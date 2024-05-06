import Foundation
import FirebaseStorage
import FirebaseFirestore

struct Item: Identifiable, Codable {
    var id: String
    var p5id: String
    var title: String
    var author: String
    var createdAt: Date
    var updatedAt: String
    var previewName: String
    var sketchURL: String
    var likes: Int
    
    // Default initializer
    init(id: String = UUID().uuidString, p5id: String, title: String, author: String, createdAt: Date, updatedAt: String, previewName: String) {
        self.id = id
        self.p5id = p5id
        self.title = title
        self.author = author
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.previewName = previewName
        self.sketchURL = "https://editor.p5js.org/editor/projects/\(id)"
        self.likes = 0
        print("[Item][init]: \(self.sketchURL)")
    }
    
    // Initializer from Firestore document
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else {
            print("\(red)[Item][init-Optional]:No data found in document \(document.documentID)")
            return nil
        }
        
        guard let p5id = data["p5id"] as? String,
              let title = data["title"] as? String,
              let author = data["author"] as? String,
              let likes = data["likes"] as? Int,
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
              let updatedAt = data["updatedAt"] as? String,
              // Save for later
//              let updatedAtString = data["updatedAt"] as? String,
//              let updatedAt = ISO8601DateFormatter().date(from: updatedAtString),
              let previewName = data["thumbnailURL"] as? String
        else {
            print("\(red)[Item][init-Optional]:Data missing or incorrect type in document \(document.documentID)")
            return nil
        }
        
        self.id = document.documentID
        self.p5id = p5id
        self.title = title
        self.author = author
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.previewName = previewName
        self.sketchURL = "https://editor.p5js.org/editor/projects/\(p5id)" // Assuming p5id is the correct parameter for the URL
        self.likes = likes
        print("[Item][init-Optional]: \(self.sketchURL)")
    }

}
