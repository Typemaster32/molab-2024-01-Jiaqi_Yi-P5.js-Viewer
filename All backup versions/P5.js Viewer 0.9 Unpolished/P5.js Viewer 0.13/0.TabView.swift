import SwiftUI
import Foundation

struct ContentView: View {
    @StateObject private var viewModelSearch = SearchViewModel()
    var body: some View {
        TabView(selection: $viewModelSearch.selectedTab) {
            ScrollingView()
                .tabItem {
                    Image(systemName: "globe.asia.australia")
                    Text("Published")
                }.tag(0)
//            ExamplesView()
//                .tabItem {
//                    Image(systemName: "list.bullet.rectangle.portrait")
//                    Text("Examples")
//                }
//            // List is having a problem. Consider going back to previous version
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search Artist")
                }.tag(1)
            
            CollectionsView()
                .tabItem {
                    Image(systemName: "person")
                    Text("My Collection")
                }.tag(2)
//            
//            SettingsView()
//                .tabItem {
//                    Image(systemName: "gear")
//                    Text("Settings")
//                }.tag(3)
        }.environmentObject(viewModelSearch) 
    }
}


extension View {
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
