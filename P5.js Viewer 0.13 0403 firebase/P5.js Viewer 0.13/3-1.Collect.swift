

import UIKit
import SwiftUI
import Foundation




class CollectionManager {
    static let shared = CollectionManager() // Singleton instance, if suitable for your use case
    var webViewSnapshotter: WebViewSnapshotter?
    func collect(title: String, author: String, originalHtmlURL: URL) {
        let collectionsFolderName = "Collections"
        let fileName = "collectionlist.json"
        let fileManager = FileManager.default
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
        let newElement = ElementModel(title: title, author: author, folderURL: destinationFolderURL.path)
        collectionList.append(newElement)
        if let encodedData = try? JSONEncoder().encode(collectionList) {
            try? encodedData.write(to: collectionListURL)
        }
        
        webViewSnapshotter = WebViewSnapshotter(url: originalHtmlURL, width: 500, height: 500) { image in
            if let image = image {
                print("--- Collect -> saveImageAction -> Image is valid from the URL below: \(originalFolderURL)")
                // Save the thumbnail image to the destination URL, with compression
                ImageSaver.shared.saveImage(image, compress: true, toURL: thumbnailDestinationURL)
            } else {
                print("--- Collect -> saveImageAction -> Failed to take snapshot")
            }
            self.webViewSnapshotter = nil
        }
        
        // Print series of info
        print("--- Collect -> destinationFolderURL: \(destinationFolderURL)")
        
        printFilesInFolder(url: destinationFolderURL)
    }
}
