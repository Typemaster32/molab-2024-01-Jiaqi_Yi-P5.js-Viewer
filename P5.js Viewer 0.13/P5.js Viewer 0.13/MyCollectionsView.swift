import SwiftUI
struct MyCollections: View {
    var body: some View {
        NavigationView {
            Form {
            }
            .navigationTitle("My Collection")
        }
    }
}

//#Preview {
//    MyCollections()
//}


struct ElementModel: Identifiable {
    let id: String
    let name: String
    let authorName: String
    let imageName: String? // Use this if the image is stored locally
}

struct ElementView: View {
    let element: ElementModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(element.imageName ?? "placeholder") // "placeholder" is the name of your placeholder image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipped()
                .cornerRadius(8)
            
            Text(element.name)
                .font(.headline)
            
            Text("By \(element.authorName)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct MyCollectionsView: View {
    // Sample elements
    var elements: [ElementModel] = [
        // Initialize your elements here
    ]
    
    let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
        // Adjust the number of columns as needed
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(elements) { element in
                    ElementView(element: element)
                }
            }
            .padding()
        }
    }
}


