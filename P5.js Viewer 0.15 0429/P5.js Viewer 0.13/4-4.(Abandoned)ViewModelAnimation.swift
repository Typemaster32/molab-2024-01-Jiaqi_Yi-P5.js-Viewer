import UIKit
import WebKit
import Foundation
/*
 1. Trigger: Button -> AnimationController.init()
 
 2. Begin video making:
 AnimationController.saveAnimationAction() -> videoCreator = VideoCreator(...)
 
 3. Copy and modify the sketch file
 AnimationController.saveAnimationAction() -> preparation()
 
 4. run html (in the webContentView)
 AnimationController.saveAnimationAction() -> webView.load(...)
 
 5. Get images
 JavaScript in WebView sends images -> userContentController(_:didReceive:)
 
 6. Receive images
 userContentController(...) -> processImage(base64:)
 
 7. Add into video
 processImage(...) -> decodeImage(from:) -> videoCreator.addImageToVideo(image:)
 
 8. Count and stop
 If imageCount >= 180 -> finalizeCreationAndCleanup()
 finalizeCreationAndCleanup() -> videoCreator.finalizeVideo()
 finalizeCreationAndCleanup() -> webView.removeFromSuperview()
 
 9. Get the first frame
 TBD
 
 10. Compose Live photo
 TBD
 
 [What happens While receiving the data]
 receive in swift (Base64) => revert into blob => save images with sequences.
 see [webView] & [viewController]
 
 Run it:
 1. Call the webView as usual
 2. create the instance of the VideoCreator
 3. whenever "userContentController" gets the image, it'll be added to the VideoCreator
 4. after reaching 180, calls the "finalizeVideo" in VideoCreator
 
 */

class ViewModelOfAnimation: ObservableObject {
    var videoCreator: VideoCreator
    var imageCount = 0
    var author: String
    var folderURL: URL = URL(string: "https://www.google.com")!
    var sketchTitle: String // 'title' is built-in
    var indexPath: URL = URL(string: "https://www.google.com")!
    @Published var shouldShowWebView: Bool = false
    
    // Custom initializer
    init(sketchTitle: String, author: String) {
        self.sketchTitle = sketchTitle
        self.author = author
        self.videoCreator = VideoCreator(name: "\(sketchTitle)-\(author)")
    }
    
    func setUp(_ newURL : URL){
        self.folderURL = newURL
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationParentFolderURL = documentsDirectory.appendingPathComponent("ModifiedForAnimation")
        self.indexPath = destinationParentFolderURL.appendingPathComponent(self.folderURL.lastPathComponent).appendingPathComponent("index.html", isDirectory: false)
        self.saveAnimationAction()
    }
    
    
    func saveAnimationAction() {
        print("[ViewModelOfAnimation][SaveAnimationAction][Start]: Initiating saving animation.")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                print("[ViewModelOfAnimation][SaveAnimationAction][Exit]: self is nil after weak capture.")
                return
            }
            self.preparation(folderURL: self.folderURL, fileName: "\(self.sketchTitle)-\(self.author)")
            
            DispatchQueue.main.async { [self] in
                print("[ViewModelOfAnimation][SaveAnimationAction][Check]: Checking existence of index.html at \(self.indexPath.path)")
                if FileManager.default.fileExists(atPath: self.indexPath.path) {
                    print("[ViewModelOfAnimation][SaveAnimationAction][Load]: index.html found, loading in webView.")
                    self.shouldShowWebView = true
                } else {
                    print("[ViewModelOfAnimation][SaveAnimationAction][Error]: index.html not found at \(self.indexPath.path).")
                }
            }
        }
    }
    
    
    
    func preparation(folderURL:URL, fileName: String){
        print("[ViewModelOfAnimation][Preparation][Start]: Preparing to process folder with file name: \(fileName)")
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationParentFolderURL = documentsDirectory.appendingPathComponent("ModifiedForAnimation")
        
        // Ensure / Create the folder "ModifiedForAnimation"
        if !fileManager.fileExists(atPath: destinationParentFolderURL.path) {
            do {
                try fileManager.createDirectory(at: destinationParentFolderURL, withIntermediateDirectories: true, attributes: nil)
                print("[ViewModelOfAnimation][Preparation][CreateDirectory]: Parent folder 'ModifiedForAnimation' created at \(destinationParentFolderURL.path)")
            } catch {
                print("[ViewModelOfAnimation][Preparation][Error]: Error creating parent folder: \(error)")
                return
            }
        } else {
            print("[ViewModelOfAnimation][Preparation][Info]: Parent folder 'ModifiedForAnimation' already exists.")
        }
        
        // Prepare destination URL for the sketch folder in "ModifiedForAnimation"
        print("[ViewModelOfAnimation][Preparation][Info]: the folderURL is: \(folderURL)")
        let destinationURL = destinationParentFolderURL.appendingPathComponent(folderURL.lastPathComponent)
        print("[ViewModelOfAnimation][Preparation][Info]: Destination URL for the sketch is \(destinationURL.path)")
        
        // Copy the folder from original location to "ModifiedForAnimation"
        if !fileManager.fileExists(atPath: destinationURL.path) {
            do {
                try fileManager.copyItem(at: folderURL, to: destinationURL)
                print("[ViewModelOfAnimation][Preparation][Copy]: Source folder copied successfully to \(destinationURL.path)")
            } catch {
                print("[ViewModelOfAnimation][Preparation][Error]: Error copying source folder: \(error)")
                return
            }
        } else {
            print("[ViewModelOfAnimation][Preparation][Info]: Source folder already exists at destination.")
        }
        
        // Inserting JavaScript code for saving images
        let indexHTMLURL = folderURL.appendingPathComponent("index.html")
        do {
            let indexHTMLContent = try String(contentsOf: indexHTMLURL, encoding: .utf8)
            print("[ViewModelOfAnimation][Preparation][ReadIndexHTML]: Read index.html successfully.")
            let localJSFiles = findLocalJSFiles(inHTMLContent: indexHTMLContent)
            let folderPath = destinationURL.path
            
            for jsFileRelativePath in localJSFiles {
                let fullPath = (folderPath as NSString).appendingPathComponent(jsFileRelativePath)
                if FileManager.default.fileExists(atPath: fullPath) {
                    modifyJSFile(atPath: fullPath, insertedJSCode: insertedJSCode)
                    print("[ViewModelOfAnimation][Preparation][ModifyJS]: Modified JavaScript file at \(fullPath)")
                } else {
                    print("[ViewModelOfAnimation][Preparation][Error]: JavaScript file not found at \(fullPath)")
                }
            }
        } catch {
            print("[ViewModelOfAnimation][Preparation][Error]: Failed to read content from 'index.html' at \(indexHTMLURL): \(error)")
        }
    }
    
    
    
    
    func modifyJSFile(atPath path: String, insertedJSCode: String) {
        print("[ViewModelOfAnimation][ModifyJSFile][Start]: Starting to modify JavaScript file at \(path)")
        do {
            // Read the content of the target JS file
            var jsContent = try String(contentsOfFile: path, encoding: .utf8)
            print("[ViewModelOfAnimation][ModifyJSFile][Read]: Successfully read the JavaScript file.")
            
            // Improved regex to specifically find the closing brace of function draw()
            let drawFunctionEndRegex = try NSRegularExpression(pattern: "\\bfunction\\s+draw\\s*\\(\\s*\\)\\s*\\{[^}]*\\}", options: .dotMatchesLineSeparators)
            let drawFunctionEndMatches = drawFunctionEndRegex.matches(in: jsContent, options: [], range: NSRange(jsContent.startIndex..., in: jsContent))
            
            if let lastMatch = drawFunctionEndMatches.last {
                // Find the index right before the closing brace to insert the new JS code
                let insertionIndex = jsContent.index(jsContent.startIndex, offsetBy: lastMatch.range.upperBound - 1)
                jsContent.insert(contentsOf: "\n    \(insertedJSCode)", at: insertionIndex)
                print("[ViewModelOfAnimation][ModifyJSFile][Insert]: Code inserted successfully before the closing brace of the draw function.")
            } else {
                print("[ViewModelOfAnimation][ModifyJSFile][Error]: No 'draw function' end found in the JS file.")
            }
            
            // Write the modified content back to the JS file
            try jsContent.write(toFile: path, atomically: true, encoding: .utf8)
            print("[ViewModelOfAnimation][ModifyJSFile][Success]: JavaScript file modified and saved successfully.")
        } catch {
            print("[ViewModelOfAnimation][ModifyJSFile][Error]: An error occurred while modifying the JS file: \(error)")
        }
    }
    
    func findLocalJSFiles(inHTMLContent htmlContent: String) -> [String] {
        let regexPattern = "<script\\s+[^>]*src=\"([^\"]+)\""
        print("[ViewModelOfAnimation][FindLocalJSFiles][Start]: Searching for local JavaScript files in HTML content.")
        do {
            let regex = try NSRegularExpression(pattern: regexPattern, options: [])
            let matches = regex.matches(in: htmlContent, options: [], range: NSRange(location: 0, length: htmlContent.utf16.count))
            
            let foundFiles = matches.compactMap { match -> String? in
                guard let range = Range(match.range(at: 1), in: htmlContent) else { return nil }
                let src = String(htmlContent[range]) // Explicitly convert Substring to String
                if src.hasPrefix("http") {
                    print("[ViewModelOfAnimation][FindLocalJSFiles][Filter]: Excluding external JS file found at URL: \(src)")
                    return nil // Filter out non-local JS files
                }
                print("[ViewModelOfAnimation][FindLocalJSFiles][Include]: Including local JS file: \(src)")
                return src
            }
            
            print("[ViewModelOfAnimation][FindLocalJSFiles][Success]: Found \(foundFiles.count) local JavaScript files.")
            return foundFiles
        } catch {
            print("[ViewModelOfAnimation][FindLocalJSFiles][Error]: Regex error: \(error)")
            return []
        }
    }
}


func showWarningAlert(on viewController: UIViewController, message: String) {
    let alert = UIAlertController(title: "Warning", message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    alert.addAction(okAction)
    
    // Presenting the alert on the provided view controller
    viewController.present(alert, animated: true, completion: nil)
}
