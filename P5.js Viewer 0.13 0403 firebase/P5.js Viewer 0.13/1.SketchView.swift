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
            // Assume an AsyncImage or similar view for displaying the thumbnail
            // AsyncImage(url: item.thumbnailURL)
        }
        .padding()
    }
}


