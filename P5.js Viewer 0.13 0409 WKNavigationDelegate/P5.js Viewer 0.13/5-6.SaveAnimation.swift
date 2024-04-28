import Foundation
import WebKit
import UIKit
// To Save Animation: UI of Loading -> Copy -> Modify for CCapture -> Run it -> handle jpgs -> turn into Live Photo -> Stop UI of Loading.



func SaveAnimation(folderURL:URL){
    // folderURL is the URL to the folder
    let parentFolderName: String = "ModifiedForAnimation"
    let fileManager = FileManager.default
    let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let destinationParentFolderURL = documentsDirectory.appendingPathComponent(parentFolderName)
    /*0.
     Prepare URLs, ensure exists. Including:
     1. Ensure / Create the folder "ModifiedForAnimation"
     2. Copy the folder from [UnzipContent+WebContentView] => [ModifiedForAnimation]
     */
    if !fileManager.fileExists(atPath: destinationParentFolderURL.path) {
        do {
            try fileManager.createDirectory(at: destinationParentFolderURL, withIntermediateDirectories: true, attributes: nil)
            print("[Save Animation] Parent folder created successfully.")
        } catch {
            print("[Save Animation] Error creating parent folder: \(error)")
            return
        }
    } // This is to ensure the folder exists.
    let destinationURL = destinationParentFolderURL.appendingPathComponent(folderURL.lastPathComponent) // ATTENTION: destinationURL is the URL in "ModifiedForAnimation" of the folder of the sketch.
    if !fileManager.fileExists(atPath: destinationURL.path) {
        do {
            try fileManager.copyItem(at: folderURL, to: destinationURL)
            print("[Save Animation] Source file copied successfully to \(destinationURL.path)")
        } catch {
            print("[Save Animation] Error copying source file: \(error)")
        }
    } else {
        print("[Save Animation] Source file already exists at destination.")
    }// This is to copy to the destination.
    /*
     1. Start the UI of Loading; (TBD)
     */
    
    /*
     2.Modify for saving images, including:
         Find
         Insert(canvas => blob => base64 => send post message => receive!)
     */
    let insertedJSCode: String =
    """
      var reader_skksn = new FileReader();
      canvas.toBlob(function (blob) {
        reader_skksn.readAsDataURL(blob);
        reader_skksn.onloadend = function () {
        var base64data_rrbss = reader_skksn.result;
        console.log(base64data_rrbss);
        window.webkit.messageHandlers.messageHandler.postMessage(base64data);
      }
      }, 'image/png');
    """
    // Inserting! find JS Files through index.html and use the modify to all of them. only the one having "function draw()
    // We need to ensure that the only html is named "index.html" before this.
    let indexHTMLURL = folderURL.appendingPathComponent("index.html")
    // Read the content of 'index.html' into a string
    do {
        let indexHTMLContent = try String(contentsOf: indexHTMLURL, encoding: .utf8)
        let localJSFiles = findLocalJSFiles(inHTMLContent: indexHTMLContent)
        
        let folderPath = destinationURL.path
        
        for jsFileRelativePath in localJSFiles {
            let fullPath = (folderPath as NSString).appendingPathComponent(jsFileRelativePath)
            // Ensure the file exists before attempting to modify it
            if FileManager.default.fileExists(atPath: fullPath) {
                modifyJSFile(atPath: fullPath, insertedJSCode: insertedJSCode)
            } else {
                print("File does not exist: \(fullPath)")
            }
        }
    } catch {
        print("Failed to read content from '\(indexHTMLURL)': \(error)")
    }
    // You can now run it!!!
    
    
    /*
     3.Receive the data
         receive in swift (Base64) => revert into blob => save images with sequences.
         see [webView] & [viewController]
     4.Run it!
     */
    
    
    
    
}

func modifyJSFile(atPath path: String, insertedJSCode: String) {
    do {
        // Read the content of the target JS file
        var jsContent = try String(contentsOfFile: path, encoding: .utf8)
        
        // Improved regex to specifically find the closing brace of function draw()
        let drawFunctionEndRegex = try NSRegularExpression(pattern: "\\bfunction\\s+draw\\s*\\(\\s*\\)\\s*\\{[^}]*\\}", options: .dotMatchesLineSeparators)
        let drawFunctionEndMatches = drawFunctionEndRegex.matches(in: jsContent, options: [], range: NSRange(jsContent.startIndex..., in: jsContent))
        if let lastMatch = drawFunctionEndMatches.last {
            // Find the index right before the closing brace to insert the new JS code
            let insertionIndex = jsContent.index(jsContent.startIndex, offsetBy: lastMatch.range.upperBound - 1)
            jsContent.insert(contentsOf: "\n    \(insertedJSCode)", at: insertionIndex)
        }
        
        // Write the modified content back to the JS file
        try jsContent.write(toFile: path, atomically: true, encoding: .utf8)
        print("JS file modified successfully.")
    } catch {
        print("An error occurred while modifying the JS file: \(error)")
    }
}

func findLocalJSFiles(inHTMLContent htmlContent: String) -> [String] {
    let regexPattern = "<script\\s+[^>]*src=\"([^\"]+)\""
    do {
        let regex = try NSRegularExpression(pattern: regexPattern, options: [])
        let matches = regex.matches(in: htmlContent, options: [], range: NSRange(location: 0, length: htmlContent.utf16.count))
        
        return matches.compactMap { match -> String? in
            guard let range = Range(match.range(at: 1), in: htmlContent) else { return nil }
            let src = String(htmlContent[range]) // Explicitly convert Substring to String
            return src.hasPrefix("http") ? nil : src // Filter out non-local JS files
        }
    } catch {
        print("Regex error: \(error)")
        return []
    }
}


