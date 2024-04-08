
import SwiftUI
import WebKit
import UIKit
import Combine
import ZIPFoundation
import Firebase
import FirebaseFirestore
// Function to fetch an element from the "sketches" collection based on field name and value
func fetchSketch(byFieldName fieldName: String, fieldValue: String, completion: @escaping (Item?) -> Void) {
    // Reference to Firestore and the specific collection
    let db = Firestore.firestore()
    let collectionRef = db.collection("sketches")
    
    // Query the collection for documents where the specified field matches the given value
    collectionRef.whereField(fieldName, isEqualTo: fieldValue).getDocuments { (querySnapshot, error) in
        if let error = error {
            // If there's an error fetching the documents, print the error
            print("Error fetching document: \(error)")
            // Dispatch the completion handler call to the main thread
            DispatchQueue.main.async {
                completion(nil)
            }
        } else {
            if let document = querySnapshot?.documents.first, let item = Item(document: document) {
                // Dispatch the completion handler call to the main thread
                DispatchQueue.main.async {
                    completion(item)
                }
            } else {
                // If no document was found or the Item could not be initialized
                // Dispatch the completion handler call to the main thread
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}


// Async Version of the fetchSketch;
// Create an Async Wrapper: You'll wrap your existing fetchSketch function inside a new function that can be awaited. This wrapper will use a Continuation to bridge between the completion handler and async/await.
func fetchSketchAsync(byFieldName fieldName: String, fieldValue: String) async -> Item? {
    await withCheckedContinuation { continuation in
        fetchSketch(byFieldName: fieldName, fieldValue: fieldValue) { item in
            continuation.resume(returning: item)
        }
    }
}


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

func updateSketchInFirestore(item: Item, completion: @escaping (Bool) -> Void) {
    let db = Firestore.firestore()
    let documentRef = db.collection("sketches").document(item.id)
    
    // Prepare the data to update
    let updateData: [String: Any] = [
        "title": item.title,
        // Add other fields of the Item you want to update
        "updatedAt": item.updatedAt // Assuming you also update the updatedAt field
    ]
    
    // Update the document
    documentRef.updateData(updateData) { error in
        if let error = error {
            print("Error updating document: \(error)")
            completion(false)
        } else {
            print("Document successfully updated")
            completion(true)
        }
    }
}

class ViewModel: ObservableObject {
    @Published var isPublished = false
    @Published var isLoading = false
    @Published var likesNumber: Int = 0
    private var p5id: String
    
    init(p5id: String) {
        self.p5id = p5id
    }
    
    func checkPublishStatusAndLikes() async {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        if let item = await fetchSketchAsync(byFieldName: "p5id", fieldValue: p5id) {
            DispatchQueue.main.async {
                self.isPublished = true
                self.likesNumber = item.likes
                self.isLoading = false
            }
        } else {
            DispatchQueue.main.async {
                self.isPublished = false
                self.isLoading = false
            }
        }
    }
}


