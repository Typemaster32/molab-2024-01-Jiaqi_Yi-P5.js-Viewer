
import SwiftUI
import WebKit
import UIKit
import Combine
import ZIPFoundation
import Firebase
import FirebaseFirestore
// Function to fetch an element from the "sketches" collection based on field name and value

func fetchSketch(byFieldName fieldName: String, fieldValue: String, completion: @escaping (Item?) -> Void) {
    // Start logging the initiation of the fetch process
    print("[ViewModel][checkPublishStatusAndLikes][fetchSketch]: Initiated fetching documents from Firestore for field '\(fieldName)' with value '\(fieldValue)'.")
    
    // Reference to Firestore and the specific collection
    let db = Firestore.firestore()
    let collectionRef = db.collection("sketches")
    
    // Query the collection for documents where the specified field matches the given value
    collectionRef.whereField(fieldName, isEqualTo: fieldValue).getDocuments { (querySnapshot, error) in
        if let error = error {
            // Log the error encountered during the fetch
            print("[ViewModel][checkPublishStatusAndLikes][fetchSketch][Error]: Error fetching document: \(error)")
            // Dispatch the completion handler call to the main thread
            DispatchQueue.main.async {
                completion(nil)
            }
        } else {
            // Log successful document retrieval or no documents found
            print("[ViewModel][checkPublishStatusAndLikes][fetchSketch]: Documents retrieval successful, processing documents.")
            
            if let document = querySnapshot?.documents.first {
                // Log the first document found
                print("[ViewModel][checkPublishStatusAndLikes][fetchSketch]: First document found, attempting to initialize 'Item'.")
                
                if let item = Item(document: document) {
                    // Log successful item initialization
                    print("[ViewModel][checkPublishStatusAndLikes][fetchSketch]: Item initialized successfully.")
                    DispatchQueue.main.async {
                        completion(item)
                    }
                } else {
                    // Log failure to initialize item from document
                    print("[ViewModel][checkPublishStatusAndLikes][fetchSketch][Error]: Unable to initialize 'Item' from document.")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            } else {
                // Log no documents found matching the criteria
                print("[ViewModel][checkPublishStatusAndLikes][fetchSketch][Error]: No documents found or 'Item' could not be initialized.")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}

func fetchSketchAsync(byFieldName fieldName: String, fieldValue: String) async -> Item? {
    // Log the start of the async version of fetchSketch
    print("[ViewModel][checkPublishStatusAndLikes][fetchSketchAsync]: Starting async fetching of documents for field '\(fieldName)' with value '\(fieldValue)'.")
    
    return await withCheckedContinuation { continuation in
        fetchSketch(byFieldName: fieldName, fieldValue: fieldValue) { item in
            if item != nil {
                // Log the successful continuation resumption with an item
                print("[fetchSketchAsync]: Resuming continuation with an 'Item'.")
            } else {
                // Log the continuation resumption with nil
                print("[fetchSketchAsync][Error]: Resuming continuation with nil - item not found or error occurred.")
            }
            continuation.resume(returning: item)
        }
    }
}



func updateSketchInFirestore(item: Item, completion: @escaping (Bool) -> Void) {
    // Log the initiation of the update process
    print("[updateSketchInFirestore]: Initiating update for document with ID '\(item.id)'.")
    
    // Reference to Firestore and the specific document
    let db = Firestore.firestore()
    let documentRef = db.collection("sketches").document(item.id)
    
    // Log the Firestore collection and document being used
    print("[updateSketchInFirestore]: Using Firestore document located at 'sketches/\(item.id)'.")
    
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    
    // Get the current date and format it as a string
    let now = Date()
    let dateString = dateFormatter.string(from: now)
    // Prepare the data to update
    let updateData: [String: Any] = [
        "likes": item.likes,
        // Add other fields of the Item you want to update
        "updatedAt": dateString // Assuming you also update the updatedAt field
    ]
    
    // Log the data that will be sent for updating
    print("[updateSketchInFirestore]: Prepared update data: \(updateData)")
    
    // Update the document
    documentRef.updateData(updateData) { error in
        if let error = error {
            // Log the error encountered during the update
            print("[updateSketchInFirestore][Error]: Error updating document: \(error)")
            completion(false)
        } else {
            // Log the successful update of the document
            print("[updateSketchInFirestore][Success]: Document successfully updated.")
            completion(true)
        }
    }
}


class ViewModel: ObservableObject {//This is an updater of isPublished
    @Published var isPublished = false
    @Published var isLoading = false
    @Published var likesNumber: Int = 0
    private var p5id: String
    
    init(p5id: String) {
        self.p5id = p5id
        print("[ViewModel][init]: Initialized with p5id: \(p5id)")
    }
    
    func checkPublishStatusAndLikes() async {
        print("[ViewModel][checkPublishStatusAndLikes]: Checking publish status and likes started for p5id: \(p5id).")
        
        DispatchQueue.main.async {
            self.isLoading = true
            print("[ViewModel][checkPublishStatusAndLikes]: isLoading set to true.")
        }
        
        if let item = await fetchSketchAsync(byFieldName: "p5id", fieldValue: p5id) {
            DispatchQueue.main.async {
                self.isPublished = true
                self.likesNumber = item.likes
                self.isLoading = false
                print("[ViewModel][checkPublishStatusAndLikes]: Fetch successful. Publish status set to true, likes updated to \(item.likes), isLoading set to false.")
            }
        } else {
            DispatchQueue.main.async {
                self.isPublished = false
                self.isLoading = false
                print("[ViewModel][checkPublishStatusAndLikes]: Fetch failed. No item found for p5id: \(self.p5id). Publish status set to false, isLoading set to false.")
            }
        }
    }
}




let red = "ERRORERRORERRORERRORERROR" // error
let green = "---" // function
let yellow = ">>>"
let blue = "----------" // class / struct
let reset = "\u{001B}[0m"
