import SwiftUI
import WebKit
import ZIPFoundation

struct WebContentView: View {
    var sourceURL: URL
    var title: String
    @State private var isPresentingFullScreenView = false
    @State private var unzippedContentURL: URL? = nil
    @State private var webViewSnapshotter: WebViewSnapshotter?
    @State private var saveAnimation: SaveAnimation? // Added for SaveAnimation
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
                .padding(3)
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
                                print("From the path below: ")
                                print(unzippedURL)
                                ImageSaver.shared.saveImage(image)
                                self.webViewSnapshotter = nil // Clear the reference once done
                            } else {
                                print("Failed to take snapshot")
                            }
                        }
                    }
                }.foregroundColor(.blue)
                    .padding(3)
                //Button2: Save Image
                
                Button("Start Animation Capture") {
                    if let unzippedURL = unzippedContentURL {

                    }
                }
                .foregroundColor(.blue)
                .padding(3)
                //Button3: Save Image
                
                Button("More Info") {
                    self.showAlert = true
                }.foregroundColor(.gray)
                    .padding(3)
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
