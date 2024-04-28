
import SwiftUI
import WebKit
import UIKit
import Combine
import ZIPFoundation
import Firebase
import FirebaseFirestore



class LikesManager: ObservableObject {
    @Published var likedIDs: Set<String> = []
    
    private var fileURL: URL {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return urls.first!.appendingPathComponent("myLikes.json")
    }
    
    init() {
        createMyLikesFileIfNeeded()
        loadLikes()
    }
    
    private func createMyLikesFileIfNeeded() {
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: fileURL.path) else { return }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: [], options: [])
            try data.write(to: fileURL, options: [])
        } catch {
            print("Error creating myLikes.json: \(error)")
        }
    }
    
    private func loadLikes() {
        do {
            let data = try Data(contentsOf: fileURL)
            let ids = try JSONSerialization.jsonObject(with: data, options: []) as? [String] ?? []
            self.likedIDs = Set(ids)
        } catch {
            print("Error reading or parsing myLikes.json: \(error)")
        }
    }
    
    func doesIDExist(_ id: String) -> Bool {
        likedIDs.contains(id)
    }
    
    func addID(_ id: String) {
        guard !likedIDs.contains(id) else { return }
        
        likedIDs.insert(id)
        saveLikes()
    }
    
    func deleteID(_ id: String) {
        guard likedIDs.contains(id) else { return }
        
        likedIDs.remove(id)
        saveLikes()
    }
    
    private func saveLikes() {
        do {
            let idsArray = Array(likedIDs)
            let data = try JSONSerialization.data(withJSONObject: idsArray, options: [])
            try data.write(to: fileURL, options: [])
        } catch {
            print("Error writing to myLikes.json: \(error)")
        }
    }
}
