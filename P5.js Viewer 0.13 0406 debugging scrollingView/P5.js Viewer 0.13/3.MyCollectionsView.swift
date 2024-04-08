import SwiftUI
struct ElementModel: Identifiable, Codable {
    var id = UUID() // Conforming to Identifiable
    let title: String
    let author: String
    let folderURL: String //This should actually be a URL
}
struct CollectionsView: View {
    @State var elements: [ElementModel] = [] // Assume this is loaded with data
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(elements) { element in
                        if let thumbnailURL = self.getThumbnailURL(for: element) {
                            let folderURL = thumbnailURL.deletingLastPathComponent()
                            NavigationLink(destination: WebContentView(sourceLocalURL: folderURL, title: element.title, author: element.author)) {
                                VStack {
                                    AsyncImageView(url: thumbnailURL)
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                    Text(element.title)
                                    Text(element.author)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        } else {
                            // Handle the case where thumbnailURL is nil, perhaps with a placeholder view 
                            VStack {
                                Image(systemName: "exclamationmark.circle")
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                Text("Caution!")
                                Text("URL is invalid")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                }
            }
            .navigationTitle("Collections")
            .onAppear {
                self.loadCollectionList()
            }
            
        }
    }
    private func loadCollectionList() {// This is to get the json into the "Sketch"
        print("---CollectionsView--- Checking the existence of Collections")
        guard let theFolderURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Collections") else {
            print("Failed to find Collections folder.")
            return
        }
        let collectionListURL = theFolderURL.appendingPathComponent("collectionlist.json")
        print("Attempting to load from: \(collectionListURL.path)") // Debugging line
        
        DispatchQueue.global(qos: .background).async {
            if let data = try? Data(contentsOf: collectionListURL),
               let decodedList = try? JSONDecoder().decode([ElementModel].self, from: data) {
                DispatchQueue.main.async {
                    self.elements = decodedList
                    print("Loaded \(decodedList.count) elements.") // Debugging line
                }
            } else {
                print("Failed to load or decode collection list.")
            }
        }
    }
    
    private func getThumbnailURL(for element: ElementModel) -> URL? { // this is to find the URL to the thumbnail
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Could not find the Documents directory.")
            return nil
        }
        // Construct the full path to the thumbnail dynamically
        
        if let url = URL(string: element.folderURL) {
            // Use the safely unwrapped URL here
            let collectionsDirectoryURL = documentsURL.appendingPathComponent("Collections")
            let lastURLcomponent = url.lastPathComponent
            let thumbnailFolderURL = collectionsDirectoryURL.appendingPathComponent(lastURLcomponent)
            let thumbnailURL = thumbnailFolderURL.appendingPathComponent("thumbnail.jpg")
            // Check if the thumbnail file exists at the constructed URL
            return thumbnailURL
        } else {
            print("Invalid URL string: \(element.folderURL)")
            return nil
        }
        
    }
    
    
}



class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    
    func load(fromURL url: URL) {
        // Check if the file exists before attempting to load it
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("File does not exist at path: \(url.path)")
            // Here you could set a default image or handle the error as appropriate
            return
        }
        
        // If the file exists, proceed with loading
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let loadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = loadedImage
                }
            } else {
                print("Failed to load image from URL: \(url)")
                // Handle failed load (e.g., set a placeholder image)
            }
        }.resume()
    }
}


struct AsyncImageView: View {
    @ObservedObject private var imageLoader = ImageLoader()
    let placeholder: Image
    let url: URL
    
    init(url: URL, placeholder: Image = Image(systemName: "photo")) {
        self.url = url
        self.placeholder = placeholder
        self.imageLoader.load(fromURL: url)
    }
    
    var body: some View {
        if let image = imageLoader.image {
            Image(uiImage: image)
                .resizable()
        } else {
            placeholder
        }
    }
}

