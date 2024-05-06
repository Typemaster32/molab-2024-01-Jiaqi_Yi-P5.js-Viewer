import SwiftUI
import Foundation

struct ScrollingView: View {
    @StateObject private var viewModel = InfiniteScrollViewModel()
    
    var body: some View {
        NavigationView {  // Added NavigationView
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.items) { item in
                        ItemView(item: item)
                            .onAppear {
                                viewModel.loadMoreContentIfNeeded(currentItem: item)
                                print("------[ScrollingView]------")
                            }
                    }
                    if viewModel.isFetching {
                        ProgressView()
                    }
                }
            }
            .onAppear {
                viewModel.refreshData()
                let fileManager = FileManager.default
                if let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                    print("[ScrollingView]:Documents Directory: \(documentsPath)")
                }
            }
        }.navigationTitle("Sketches")
    }
}

// Next: click image; progressingView;
struct ItemView: View {
    let item: Item
    @State private var isActive = false
    var body: some View {
        VStack(alignment: .leading) {
            NavigationLink(destination: downloadSketchWithURL(urlString: "https://editor.p5js.org/editor/projects/\(item.p5id)/zip", author: item.author, title: item.title, p5id: item.p5id, createdAt: item.createdAt), isActive: $isActive) {
                Button(action: {
                    print("Image or placeholder tapped for item: \(item.id)")
                    isActive = true
                }) {
                    Group {
                        if let imageURL = localFileURL(for: item.previewName), FileManager.default.fileExists(atPath: imageURL.path) {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure(_), .empty:
                                    placeholderImage
                                @unknown default:
                                    placeholderImage
                                }
                            }
                        } else {
                            placeholderImage
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Text(item.title)
                .font(.headline)
            
            Button(item.author) {
                print("Placeholder action for \(item.author)")
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.blue)
            
            HStack {
                Text("\(item.likes) Like\(item.likes != 1 ? "s" : "")")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.gray)
                    .padding(0)
                Spacer()
                Text("Created At: \(formattedDate(item.createdAt))")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.gray)
                    .padding(0)
            }
            .padding(1)
        }
        .padding()
        .background(Color.white)
    }
    
    var placeholderImage: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .stroke(Color.gray, lineWidth: 0)
                    .background(Color.white)
                    .frame(width: geometry.size.width, height: geometry.size.width)
                
                Image(systemName: "questionmark.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .background(Color.white)
            }
        }
        .frame(height: UIScreen.main.bounds.width)
    }
    
    
    
    func localFileURL(for imageName: String) -> URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Previews")
            .appendingPathComponent(imageName)
    }
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm, MMM dd, yyyy"
        return formatter.string(from: date)
    }
}


