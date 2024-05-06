import Foundation
import FirebaseStorage
import FirebaseFirestore



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
        "thumbnailURL": localItem.previewName,
        // "sketchURL": localItem.sketchURL.absoluteString
        "likes": 0
    ]) { err in
        if let err = err {
            print("\(red)[Firebase][addDocument]:Error adding document: \(err)")
            completion(nil)
        } else {
            // Here, use the document reference (`ref`) to get the document ID
            if let documentID = ref?.documentID {
                localItem.id = documentID
                print("[Firebase][addDocument]:Document added with ID: \(documentID)")
                completion(localItem) // Return the updated item with the correct ID via the completion handler
            } else {
                completion(nil)
            }
        }
    }
}


func getDocument(_ documentID: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
    
    print("[Firebase][getDocument]")
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

func localFileURL(for imageName: String) -> URL? { // This is to get the previews into the Previews folder(and create if there's not)
    
//    print("[Firebase][localFileURL]:\(imageName)")
    let fileManager = FileManager.default
    let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Previews")
    
    // Create "Previews" directory if it doesn't exist
    if let directory = directory, !fileManager.fileExists(atPath: directory.path) {
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating directory: \(error)")
            return nil
        }
    }
    
    return directory?.appendingPathComponent(imageName)
}


func extractImageName(from input: String) -> String? {
    
    print("[Firebase][extractImageName]")
    // Check if the input is a URL (including local file URLs)
    if let url = URL(string: input) {
        return url.lastPathComponent // Returns the last component of the URL (e.g., "YiJiaqi-YOYO-2.2.jpg")
    } else {
        // If the input is not a URL, assume it's already just the name of the image
        return input
    }
}


func uploadImageToFirebaseStorage(imageURL: URL) { // This is to upload the Previews to the firebase
// Create a reference to the Firebase Storage location where you want to upload the image
    let storageRef = Storage.storage().reference().child("previews/\(imageURL.lastPathComponent)")
    // Upload the image
    storageRef.putFile(from: imageURL, metadata: nil) { metadata, error in
        guard metadata != nil else {
            // Handle any errors
            print("[uploadImageToFirebaseStorage]:Error uploading image: \(error?.localizedDescription ?? "No error description")")
            return
        }
        
        // Image uploaded successfully
        print("[uploadImageToFirebaseStorage]: Image uploaded successfully.")
    }
}
