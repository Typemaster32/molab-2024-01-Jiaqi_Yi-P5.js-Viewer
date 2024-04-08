import SwiftUI
import Foundation

struct ContentView: View {
    var body: some View {
        TabView {
            
            
            ExamplesView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.portrait")
                    Text("Examples")
                }
            // List is having a problem. Consider going back to previous version
            
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
    @Published var namesOfFiles: [(name: String, link: String)] = [(name: "1",link:"2")]
    @Published var isLoading = true
    //@Published means this property is notifying everybody when it changes
    init() {
        loadContent()
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let documentsDirectory = paths.first {
            print("[FolderContentManager]: Initiating ExampleView: Root Path:\(documentsDirectory)")
        }
    }
    
    
    func loadContent() {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        do {
            let folders = try listFolders(in: "Examples")
            DispatchQueue.main.async {
                self.namesOfFiles = folders
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                print("[FolderContentManager]: Failed to load folder contents: \(error)")
                self.isLoading = false
            }
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
