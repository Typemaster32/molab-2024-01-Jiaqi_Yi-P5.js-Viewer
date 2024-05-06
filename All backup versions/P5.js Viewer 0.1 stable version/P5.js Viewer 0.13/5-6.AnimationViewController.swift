import UIKit
import WebKit
import Foundation
/*
 1. Trigger: Button -> AnimationController.init() -> AnimationController.saveAnimationAction()
 
 2. Begin video making:
 AnimationController.saveAnimationAction() -> videoCreator = VideoCreator(...)
 
 3. Copy and modify the sketch file
 AnimationController.saveAnimationAction() -> preparation()

 4. run html
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

let insertedJSCode: String =
"""
var reader_skksn = new FileReader();
canvas.toBlob(function (blob) {
    reader_skksn.readAsDataURL(blob);
    reader_skksn.onloadend = function () {
    var base64data_rrbss = reader_skksn.result;

    window.webkit.messageHandlers.p5js_viewer.postMessage(base64data_rrbss);
  }
  }, 'image/png');
if (frameCount>180) noLoop()
"""
class AnimationViewController {
    var videoCreator: VideoCreator?
    var webView: WKWebView!
    var imageCount = 0
    
    // Question: does this have to have a name?
    
    var author: String
    var folderURL: URL
    var sketchTitle: String // 'title' is built-in
    
    // Custom initializer
    init(sketchTitle: String, author: String, folderURL: URL) {
        self.sketchTitle = sketchTitle
        self.author = author
        self.folderURL = folderURL // aka sourceLocalURL
        self.videoCreator = VideoCreator(name: "\(sketchTitle)-\(author)")
        setupWebView()
        print("Setting up WebView with new configuration")
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: config)
        //        webView.isHidden = true
        print("WebView is set up and added to view hierarchy")
        if self.webView != nil {
            print("[AnimationViewController][viewDidLoad]: WebView is successfully initialized and ready for use.")
        } else {
            print("[AnimationViewController][viewDidLoad]: WebView failed to initialize.")
        }
        self.saveAnimationAction()
    }
    
    
    func setupWebView() {

    }

    func saveAnimationAction() {
        print("[SaveAnimationAction][Start]: Initiating saving animation.")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                print("[SaveAnimationAction][Exit]: self is nil after weak capture.")
                return
            }
            self.preparation(folderURL: self.folderURL, fileName: "\(self.sketchTitle)-\(self.author)")
            
            DispatchQueue.main.async {
                if self.webView == nil {
                    print("[SaveAnimationAction][Info]: webView is STILL nil, even after reinitializing.")
                }
                
                let fileManager = FileManager.default
                let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                let destinationParentFolderURL = documentsDirectory.appendingPathComponent("ModifiedForAnimation")
                let indexPath = destinationParentFolderURL.appendingPathComponent(self.folderURL.lastPathComponent).appendingPathComponent("index.html", isDirectory: false)
                
                print("[SaveAnimationAction][Check]: Checking existence of index.html at \(indexPath.path)")
                if FileManager.default.fileExists(atPath: indexPath.path) {
                    print("[SaveAnimationAction][Load]: index.html found, loading in webView.")
//                    self.webView?.load(URLRequest(url: "indexPath"))
                    let placeholderURL = URL(string: "https://www.google.com")!
                    self.webView?.load(URLRequest(url: placeholderURL))
                } else {
                    print("[SaveAnimationAction][Error]: index.html not found at \(indexPath.path).")
                }
            }
        }
    }


    
    func preparation(folderURL:URL, fileName: String){
        print("[Preparation][Start]: Preparing to process folder with file name: \(fileName)")
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationParentFolderURL = documentsDirectory.appendingPathComponent("ModifiedForAnimation")
        
        // Ensure / Create the folder "ModifiedForAnimation"
        if !fileManager.fileExists(atPath: destinationParentFolderURL.path) {
            do {
                try fileManager.createDirectory(at: destinationParentFolderURL, withIntermediateDirectories: true, attributes: nil)
                print("[Preparation][CreateDirectory]: Parent folder 'ModifiedForAnimation' created at \(destinationParentFolderURL.path)")
            } catch {
                print("[Preparation][Error]: Error creating parent folder: \(error)")
                return
            }
        } else {
            print("[Preparation][Info]: Parent folder 'ModifiedForAnimation' already exists.")
        }
        
        // Prepare destination URL for the sketch folder in "ModifiedForAnimation"
        print("[Preparation][Info]: the folderURL is: \(folderURL)")
        let destinationURL = destinationParentFolderURL.appendingPathComponent(folderURL.lastPathComponent)
        print("[Preparation][Info]: Destination URL for the sketch is \(destinationURL.path)")
        
        // Copy the folder from original location to "ModifiedForAnimation"
        if !fileManager.fileExists(atPath: destinationURL.path) {
            do {
                try fileManager.copyItem(at: folderURL, to: destinationURL)
                print("[Preparation][Copy]: Source folder copied successfully to \(destinationURL.path)")
            } catch {
                print("[Preparation][Error]: Error copying source folder: \(error)")
                return
            }
        } else {
            print("[Preparation][Info]: Source folder already exists at destination.")
        }
        
        // Inserting JavaScript code for saving images
        let indexHTMLURL = folderURL.appendingPathComponent("index.html")
        do {
            let indexHTMLContent = try String(contentsOf: indexHTMLURL, encoding: .utf8)
            print("[Preparation][ReadIndexHTML]: Read index.html successfully.")
            let localJSFiles = findLocalJSFiles(inHTMLContent: indexHTMLContent)
            let folderPath = destinationURL.path
            
            for jsFileRelativePath in localJSFiles {
                let fullPath = (folderPath as NSString).appendingPathComponent(jsFileRelativePath)
                if FileManager.default.fileExists(atPath: fullPath) {
                    modifyJSFile(atPath: fullPath, insertedJSCode: insertedJSCode)
                    print("[Preparation][ModifyJS]: Modified JavaScript file at \(fullPath)")
                } else {
                    print("[Preparation][Error]: JavaScript file not found at \(fullPath)")
                }
            }
        } catch {
            print("[Preparation][Error]: Failed to read content from 'index.html' at \(indexHTMLURL): \(error)")
        }
    }
    


    
    func modifyJSFile(atPath path: String, insertedJSCode: String) {
        print("[ModifyJSFile][Start]: Starting to modify JavaScript file at \(path)")
        do {
            // Read the content of the target JS file
            var jsContent = try String(contentsOfFile: path, encoding: .utf8)
            print("[ModifyJSFile][Read]: Successfully read the JavaScript file.")
            
            // Improved regex to specifically find the closing brace of function draw()
            let drawFunctionEndRegex = try NSRegularExpression(pattern: "\\bfunction\\s+draw\\s*\\(\\s*\\)\\s*\\{[^}]*\\}", options: .dotMatchesLineSeparators)
            let drawFunctionEndMatches = drawFunctionEndRegex.matches(in: jsContent, options: [], range: NSRange(jsContent.startIndex..., in: jsContent))
            
            if let lastMatch = drawFunctionEndMatches.last {
                // Find the index right before the closing brace to insert the new JS code
                let insertionIndex = jsContent.index(jsContent.startIndex, offsetBy: lastMatch.range.upperBound - 1)
                jsContent.insert(contentsOf: "\n    \(insertedJSCode)", at: insertionIndex)
                print("[ModifyJSFile][Insert]: Code inserted successfully before the closing brace of the draw function.")
            } else {
                print("[ModifyJSFile][Error]: No 'draw function' end found in the JS file.")
            }
            
            // Write the modified content back to the JS file
            try jsContent.write(toFile: path, atomically: true, encoding: .utf8)
            print("[ModifyJSFile][Success]: JavaScript file modified and saved successfully.")
        } catch {
            print("[ModifyJSFile][Error]: An error occurred while modifying the JS file: \(error)")
        }
    }

    func findLocalJSFiles(inHTMLContent htmlContent: String) -> [String] {
        let regexPattern = "<script\\s+[^>]*src=\"([^\"]+)\""
        print("[FindLocalJSFiles][Start]: Searching for local JavaScript files in HTML content.")
        do {
            let regex = try NSRegularExpression(pattern: regexPattern, options: [])
            let matches = regex.matches(in: htmlContent, options: [], range: NSRange(location: 0, length: htmlContent.utf16.count))
            
            let foundFiles = matches.compactMap { match -> String? in
                guard let range = Range(match.range(at: 1), in: htmlContent) else { return nil }
                let src = String(htmlContent[range]) // Explicitly convert Substring to String
                if src.hasPrefix("http") {
                    print("[FindLocalJSFiles][Filter]: Excluding external JS file found at URL: \(src)")
                    return nil // Filter out non-local JS files
                }
                print("[FindLocalJSFiles][Include]: Including local JS file: \(src)")
                return src
            }
            
            print("[FindLocalJSFiles][Success]: Found \(foundFiles.count) local JavaScript files.")
            return foundFiles
        } catch {
            print("[FindLocalJSFiles][Error]: Regex error: \(error)")
            return []
        }
    }


    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "imageHandler", let imageString = message.body as? String {
            processImage(base64: imageString)
        }
    }
    
    func processImage(base64: String) { // Take images, and end if reaching 180
        print("[ProcessImage][Start]: Starting to process image.")
        if let image = decodeImage(from: base64) {
            print("[ProcessImage][Success]: Image decoded successfully.")
            videoCreator?.addImageToVideo(image: image)
            imageCount += 1
            print("[ProcessImage][Count]: Image count updated to \(imageCount).")
            
            if imageCount >= 180 {
                print("[ProcessImage][LimitReached]: Image count limit of 180 reached.")
                finalizeCreationAndCleanup()
            }
        } else {
            print("[ProcessImage][Error]: Failed to decode image from base64 string.")
        }
    }

    
    func finalizeCreationAndCleanup() { // It finalizes the video, not the live photo
        videoCreator?.completeVideoProcess { success, message in
            if success {
                print("Success: \(message)")
            } else {
                print("Error: \(message)")
            }
        }
        
        webView.removeFromSuperview()  // Terminate and remove webView
        webView = nil
        imageCount = 0  // Reset the count if needed for future operations
    }
    
    func decodeImage(from base64String: String) -> UIImage? {
        guard let imageData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters),
              let image = UIImage(data: imageData) else { return nil }
        return image
    }
}
