import Foundation
import FirebaseStorage
import FirebaseFirestore

struct Item: Identifiable, Decodable { //Note that this is different from the SearchView
    var id: String // Assuming there is an ID or you can use UUID().uuidString
    var title: String
    var author: String
    var createdAt: String
    var updatedAt: String
    var thumbnailURL: URL
    var sketchURL: URL
}

let db = Firestore.firestore()

func addDocument(_ targetItem: Item, completion: @escaping (Item?) -> Void) {
    let db = Firestore.firestore()
    let collectionRef = db.collection("sketches")
    
    // Add a new document with an auto-generated ID
    var localItem = targetItem // Make a local copy of targetItem to modify
    collectionRef.addDocument(data: [
        "title": localItem.title,
        "author": localItem.author,
        "createdAt": localItem.createdAt,
        "updatedAt": localItem.updatedAt,
        "thumbnailURL": localItem.thumbnailURL.absoluteString,
        "sketchURL": localItem.sketchURL.absoluteString
    ]) { err in
        if let err = err {
            print("Error adding document: \(err)")
            completion(nil)
        } else {
            // Assuming you want to use the Firestore-generated document ID to update the localItem's id
            localItem.id = collectionRef.document().documentID
            print("Document added with ID: \(localItem.id)")
            completion(localItem) // Return the updated item via the completion handler
        }
    }
}

func getDocument(_ documentID: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
    let docRef = db.collection("sketches").document(documentID)
    docRef.getDocument { (document, error) in
        if let error = error {
            // If an error occurred, pass the error to the completion handler
            completion(.failure(error))
        } else if let document = document, document.exists {
            // If the document exists, pass the document data to the completion handler
            if let data = document.data() {
                completion(.success(data))
            } else {
                // Handle the case where document exists but has no data
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Document is empty"])))
            }
        } else {
            // Handle the case where the document does not exist
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Document does not exist"])))
        }
    }
}



func uploadImage(imageData: Data) {
    // Reference to the Firebase Storage service
    let storageRef = Storage.storage().reference()
    
    // Reference to where the file should be saved in Storage
    let imageRef = storageRef.child("images/myImage.jpg")
    
    // Upload the file
    imageRef.putData(imageData, metadata: nil) { (metadata, error) in
        guard let metadata = metadata else {
            print("Error uploading image: \(error?.localizedDescription ?? "Error")")
            return
        }
        print("Image uploaded successfully. Metadata: \(metadata)")
    }
}

func downloadImage() {
    let storageRef = Storage.storage().reference()
    let imageRef = storageRef.child("images/myImage.jpg")
    
    imageRef.downloadURL { (url, error) in
        guard let downloadURL = url else {
            print("Error getting download URL: \(error?.localizedDescription ?? "Error")")
            return
        }
        // Here you can use the downloadURL to download the image
        // For example, you might pass the URL to an image downloading function
        print("Download URL: \(downloadURL)")
    }
}


//var itemToAdd = Item(id: "", title: "Innovations in Firebase", author: "Jane Doe", thumbnailURL: URL(string: "https://example.com/thumbnail.jpg")!, sketchURL: URL(string: "https://example.com/sketch.jpg")!)
//
//addDocument(itemToAdd) { updatedItem, error in
//    DispatchQueue.main.async {
//        if let error = error {
//            // Handle the error, e.g., show an alert to the user
//            print("Error occurred: \(error.localizedDescription)")
//        } else if let updatedItem = updatedItem {
//            // Use the updated item, e.g., update the UI or save the item locally
//            print("Successfully added document with ID: \(updatedItem.id)")
//            // Assume you have a method to update your UI or local data store
//            // updateUI(with: updatedItem)
//        }
//    }
//}
