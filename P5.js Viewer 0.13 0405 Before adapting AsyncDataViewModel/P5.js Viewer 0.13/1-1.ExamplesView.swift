import SwiftUI
import FirebaseCore

struct ExamplesView: View {
    @StateObject private var contentManager = FolderContentManager()
    //@StateObject is tied with ObservableObject to hold the source of the truth.
    //private means it could only be changed within this scope.
    var body: some View {
        VStack{
            Text("[04.05] Currently have a problem")
            //            NavigationView {
            //                if contentManager.isLoading {
            //                    ProgressView("Loading...")
            //                } else {
            //                    List(contentManager.namesOfFiles, id: \.name) { file in
            //                        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            //                            let newFilePath = documentsDirectory.appendingPathComponent("Examples/\(file.name)")
            //                            var fileURL:URL = newFilePath
            //                            NavigationLink(destination: WebContentView(sourceURL: fileURL, title: removeDotZip(from: file.name),author: "Unknown")) {
            //
            //                                Text(adjustedName(from: file.name))
            //                                    .lineLimit(1)
            //                            }
            //                            //withExtension: "zip" causes "invalid file"
            //
            //                            // Fallback content in case the URL couldn't be constructed
            //                        }
            //
            //
            //
            //                    }
            //                    .navigationTitle("P5 Viewer").onAppear {
            //                        contentManager.loadContent()
            //                        //                print("Content Manager Files: \(contentManager.namesOfFiles)")
            //                    }
            //                }
            //            }
        }
    }
}


