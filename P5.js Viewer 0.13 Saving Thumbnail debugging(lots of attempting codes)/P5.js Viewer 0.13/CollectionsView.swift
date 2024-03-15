import SwiftUI
import Foundation
struct MyCollections: View {
    var body: some View {
        NavigationView {
            Form {
            }
            .navigationTitle("My Collection")
        }
    }
}

//struct MyCollectionsView: View {
//    var body: some View {
//        NavigationView {
//            MyCollectionsViewControllerWrapper()
//                .navigationTitle("My Collection")
//        }
//    }
//}


struct MyCollectionsViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MyCollectionsViewController {
        // Initialize the layout and view controller
        let layout = UICollectionViewFlowLayout()
        let myCollectionsViewController = MyCollectionsViewController(collectionViewLayout: layout)
        // Perform any additional configuration on the view controller here
        return myCollectionsViewController
    }
    
    func updateUIViewController(_ uiViewController: MyCollectionsViewController, context: Context) {
        // Update the view controller in response to state changes, if needed
    }
}


struct ElementModel: Codable {
    var title: String
    var author: String
    var folderURL: URL
}



class MyCollectionsViewController: UICollectionViewController {
    var elements: [ElementModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        elements = DataManager.shared.loadElements()
        collectionView.reloadData()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return elements.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ElementCell", for: indexPath)
        let element = elements[indexPath.item]
        configureCell(cell, with: element)
        return cell
    }
    
    func configureCell(_ cell: UICollectionViewCell, with element: ElementModel) {
        // Assuming you have a custom cell. Adjust accordingly.
        // Load the image from the folderURL. If the image doesn't exist, use the sf icon.
        let imagePath = element.folderURL.appendingPathComponent("p5viewer_thumbnail.jpg").path
        let image: UIImage
        if FileManager.default.fileExists(atPath: imagePath) {
            image = UIImage(contentsOfFile: imagePath) ?? UIImage(systemName: "questionmark.circle")!
        } else {
            image = UIImage(systemName: "questionmark.circle")!
        }
        
        // Configure your cell here with the image and other element data
    }
}

struct ElementView: View {
    var element: ElementModel
    
    // Attempt to load the thumbnail image; fall back to system icon if unavailable
    var thumbnailImage: Image {
        let fileManager = FileManager.default
        let imagePathJPG = element.folderURL.appendingPathComponent("p5viewer_thumbnail.jpg").path
        let imagePathPNG = element.folderURL.appendingPathComponent("p5viewer_thumbnail.png").path
        
        if fileManager.fileExists(atPath: imagePathJPG),
           let uiImage = UIImage(contentsOfFile: imagePathJPG) {
            return Image(uiImage: uiImage)
        } else if fileManager.fileExists(atPath: imagePathPNG),
                  let uiImage = UIImage(contentsOfFile: imagePathPNG) {
            return Image(uiImage: uiImage)
        } else {
            return Image(systemName: "questionmark.circle")
        }
    }
    
    var body: some View {
        VStack {
            thumbnailImage
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
            Text(element.title)
                .font(.headline)
            Text("Author: \(element.author)")
                .font(.subheadline)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

struct MyCollectionsView: View {
    @State private var elements: [ElementModel] = []
    
    // Load elements from JSON file when the view appears
    private func loadElements() {
        self.elements = DataManager.shared.loadElements()
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                ForEach(elements, id: \.title) { element in
                    ElementView(element: element)
                }
            }
            .padding()
        }
        .onAppear(perform: loadElements)
    }
}

//#Preview {
//    MyCollectionsView(elements:[])
//}


//struct ElementView: View {
//    let element: ElementModel
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Image(element.imageName ?? "placeholder") // "placeholder" is the name of your placeholder image
//                .resizable()
//                .aspectRatio(contentMode: .fill)
//                .frame(width: 100, height: 100)
//                .clipped()
//                .cornerRadius(8)
//
//            Text(element.name)
//                .font(.headline)
//
//            Text("By \(element.authorName)")
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//        }
//        .padding()
//    }
//}
//
//struct MyCollectionsView: View {
//    // Sample elements
//    var elements: [ElementModel] = [
//        // Initialize your elements here
//    ]
//
//    let columns: [GridItem] = [
//        GridItem(.flexible()),
//        GridItem(.flexible())
//        // Adjust the number of columns as needed
//    ]
//
//    var body: some View {
//        ScrollView {
//            LazyVGrid(columns: columns, spacing: 20) {
//                ForEach(elements) { element in
//                    ElementView(element: element)
//                }
//            }
//            .padding()
//        }
//    }
//}

