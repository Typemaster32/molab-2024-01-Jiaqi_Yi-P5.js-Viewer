import SwiftUI
import WebKit
import ZIPFoundation

struct WebContentView: View {
    var sourceURL: URL
    var title: String
    var author: String
    @State private var showingActionSheet = false
    @State private var isPresentingFullScreenView = false
    @State private var unzippedContentURL: URL? = nil
    @State private var webViewSnapshotter: WebViewSnapshotter?
//    @State private var saveAnimation: SaveAnimation? // Added for SaveAnimation
    @State private var showAlert = false
    @State private var remarkBools: [Bool] = [false, false, false, false, false]
    @State private var alertMessage = "Currently, importing p5.sound makes the infinite loading problem.(<script src=\"https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.1.9/addons/p5.sound.min.js\"></script>)"
    
    let remarks = ["Size Adaptive","A/V","Mouse","Keyboard","Capturing"]
    let remarkIcons = ["arrow.up.left.and.arrow.down.right","exclamationmark.triangle","exclamationmark.triangle","exclamationmark.triangle","exclamationmark.triangle"]
    let remarkColors = [Color.green,Color.red,Color.red,Color.red,Color.red]
    private var unsupportedMarkShow: Bool {
        remarkBools.dropFirst().contains(true)
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                // Top-aligned content
                HStack(spacing: 0) { // Reduce or remove spacing if needed
                    Text(author)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 1) // Reduce padding or remove it completely
                    
                    Image(systemName: "arrow.up.forward.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 14)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    ForEach(Array(zip(remarks.indices, remarks)), id: \.0) { index, remark in
                        if remarkBools[index] {
                            Button(action: {
                                // Trigger the sheet to open
                                self.showAlert = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: remarkIcons[index])
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 10)
                                    Text(remark)
                                        .padding(.vertical, 8)
                                }
                                .padding(.horizontal, 4)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(remarkColors[index])
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .sheet(isPresented: $showAlert) {
                    // Custom view for detailed content
                    CustomDetailView()
                }

                
                if let unzippedURL = unzippedContentURL {
                    WebView(url: unzippedURL)
                        .frame(width: geometry.size.width * 0.95, height: geometry.size.width * 0.95)
                    //todo: want this frame to be controlled in settings.
//                        .border(Color.gray, width: 1)
                } else {
                    Text("Loading...")
                        .onAppear {
                            unzipContent(sourceURL: sourceURL) { unzippedURL,tagResults in
                                self.unzippedContentURL = unzippedURL
                                self.remarkBools = tagResults
                            }
                        }
                }
                
                Spacer() // Pushes the following content to the bottom
                
                // Bottom-aligned buttons
                HStack {
                    Button("Full Screen") {
                        self.isPresentingFullScreenView = true
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(12)
                    .fullScreenCover(isPresented: $isPresentingFullScreenView) {
                        if let unzippedURL = unzippedContentURL {
                            FullScreenWebView(sourceURL: unzippedURL)
                        } else {
                            Text("Unzipping Failed")
                        }
                    }
                    
                    Button(action: {
                        self.showingActionSheet = true
                    }) {
                        Text("Save")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.blue)
                            .padding(12)
                    }
                    .actionSheet(isPresented: $showingActionSheet) {
                        ActionSheet(title: Text("Choose an option"), message: nil, buttons: [
                            .default(Text("Save Image")) {
                                saveImageAction()
                            },
                            .default(Text("Save Live Photo")) {
                                startAnimationCaptureAction()
                            },
                            .default(Text("Save to My Collection")) {
                                // CollectionHandler(fileURL: sourceURL)
                            },
                            .cancel()
                        ])
                    }
                    
//                    Button("More Info") {
//                        self.showAlert = true
//                    }
//                    .foregroundColor(.gray)
//                    .padding(3)
//                    .alert(isPresented: $showAlert) {
//                        Alert(
//                            title: Text("Problems to be fixed:"),
//                            message: Text(alertMessage),
//                            dismissButton: .default(Text("OK"))
//                        )
//                    }
                }
            }
            .navigationBarTitle(Text(title), displayMode: .inline)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    
    func saveImageAction() {
        if let unzippedURL = unzippedContentURL {
            webViewSnapshotter = WebViewSnapshotter(url: unzippedURL) { image in
                if let image = image {
                    print("4. Image is valid from the URL below: ")
                    print(unzippedURL)
                    ImageSaver.shared.saveImage(image)
                    self.webViewSnapshotter = nil // Clear the reference once done
                } else {
                    print("4. Failed to take snapshot")
                }
            }
        }
    }
    
    func startAnimationCaptureAction() {
        // Your animation capture logic here
    }
    
    
}
