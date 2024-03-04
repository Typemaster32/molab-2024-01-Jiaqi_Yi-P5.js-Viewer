import SwiftUI
import WebKit
import ZIPFoundation

struct WebContentView: View {
    var sourceURL: URL
    var title: String
    @State private var isPresentingFullScreenView = false
    @State private var unzippedContentURL: URL? = nil
    @State private var webViewSnapshotter: WebViewSnapshotter?
    @State private var showAlert = false
    @State private var alertMessage = "Currently, importing p5.sound makes the infinite loading problem.(<script src=\"https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.1.9/addons/p5.sound.min.js\"></script>)"
    
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Author: Unknown").font(.subheadline)
                
                if let unzippedURL = unzippedContentURL {
                    WebView(url: unzippedURL)
                        .frame(width: geometry.size.width * 0.95, height: geometry.size.width * 0.95 * (4 / 3)).border(Color.gray, width: 1)
                } else {
                    Text("Loading...")
                        .onAppear {
                            unzipContent(sourceURL: sourceURL) { unzippedURL in
                                self.unzippedContentURL = unzippedURL
                            }
                        }
                }
                Button("Open Full Screen") {
                    self.isPresentingFullScreenView = true
                }
                .foregroundColor(.blue)
                .padding(5)
                .fullScreenCover(isPresented: $isPresentingFullScreenView) {
                    if let unzippedURL = unzippedContentURL {
                        FullScreenWebView(sourceURL: unzippedURL)
                    }else{Text("Unzipping Failed")}
                };
                //Button1: Open Full Screen
                
                Button("Save Image") {
                    if let unzippedURL = unzippedContentURL {
                        webViewSnapshotter = WebViewSnapshotter(url: unzippedURL) { image in
                            if let image = image {
                                print("Snapshot taken successfully from the path below: ")
                                print(unzippedURL)
                                ImageSaver.shared.saveImage(image)
                                self.webViewSnapshotter = nil // Clear the reference once done
                            } else {
                                print("Failed to take snapshot")
                            }
                        }
                    }
                }.foregroundColor(.blue)
                    .padding(5)
                //Button2: Save Image
                
                Button("Save Live Photo") {
                    //                    EmptyView()
                }.foregroundColor(.blue)
                    .padding(5)
                //Button3: Save Image
                
                Button("More Info") {
                    self.showAlert = true
                }.foregroundColor(.gray)
                    .padding(5)
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Problems to be fixed:"),
                            message: Text(alertMessage),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                //Button3: Save Image
                
                
            }.navigationBarTitle(Text(title), displayMode: .inline)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            //            .multilineTextAlignment(.center)
        }
    }
}




//                Button("Save Image"){
//                    if let unzippedURL = unzippedContentURL {
//                        _ = WebViewSnapshotter(url: unzippedURL) { image in
//                            if image != nil {
//                                // Process image, e.g., save to disk
//                                print("Snapshot taken successfully")
//                            } else {
//                                print("Failed to take snapshot")
//                            }
//                        }
//                    }
//                }.foregroundColor(.blue)

//struct WebContentView: View {
//    var sourceURL: URL
//    var title: String
//        // For modal presentation without introducing new @State variables,
//        // we can leverage .sheet's onDismiss or use a workaround to trigger the sheet.
//    @State private var isPresentingFullScreenView: Bool = false
//    var body: some View {
//        GeometryReader { geometry in
//            VStack {
//                    // Spacer(minLength: 20) // Optional: Adjust space above the title as needed
//                Text(title)
//                    .font(.headline)
//                    .padding([.leading, .trailing], 20)
//                Text("Author: Unknown")
//                    .font(.subheadline)
//                    // Calculate width and height based on desired aspect ratio and screen width
//                let webViewWidth = geometry.size.width * 0.95
//                let webViewHeight = webViewWidth * (4 / 3) // 4:3 aspect ratio
//
//                UnzipAndPrepare(sourceURL: sourceURL)
//                    .frame(width: webViewWidth, height: webViewHeight)
//                    .cornerRadius(10) // Optional: Adds rounded corners to the WebView
//                    .padding(.bottom, 40)
//                    .border(Color.gray, width: 1)  // Space between the WebView and the footer
//
//                Button(action: {
//                    self.isPresentingFullScreenView = true
//                }) {
//                    Text("Open Full Screen")
//                        .foregroundColor(.blue)
//                        .padding()
//                }
//                .sheet(isPresented: $isPresentingFullScreenView) {
//                        // Here you present another instance of WebContentView or a different
//                        // view designed for full screen. Adjust sourceURL as needed.
//                    FullScreenWebView(sourceURL: sourceURL)
//
//                }
//                Spacer(minLength: 20)
//            }
//            .frame(width: geometry.size.width)
//            .multilineTextAlignment(.center) // Ensure text is centered if it wraps
//        }
//    }
//}
//
//
//struct WebContentView_Previews: PreviewProvider {
//    static var previews: some View {
//            // Attempt to construct the URL for the local resource
//        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "TestSketch1981360") {
//            WebContentView(sourceURL: url, title: "TestTitle")
//        } else {
//                // Fallback content in case the URL couldn't be constructed
//            Text("Could not load the URL")
//        }
//    }
//}


