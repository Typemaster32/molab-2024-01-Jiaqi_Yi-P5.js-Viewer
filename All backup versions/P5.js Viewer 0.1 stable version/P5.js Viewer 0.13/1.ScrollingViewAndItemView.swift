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
                                print("[ScrollingView][ItemView][onAppear]: triggered with p5id: \(item.p5id)")
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
                    print("[ScrollingView][ScrollView][onAppear]:Documents Directory: \(documentsPath)")
                }
            }
        }.navigationTitle("Sketches")
    }
}



