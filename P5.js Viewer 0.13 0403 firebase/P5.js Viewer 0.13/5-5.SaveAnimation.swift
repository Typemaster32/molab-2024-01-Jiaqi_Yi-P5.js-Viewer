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
    if !fileManager.fileExists(atPath: destinationParentFolderURL.path) {
        do {
            try fileManager.createDirectory(at: destinationParentFolderURL, withIntermediateDirectories: true, attributes: nil)
            print("[Save Animation] Parent folder created successfully.")
        } catch {
            print("[Save Animation] Error creating parent folder: \(error)")
            return
        }
    }
    // This is to ensure the folder exists.
    let destinationURL = destinationParentFolderURL.appendingPathComponent(folderURL.lastPathComponent)
    // ATTENTION: destinationURL is the URL of the folder of the sketch.
    // Here to load the UI of Loading;
    
    if !fileManager.fileExists(atPath: destinationURL.path) {
        do {
            try fileManager.copyItem(at: folderURL, to: destinationURL)
            print("[Save Animation] Source file copied successfully to \(destinationURL.path)")
        } catch {
            print("[Save Animation] Error copying source file: \(error)")
        }
    } else {
        print("[Save Animation] Source file already exists at destination.")
    }
    // This is to copy to the destination.
    
    
    var indexPath = destinationURL.appendingPathComponent("index.html")
    //We need to ensure that the only html is named "index.html" before this.
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
                modifyJSFile(atPath: fullPath)
            } else {
                print("File does not exist: \(fullPath)")
            }
        }
    } catch {
        print("Failed to read content from '\(indexHTMLURL)': \(error)")
    }
    // Run it!!!
    
    
    
}

func modifyJSFile(atPath path: String) {
    do {
        // Read the content of the JS file
        var jsContent = try String(contentsOfFile: path, encoding: .utf8)
        
        // Task 1: Insert the variable declaration anywhere, here we choose the beginning for simplicity
        let insertionPart0 = "var capturer = new CCapture({ format: 'png', framerate: 60 });\nvar duration = 3000; // part0\n"
        jsContent = insertionPart0 + jsContent
        
        // Task 2: Insert after "function draw()" considering it's not part of a string or comment
        let drawFunctionRegex = try NSRegularExpression(pattern: "function draw\\(\\)\\s*{", options: [])
        let drawFunctionMatches = drawFunctionRegex.matches(in: jsContent, options: [], range: NSRange(jsContent.startIndex..., in: jsContent))
        if let match = drawFunctionMatches.first {
            let insertionIndex = jsContent.index(jsContent.startIndex, offsetBy: match.range.location + match.range.length)
            jsContent.insert(contentsOf: "\n  if (frameCount === 1) { \n        capturer.start();\n      }\n", at: insertionIndex)
        }
        
        // Task 3: Insert as the last line of "function draw()"
        // This is trickier as we need to ensure we're adding it at the end of the function
        let drawFunctionEndRegex = try NSRegularExpression(pattern: "}", options: [])
        let drawFunctionEndMatches = drawFunctionEndRegex.matches(in: jsContent, options: [], range: NSRange(jsContent.startIndex..., in: jsContent))
        if let lastMatch = drawFunctionEndMatches.last {
            let insertionIndex = jsContent.index(jsContent.startIndex, offsetBy: lastMatch.range.location)
            jsContent.insert(contentsOf: "\n  capturer.capture(document.getElementById('defaultCanvas0'));", at: insertionIndex)
        }
        
        // Write the modified content back to the JS file
        try jsContent.write(toFile: path, atomically: true, encoding: .utf8)
        print("JS file modified successfully.")
    } catch {
        print("An error occurred: \(error)")
    }
}


func findLocalJSFiles(inHTMLContent htmlContent: String) -> [String] {
    let regexPattern = "<script\\s+[^>]*src=\"([^\"]+)\""
    do {
        let regex = try NSRegularExpression(pattern: regexPattern, options: [])
        let matches = regex.matches(in: htmlContent, options: [], range: NSRange(location: 0, length: htmlContent.utf16.count))
        
        let jsFiles = matches.compactMap { match -> String? in
            guard let range = Range(match.range(at: 1), in: htmlContent) else { return nil }
            let src = String(htmlContent[range])
            return src.hasPrefix("http") ? nil : src // Filter out non-local JS files
        }
        return jsFiles
    } catch {
        print("Regex error: \(error)")
        return []
    }
}

