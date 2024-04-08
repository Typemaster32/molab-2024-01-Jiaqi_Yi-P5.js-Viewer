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
    var previewName: String
    var sketchURL: String
    var likes: Int
    
    // Default initializer
    init(id: String = UUID().uuidString, p5id: String, title: String, author: String, createdAt: String, updatedAt: String, previewName: String, sketchURL: String) {
        self.id = id
        self.p5id = p5id
        self.title = title
        self.author = author
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.previewName = previewName
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
              let previewNameString = data["previewName"] as? String,
              let sketchURL = data["sketchURL"] as? String,
              let previewName = URL(string: previewNameString) else { return nil }
        // ATTENTION: still need to update previewURL here(actually preview iamge name):
        self.id = document.documentID
        self.p5id = p5id
        self.title = title
        self.author = author
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.previewName = previewNameString
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
        "thumbnailURL": localItem.previewName,
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



func localFileURL(for imageName: String) -> URL? { // This is to get the previews into the Previews folder(and create if there's not)
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
    // Check if the input is a URL (including local file URLs)
    if let url = URL(string: input) {
        return url.lastPathComponent // Returns the last component of the URL (e.g., "YiJiaqi-YOYO-2.2.jpg")
    } else {
        // If the input is not a URL, assume it's already just the name of the image
        return input
    }
}

let red = "ERROR" // error
let green = "Function" // function
let yellow = "\u{001B}[33m"
let blue = "Class" // class / struct
let reset = "\u{001B}[0m"
