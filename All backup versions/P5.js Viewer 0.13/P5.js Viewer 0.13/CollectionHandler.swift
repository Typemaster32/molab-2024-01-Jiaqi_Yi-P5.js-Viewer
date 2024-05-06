import SwiftUI

import Foundation

struct CollectionHandler {
    let fileURL: URL // Attention: this should be the URL to the unzipped folder
                     // To create the thumbnail, you'll still need a URL to the index.html
    let folderName: String = "Collection"
    
    var destinationFileURL:URL?
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        self.destinationFileURL = ensureFolderExistsAndCopyFile()
    }
    
    private func ensureFolderExistsAndCopyFile()->URL? {
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
                return nil
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
        return destinationURL
    }
    
    // Function to add a new element to the JSON
    func addElement(title: String, author: String) {
        var elements = DataManager.shared.loadElements()
        
        // Ensure the URL to the folder is correct and points to the new collection
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let newFolderPath = documentsDirectory.appendingPathComponent(folderName)
        
        let newElement = ElementModel(title: title, author: author, folderURL: newFolderPath)
        elements.append(newElement)
        
        DataManager.shared.saveElements(elements)
        print("Element added successfully.")
    }
}

class DataManager {
    static let shared = DataManager()
    private let fileName = "collectionlist.json"
    
    func getDocumentDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func getFileURL() -> URL {
        getDocumentDirectory().appendingPathComponent(fileName)
    }
    
    func loadElements() -> [ElementModel] {
        let fileURL = getFileURL()
        // Attempt to read from the documents directory first
        if let data = try? Data(contentsOf: fileURL),
           let elements = try? JSONDecoder().decode([ElementModel].self, from: data) {
            return elements
        } else {
            // If the file doesn't exist in the documents directory, read from the bundle
            if let bundleURL = Bundle.main.url(forResource: fileName, withExtension: nil),
               let data = try? Data(contentsOf: bundleURL),
               let elements = try? JSONDecoder().decode([ElementModel].self, from: data) {
                return elements
            }
        }
        // Return an empty array if neither source has data
        return []
    }
    
    func saveElements(_ elements: [ElementModel]) {
        let fileURL = getFileURL()
        do {
            let data = try JSONEncoder().encode(elements)
            try data.write(to: fileURL, options: [.atomicWrite])
        } catch {
            print("Error saving elements: \(error)")
        }
    }
}






//#Preview {
//    CollectTheSketch()
//}
