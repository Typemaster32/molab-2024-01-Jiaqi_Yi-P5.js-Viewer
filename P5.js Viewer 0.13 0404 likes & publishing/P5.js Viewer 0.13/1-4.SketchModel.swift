import Foundation
import FirebaseStorage
import FirebaseFirestore

struct Item: Identifiable, Codable {
    var id: String
    var p5id: String
    var title: String
    var author: String
    var createdAt: String
    var updatedAt: String
    var previewURL: URL
    var sketchURL: String
    var likes: Int
    
    // Default initializer
    init(id: String = UUID().uuidString, p5id: String, title: String, author: String, createdAt: String, updatedAt: String, previewURL: URL, sketchURL: String) {
        self.id = id
        self.p5id = p5id
        self.title = title
        self.author = author
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.previewURL = previewURL
        self.sketchURL = sketchURL
        self.likes = 0
    }
    
    // Initializer from Firestore document
    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let p5id = data["p5id"] as? String,
              let title = data["title"] as? String,
              let author = data["author"] as? String,
              let likes = data["likes"] as? Int,
              let createdAt = data["createdAt"] as? String,
              let updatedAt = data["updatedAt"] as? String,
              let previewURLString = data["previewURL"] as? String,
              let sketchURL = data["sketchURL"] as? String,
              let previewURL = URL(string: previewURLString) else { return nil }
        
        self.id = document.documentID
        self.p5id = p5id
        self.title = title
        self.author = author
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.previewURL = previewURL
        self.sketchURL = sketchURL
        self.likes = likes
    }
}


let db = Firestore.firestore()

func addDocument(_ targetItem: Item, completion: @escaping (Item?) -> Void) {
    let db = Firestore.firestore()
    let collectionRef = db.collection("sketches")
    
    var localItem = targetItem // Make a local copy of targetItem to modify
    var ref: DocumentReference? = nil
    ref = collectionRef.addDocument(data: [
        "title": localItem.title,
        "p5id": localItem.p5id,
        "author": localItem.author,
        "createdAt": localItem.createdAt,
        "updatedAt": localItem.updatedAt,
        "thumbnailURL": localItem.previewURL.absoluteString,
        // "sketchURL": localItem.sketchURL.absoluteString
        "likes": 1
    ]) { err in
        if let err = err {
            print("Error adding document: \(err)")
            completion(nil)
        } else {
            // Here, use the document reference (`ref`) to get the document ID
            if let documentID = ref?.documentID {
                localItem.id = documentID
                print("Document added with ID: \(documentID)")
                completion(localItem) // Return the updated item with the correct ID via the completion handler
            } else {
                completion(nil)
            }
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
