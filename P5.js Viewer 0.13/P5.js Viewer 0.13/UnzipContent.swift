import SwiftUI
import WebKit
import ZIPFoundation




func unzipContent(sourceURL: URL, completion: @escaping (URL?) -> Void) {
    let fileManager = FileManager.default
    let destinationDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("UnzippedContent")
    let uniqueSubdirectoryName = sourceURL.deletingPathExtension().lastPathComponent
    let uniqueDestinationURL = destinationDirectoryURL.appendingPathComponent(uniqueSubdirectoryName)
    
    // Clean the comments in JS. Call the function with your directory URL
    processJSFiles(inDirectory: uniqueDestinationURL)
    let keywords:[Any]=[["createCanvas(windowWidth,windowHeight)","resizeCanvas(windowWidth,windowHeight)"],".play()",["mouseX","mouseY","mouseReleased()","mouseHover()","mouseMoved()"],["keyIsPressed","keyPressed"],["createCapture(VIDEO)"]]
    let remarks=["Fullscreen","A/V","Mouse","Keyboard","Capturing"]
    
    // More to do: disable downloading; Delete console.log();

    // Check if the directory already exists (Oringinal)
    if fileManager.fileExists(atPath: uniqueDestinationURL.path) {
        do {
            // Attempt to remove the existing directory to avoid the error
            try fileManager.removeItem(at: uniqueDestinationURL)
        } catch {
            print("An error occurred while removing existing directory: \(error)")
            completion(nil)
            return
        }
    }
    
    do {
        // Proceed with creating the directory and unzipping
        try fileManager.createDirectory(at: uniqueDestinationURL, withIntermediateDirectories: true, attributes: nil)
        try fileManager.unzipItem(at: sourceURL, to: uniqueDestinationURL)
        
        
        let indexPath = uniqueDestinationURL.appendingPathComponent("index.html")
        //This is the origin of the html file path. This assumes the name of the file to be "index.html"
        
        if fileManager.fileExists(atPath: indexPath.path) {
            removeP5SoundScriptTag(fromHtmlFile: indexPath)
            DispatchQueue.main.async {
                completion(indexPath) // Successfully unzipped
            }
        } else {
            print("index.html does not exist at expected location: \(indexPath.path)")
            completion(nil)
        }
    } catch {
        print("An error occurred during unzipping: \(error)")
        completion(nil)
    }
}

func removeP5SoundScriptTag(fromHtmlFile filePath: URL) {
    do {
        // 1. Read the HTML file into a String
        let htmlContent = try String(contentsOf: filePath, encoding: .utf8)
        
        // 2. Use regex to specifically target any script tag containing "p5.sound.min.js"
        // This pattern matches a script tag that contains "p5.sound.min.js", capturing variations in the URL
        let pattern = "<script[^>]*src=[\"'][^\"']*p5\\.sound\\.min\\.js[^\"']*[\"'][^>]*><\\/script>"
        let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        
        // Perform the replacement
        let newHtmlContent = regex.stringByReplacingMatches(in: htmlContent, options: [], range: NSRange(htmlContent.startIndex..., in: htmlContent), withTemplate: "")
        
        // Check if replacement was made
        if htmlContent == newHtmlContent {
            print("No script tag for 'p5.sound.min.js' was found in the HTML file.")
        } else {
            // 3. Write the modified String back to the file
            try newHtmlContent.write(to: filePath, atomically: true, encoding: .utf8)
            print("Successfully removed the script tag for 'p5.sound.min.js' from the HTML file.")
        }
    } catch {
        print("An error occurred while processing the HTML file: \(error)")
    }
}

func removeCommentsFromJSFiles(inDirectory directoryPath: URL) {
    let fileManager = FileManager.default
    do {
        // 1. Get the list of files in the directory
        let items = try fileManager.contentsOfDirectory(at: directoryPath, includingPropertiesForKeys: nil)
        // 2. Filter for .js files
        let jsFiles = items.filter { $0.pathExtension == "js" }
        
        for fileURL in jsFiles {
            // 3. Read the content of each .js file
            var content = try String(contentsOf: fileURL, encoding: .utf8)
            
            // 4. Use regex to remove single-line and block comments
            // Remove single-line comments
            content = content.replacingOccurrences(of: "//.*", with: "", options: .regularExpression)
            // Attempt to remove block comments
            content = content.replacingOccurrences(of: "/\\*[^*]*\\*+(?:[^/*][^*]*\\*+)*/", with: "", options: .regularExpression)
            
            // 5. Write the modified content back to the file
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
        print("Comments removed from all .js files.")
    } catch {
        print("An error occurred: \(error)")
    }
}

func processJSFiles(inDirectory directoryURL: URL) {
    let fileManager = FileManager.default
    
    do {
        // 1. List directory contents
        let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
        
        // 2. Filter for .js files
        let jsFileURLs = fileURLs.filter { $0.pathExtension == "js" }
        
        // 3. Loop through the .js files
        for fileURL in jsFileURLs {
            // Perform your operations on each .js file URL here
            print("Processing JS file: \(fileURL.lastPathComponent)")
            // For example, removing comments from the JS file
            // removeCommentsFromJSFile(fileURL) // You would need to define this function
        }
    } catch {
        print("An error occurred while listing .js files: \(error)")
    }
}

func searchJSFilesForKeywords(inDirectory directoryURL: URL, keywords: [Any]) -> [Bool] {
    let fileManager = FileManager.default
    var results = [Bool](repeating: false, count: keywords.count)
    
    do {
        let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
        let jsFileURLs = fileURLs.filter { $0.pathExtension == "js" }
        
        for fileURL in jsFileURLs {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            
            for (index, keywordItem) in keywords.enumerated() {
                if results[index] { continue } // Skip if already found
                
                if let keyword = keywordItem as? String {
                    // Single keyword
                    if content.contains(keyword) {
                        results[index] = true
                    }
                } else if let keywordArray = keywordItem as? [String] {
                    // Child array of keywords
                    for keyword in keywordArray {
                        if content.contains(keyword) {
                            results[index] = true
                            break // Found, no need to check further in this array
                        }
                    }
                }
            }
        }
    } catch {
        print("An error occurred: \(error)")
    }
    
    return results
}
