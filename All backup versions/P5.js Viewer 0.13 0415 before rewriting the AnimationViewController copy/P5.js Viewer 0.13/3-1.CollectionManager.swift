

import UIKit
import SwiftUI
import Foundation
import Firebase
import FirebaseStorage

class CollectionManager {
    static let shared = CollectionManager() // Singleton instance, if suitable for your use case
    var webViewSnapshotter: WebViewSnapshotter?
    var isThumbnailTiny: Bool = true // true for a real tiny thumbnail (icon-level), false for a regular thumbnail (preview-level)
    let fileManager = FileManager.default
    func collect(title: String, author: String, originalHtmlURL: URL,p5id:String,createdAt:Date) { // wrapped up for thumbnail saving, copy files to collections and add onto the json.
        let collectionsFolderName = "Collections"
        let fileName = "collectionlist.json"
        let
        originalFolderURL=originalHtmlURL.deletingLastPathComponent()
        // Path to "The Folder"/Collections
        guard let theFolderURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(collectionsFolderName) else {
            print("Failed to find or create Collections folder.")
            return
        }
        
        // Ensure the Collections folder exists
        if !fileManager.fileExists(atPath: theFolderURL.path) {
            do {
                try fileManager.createDirectory(at: theFolderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create Collections folder: \(error)")
                return
            }
        }
        
        // Path to collection list.json
        let collectionListURL = theFolderURL.appendingPathComponent(fileName)
        
        // Try to read the existing collection list.json
        var collectionList = [ElementModel]()
        if let data = try? Data(contentsOf: collectionListURL), let decodedList = try? JSONDecoder().decode([ElementModel].self, from: data) {
            collectionList = decodedList
        }
        
        // Check for duplicates
        if collectionList.contains(where: { $0.title == title && $0.author == author }) {
            print("Collection for this title and author already exists.")
            // Placeholder for triggering a function or showing a message
            return
        }
        
        // Copy the folder
        let theActualName = originalFolderURL.lastPathComponent
        let destinationFolderURL = theFolderURL.appendingPathComponent(theActualName)
        if fileManager.fileExists(atPath: destinationFolderURL.path) {
            do {
                try fileManager.removeItem(at: destinationFolderURL)
            } catch {
                print("Failed to remove existing folder: \(error)")
                return
            }
        }
        do {
            try fileManager.copyItem(at: originalFolderURL, to: destinationFolderURL)
        } catch {
            print("Failed to copy folder: \(error)")
            return
        }
        let thumbnailDestinationURL = destinationFolderURL.appendingPathComponent("thumbnail.jpg")
        
        // Add the new collection to the list and write it to the JSON file
        let newElement = ElementModel(title: title, author: author, folderURL: destinationFolderURL.path,p5id:p5id,createdAt: createdAt)
        collectionList.append(newElement)
        if let encodedData = try? JSONEncoder().encode(collectionList) {
            try? encodedData.write(to: collectionListURL)
        }
        
        webViewSnapshotter = WebViewSnapshotter(url: originalHtmlURL, width: 500, height: 500) { image in
            if let image = image {
                print("--- Collect -> saveImageAction -> Image is valid from the URL below: \(originalFolderURL)")
                ImageSaver.shared.saveImage(image, compress: true, toURL: thumbnailDestinationURL, completion: { success, error in
                    DispatchQueue.main.async {
                        if success {
                            print("--- Collect -> saveImageAction -> Image saved successfully to URL: \(thumbnailDestinationURL)")
                        } else {
                            print("--- Collect -> saveImageAction -> Failed to save image. Error: \(String(describing: error))")
                        }
                        self.webViewSnapshotter = nil // Clear the reference once done, whether success or failure
                    }
                })
            } else {
                print("--- Collect -> saveImageAction -> Failed to take snapshot")
                self.webViewSnapshotter = nil
            }
        }

        
        // Print series of info
        print("--- Collect -> destinationFolderURL: \(destinationFolderURL)")
        
        printFilesInFolder(url: destinationFolderURL)
    }
    
    func getPreviewImage(width: Int = Int(UIScreen.main.bounds.width/3), height: Int = Int(UIScreen.main.bounds.width/3), originalHtmlURL: URL, title: String, author: String, completion: @escaping (URL?) -> Void) {// This is for saving the preview. It's using a completion handler.
        print("[CollectionManager][getPreviewImage]")
        webViewSnapshotter = WebViewSnapshotter(url: originalHtmlURL, width: 500, height: 500) { [weak self] image in
            guard let self = self else { return }
            
            if let image = image {
                let safeTitle = title.replacingOccurrences(of: " ", with: "-")
                let safeAuthor = author.replacingOccurrences(of: " ", with: "-")
                let filename = "\(safeAuthor)-\(safeTitle).jpg"
                
                if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let temporaryFolder = documentsDirectory.appendingPathComponent("temporary")
                    
                    if !FileManager.default.fileExists(atPath: temporaryFolder.path) {
                        do {
                            try FileManager.default.createDirectory(at: temporaryFolder, withIntermediateDirectories: true)
                        } catch {
                            print("[CollectionManager][getPreviewImage]:Error creating temporary folder: \(error)")
                            completion(nil)
                            return
                        }
                    }
                    
                    let fileURL = temporaryFolder.appendingPathComponent(filename)
                    let screenWidth = UIScreen.main.bounds.width
                    let previewWidth = screenWidth / 3
                    ImageSaver.shared.saveImage(image, toURL: fileURL, resizeToWidth: CGFloat(previewWidth), completion: { success, error in
                        DispatchQueue.main.async {
                            if success {
                                print("[CollectionManager][getPreviewImage]:Image saved successfully")
                                completion(fileURL)
                            } else {
                                print("[CollectionManager][getPreviewImage]:Failed to save image: \(String(describing: error))")
                                completion(nil)
                            }
                        }
                    })
                    
                    // Call the completion handler with the URL where the image was saved.
                    completion(fileURL)
                } else {
                    completion(nil)
                }
            } else {
                print("[CollectionManager][getPreviewImage]:Failed to take snapshot")
                completion(nil)
            }
            self.webViewSnapshotter = nil
        }
    }


}


