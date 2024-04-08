import SwiftUI
import FirebaseCore

struct ExamplesView: View {
    @StateObject private var contentManager = FolderContentManager()
    //@StateObject is tied with ObservableObject to hold the source of the truth.
    //private means it could only be changed within this scope.
    var body: some View {
        VStack{
            NavigationView {
                List(contentManager.namesOfFiles, id: \.name) { file in
                    // \.name means Key Path. Here it serves as the unique identifier.
                    // This iterates over files, using file as the identifier for the current element.
                    // Assuming file.name contains the filename without path
                    if let fileURL = Bundle.main.url(forResource: file.name, withExtension: nil, subdirectory: "Examples") {
                        NavigationLink(destination: WebContentView(sourceURL: fileURL, title: removeDotZip(from: file.name),author: "Unknown")) {
                            Text(adjustedName(from: file.name))
                                .lineLimit(1)
                        }
                        //withExtension: "zip" causes "invalid file"
                    } else {
                        // Fallback content in case the URL couldn't be constructed
                        Text("Invalid file: \(file.name)")
                    }
                }
                .navigationTitle("P5 Viewer").onAppear {
                    contentManager.loadContent()
                    //                print("Content Manager Files: \(contentManager.namesOfFiles)")
                }
            }
        }
    }
}


