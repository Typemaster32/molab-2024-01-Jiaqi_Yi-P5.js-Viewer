import SwiftUI

import Foundation

struct CollectionHandler {
    let fileURL: URL 
    // Attention: this should be the URL to the unzipped folder
    // To create the thumbnail, you'll still need a URL to the index.html
    let folderName: String = "Collection"
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        ensureFolderExistsAndCopyFile()
    }
    
    private func ensureFolderExistsAndCopyFile() {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderPath = documentsDirectory.appendingPathComponent(folderName)
        
        // Ensure the folder exists
        if !fileManager.fileExists(atPath: folderPath.path) {
            do {
                try fileManager.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
                print("Folder created successfully.")
            } catch {
                print("Error creating folder: \(error)")
                return
            }
        }
        
        // Copy the file to the new folder
        let destinationURL = folderPath.appendingPathComponent(fileURL.lastPathComponent)
        if !fileManager.fileExists(atPath: destinationURL.path) {
            do {
                try fileManager.copyItem(at: fileURL, to: destinationURL)
                print("File copied successfully to \(destinationURL.path)")
            } catch {
                print("Error copying file: \(error)")
            }
        } else {
            print("File already exists at destination.")
        }
    }
}






//#Preview {
//    CollectTheSketch()
//}
