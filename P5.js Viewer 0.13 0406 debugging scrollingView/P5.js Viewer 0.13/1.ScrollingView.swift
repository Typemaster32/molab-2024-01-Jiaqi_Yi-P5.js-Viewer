import SwiftUI

struct ScrollingView: View {
    @StateObject private var viewModel = InfiniteScrollViewModel()
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.items) { item in
                    ItemView(item: item)
                        .onAppear {
                            viewModel.loadMoreContentIfNeeded(currentItem: item)
                            print("\(green)")
                        }
                }
            }
        }
        .onAppear {
            viewModel.fetchData() // Initial data fetch
        }
    }
}

struct ItemView: View {
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(item.title)
                .font(.headline)
            Text(item.author)
                .font(.subheadline)
            
            // Attempt to display the image if it exists, else show a placeholder
            if let imageURL = localFileURL(for: item.previewName), FileManager.default.fileExists(atPath: imageURL.path) {
                // Using AsyncImage to load from local file URL (iOS 15+)
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        placeholderImage
                    default:
                        placeholderImage
                    }
                }
                .frame(width: 100, height: 100) // Adjust size as needed
            } else {
                placeholderImage
            }
        }
        .padding()
    }
    
    var placeholderImage: some View {
        Image(systemName: "questionmark.circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 100, height: 100) // Adjust size as needed
    }
    
    func localFileURL(for imageName: String) -> URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Previews")
            .appendingPathComponent(imageName)
    }
}


