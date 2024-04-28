import SwiftUI
struct ElementModel: Identifiable, Codable {
    var id = UUID() // Conforming to Identifiable
    let title: String
    let author: String
    let folderURL: String //This should actually be a URL
    let p5id: String
    let createdAt: Date
}
