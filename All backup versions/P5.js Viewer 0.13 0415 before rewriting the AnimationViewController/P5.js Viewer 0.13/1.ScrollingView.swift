import SwiftUI
import Foundation

struct ScrollingView: View {
    @EnvironmentObject var viewModelSearch: SearchViewModel
    @StateObject private var viewModelScrolling = InfiniteScrollViewModel()
    
    var body: some View {
        NavigationView {  // Added NavigationView
            ScrollView {
                LazyVStack {
                    ForEach(viewModelScrolling.items) { item in
                        ItemView(item: item)
                            .onAppear {
                                viewModelScrolling.loadMoreContentIfNeeded(currentItem: item)
                                viewModelScrolling.refreshData()
                                print("[ScrollingView][ItemView][onAppear]: triggered with p5id: \(item.p5id)")
                            }
                    }
                    if viewModelScrolling.isFetching {
                        ProgressView()
                    }
                }
            }
            .onAppear {
                viewModelScrolling.refreshData()
                let fileManager = FileManager.default
                if let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                    print("[ScrollingView][ScrollView][onAppear]:Documents Directory: \(documentsPath)")
                }
            }
        }.navigationTitle("Sketches")
    }
}



