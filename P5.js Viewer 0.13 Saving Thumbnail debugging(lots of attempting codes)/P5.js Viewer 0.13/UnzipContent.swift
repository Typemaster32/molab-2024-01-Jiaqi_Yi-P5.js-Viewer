import SwiftUI
import WebKit
import ZIPFoundation

func unzipContent(sourceURL: URL, completion: @escaping (URL?,[Bool]) -> Void) {
    let fileManager = FileManager.default
    let destinationDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("UnzippedContent")
    let uniqueSubdirectoryName = sourceURL.deletingPathExtension().lastPathComponent
    let uniqueDestinationURL = destinationDirectoryURL.appendingPathComponent(uniqueSubdirectoryName)
    print("---unzipContent---")
    print("[unzipContent]sourceURL: \(sourceURL)")
    print("[unzipContent]uniqueDestinationURL: \(uniqueDestinationURL)")
//    let tagCCapture:String="""
//    <script src="path/to/CCapture.min.js"></script>
//    <script src="path/to/gif.js"></script>
//    <script src="path/to/webm-writer-0.2.0.js"></script>
//    """
//    let tagBanZooming:String="name=\"viewport\" content=\"width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no\""
//    
//    let tagForceResize:String="<meta name=\"viewport\" content=\"width=device-width, initial-scale=1, maximum-scale=1\">"
    let keywords:[Any]=[["createCanvas(windowWidth,windowHeight)","resizeCanvas(windowWidth,windowHeight)"],".play()",["mouseX","mouseY","mouseReleased()","mouseHover()","mouseMoved()"],["keyIsPressed","keyPressed"],["createCapture(VIDEO)"]]
    
    
    // Check if the directory already exists (Oringinal)
    if fileManager.fileExists(atPath: uniqueDestinationURL.path) {
        print("uniqueDestinationURL is now OCCUPIED. Trying to remove the exsiting file")
        do {
            // Attempt to remove the existing directory to avoid the error
            try fileManager.removeItem(at: uniqueDestinationURL)
            print("Removing is successful")
        } catch {
            print("An error occurred while removing existing directory: \(error)")
            completion(nil,[true,true,true,true,true])
            return
        }
    }
    print("Trying to Unzip")
    do {
        // Proceed with creating the directory and unzipping
        try fileManager.createDirectory(at: uniqueDestinationURL, withIntermediateDirectories: true, attributes: nil)
        try fileManager.unzipItem(at: sourceURL, to: uniqueDestinationURL)
        print("Unzipping is successful")
        
        //        print("[unzipContent]ZIP details:")
        //        printZipFileDetails(url:sourceURL)
        //        print("[unzipContent]Unzipped details:")
        //        printFilesInFolder(url:uniqueDestinationURL)
        deleteSpecificFiles(inDirectory: uniqueDestinationURL)
        processJSFiles(inDirectory: uniqueDestinationURL)
        removeCommentsFromJSFiles(inDirectory: uniqueDestinationURL)
//      insertMetaTagInHtmlFile(folderPath:uniqueDestinationURL, tagToImport: tagForceResize)
//      insertCssRulesInCssFile(folderPath:uniqueDestinationURL)
        let remarkBools = searchJSFilesForKeywords(inDirectory: uniqueDestinationURL, keywords: keywords)
        print("This is the keyword results: \(remarkBools)")
        
        let indexPath = uniqueDestinationURL.appendingPathComponent("index.html")
        //This is the origin of the html file path. This assumes the name of the file to be "index.html"
        
        if fileManager.fileExists(atPath: indexPath.path) {
            removeP5SoundScriptTag(fromHtmlFile: indexPath)
            DispatchQueue.main.async {
                //                print(indexPath)
                completion(indexPath,remarkBools) // Successfully unzipped
            }
        } else {
            print("index.html is missing at expected location: \(indexPath.path)")
            completion(nil,[true,true,true,true,true])
        }
    } catch {
        print("Error unzipping: \(error)")
        completion(nil,[true,true,true,true,true])
    }
}

func removeP5SoundScriptTag(fromHtmlFile filePath: URL) {
    print("     ---removeP5SoundScriptTag---")
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
func insertMetaTagInHtmlFile(folderPath: URL, tagToImport: String) {
    print("     ---insertMetaTagInHtmlFile---")
    let htmlFilePath = folderPath.appendingPathComponent("index.html")
    do {
        // 1. Read the HTML file into a String
        var htmlContent = try String(contentsOf: htmlFilePath, encoding: .utf8)
        
        // 2. Check if the meta tag is already present
        if !htmlContent.contains(tagToImport) {
            // Prepare the meta tag
            let metaTag = tagToImport
            
            // Insert the meta tag after the <head> tag
            if let headRange = htmlContent.range(of: "<head>") {
                htmlContent.insert(contentsOf: metaTag, at: headRange.upperBound)
                // 3. Write the modified String back to the file
                try htmlContent.write(to: htmlFilePath, atomically: true, encoding: .utf8)
                print("Successfully inserted the meta tag into the HTML file.")
            } else {
                print("No <head> tag was found in the HTML file.")
            }
        } else {
            print("The meta tag is already present in the HTML file.")
        }
    } catch {
        print("An error occurred while processing the HTML file: \(error)")
    }
}
// It would cause sketch1981360 being blank!!!
func insertCssRulesInCssFile(folderPath: URL) {
    print("     ---insertCssRulesInCssFile---")
    let cssFilePath = folderPath.appendingPathComponent("style.css")
    
    // Check if the CSS file exists, if not, create an empty one
    if !FileManager.default.fileExists(atPath: cssFilePath.path) {
        FileManager.default.createFile(atPath: cssFilePath.path, contents: nil)
    }
    
    do {
        // 1. Read the CSS file into a String
        var cssContent = try String(contentsOf: cssFilePath, encoding: .utf8)
        
        // 2. Prepare the CSS rule
        let cssRule = "canvas { touch-action: none; }\n"
        
        // Check if the CSS rule is already present
        if !cssContent.contains(cssRule) {
            // Append the CSS rule
            cssContent += cssRule
            // 3. Write the modified String back to the file
            try cssContent.write(to: cssFilePath, atomically: true, encoding: .utf8)
            print("Successfully inserted the CSS rules into the CSS file.")
        } else {
            print("The CSS rule is already present in the CSS file.")
        }
    } catch {
        print("An error occurred while processing the CSS file: \(error)")
    }
}
func removeCommentsFromJSFiles(inDirectory directoryPath: URL) {
    print("     ---removeCommentsFromJSFiles---")
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
    print("     ---processJSFiles---")
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
        //        print("An error occurred while listing .js files: \(error)")
        print("Error listing .js files: \(error)")
    }
}
func searchJSFilesForKeywords(inDirectory directoryURL: URL, keywords: [Any]) -> [Bool] {
    print("     ---searchJSFilesForKeywords---")
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
func deleteSpecificFiles(inDirectory directoryURL: URL) {
    print("     ---deleteSpecificFiles---")
    let fileManager = FileManager.default
    let filesToDelete = ["p5.js", "p5.min.js", "p5.sound.min.js", "p5.dom.min.js"]
    
    filesToDelete.forEach { fileName in
        let fileURL = directoryURL.appendingPathComponent(fileName)
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
                print("\(fileName) was successfully deleted.")
            } catch {
                print("Could not delete \(fileName): \(error)")
            }
        } else {
            print("\(fileName) does not exist in the specified directory.")
        }
    }
}
//There are two test functions:
func printZipFileDetails(url: URL) {
    let fileManager = FileManager.default
    do {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let fileSize = attributes[FileAttributeKey.size] as? NSNumber
        let fileName = url.lastPathComponent
        
        print("File Name: \(fileName)")
        if let fileSize = fileSize {
            print("File Size: \(fileSize.intValue) bytes")
        }
    } catch {
        print("Error retrieving file attributes: \(error.localizedDescription)")
    }
}
func printFilesInFolder(url: URL) {
    let fileManager = FileManager.default
    do {
        let fileURLs = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        
        for fileURL in fileURLs {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            let fileSize = attributes[FileAttributeKey.size] as? NSNumber
            let fileName = fileURL.lastPathComponent
            
            print("File Name: \(fileName)")
            if let fileSize = fileSize {
                print("File Size: \(fileSize.intValue) bytes")
            }
        }
    } catch {
        print("Error listing directory contents: \(error.localizedDescription)")
    }
}
