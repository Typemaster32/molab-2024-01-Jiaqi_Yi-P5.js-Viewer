import SwiftUI
import Foundation

struct ContentView: View {
    @StateObject private var contentManager = FolderContentManager()
    //@StateObject is tied with ObservableObject to hold the source of the truth.
    //private means it could only be changed within this scope.
    
    var body: some View {
        TabView {
            
            
            ExamplesView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.portrait")
                    Text("Examples")
                }
            
            ScrollingView()
                .tabItem {
                    Image(systemName: "globe.asia.australia")
                    Text("Published")
                }
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search Artist")
                }
            
            CollectionsView()
                .tabItem {
                    Image(systemName: "person")
                    Text("My Collection")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
    }
}

//By ChatGPT, modified
class FolderContentManager: ObservableObject {
    //ObservableObject is for some objects that needs to change and live update others.
    //ObservableObejct only requires an @Published property.
    @Published var namesOfFiles: [(name: String, link: String)] = []
    //@Published means this property is notifying everybody when it changes
    init() {
        loadContent()
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let documentsDirectory = paths.first {
            print("Root Path:")
            print(documentsDirectory)
        }
    }
    
    
    func loadContent() {
        do {
            let folders = try listFolders(in: "Examples")
            DispatchQueue.main.async {
                self.namesOfFiles = folders
            }
            //This means the thread is done in main
        } catch {
            print("Failed to load folder contents: \(error)")
            //error is defined by default
        }
    }
}

enum FolderListError: Error {
    case unableToAccessDirectory(reason: String)
}

//By ChatGPT, modified
func listFolders(in directoryName: String) throws -> [(name: String, link: String)] {
    guard let directoryURL = Bundle.main.url(forResource: directoryName, withExtension: nil) else {
        throw FolderListError.unableToAccessDirectory(reason: "Directory \(directoryName) not found in the bundle.")
    }
    
    let fileManager = FileManager.default
    let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
    
    // Filter for .zip files only
    let zipFiles = fileURLs.filter { $0.pathExtension == "zip" }
    
    // Create tuples of file name and path for each zip file
    let zipFileTuples = zipFiles.map { (name: $0.lastPathComponent, link: $0.path) }
    
    if zipFileTuples.isEmpty {
        throw FolderListError.unableToAccessDirectory(reason: "No zip files found in the directory \(directoryName).")
    }
    //    print("Found zip files: \(zipFileTuples)")
    return zipFileTuples
}


func adjustedName(from name: String) -> String {
    let maxLength = 40 // Define the max length of the string
    let suffixToRemove = ".zip" // Example suffix to remove
    var adjustedName = name
    
    // Remove the suffix if present
    if adjustedName.hasSuffix(suffixToRemove) {
        adjustedName = String(adjustedName.dropLast(suffixToRemove.count))
    }
    
    // Truncate the string to maxLength characters
    if adjustedName.count > maxLength {
        adjustedName = String(adjustedName.prefix(maxLength))
    }
    
    return adjustedName // (Removed) Add ellipsis to indicate truncation
}

func removeDotZip(from name: String) -> String {
    let suffixToRemove = ".zip" // Example suffix to remove
    var adjustedName = name
    
    // Remove the suffix if present
    if adjustedName.hasSuffix(suffixToRemove) {
        adjustedName = String(adjustedName.dropLast(suffixToRemove.count))
    }
    
    return adjustedName // (Removed) Add ellipsis to indicate truncation
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
