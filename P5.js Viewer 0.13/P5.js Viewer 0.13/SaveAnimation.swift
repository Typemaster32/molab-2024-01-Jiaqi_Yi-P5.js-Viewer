import Foundation
import WebKit
import UIKit

func SaveAnimation(folderURL:URL){
    
//    let folderName: String = folderURL.lastPathComponent()
    let parentFolderName: String = "SaveAnimationVersion"
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
    
    
    
}
