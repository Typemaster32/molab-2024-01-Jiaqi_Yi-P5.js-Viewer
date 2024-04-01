import SwiftUI
import WebKit
import UIKit
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
    @State private var key: UUID = UUID() // Used to refresh the WebView
    @State private var showAlert = false
    @State private var remarkBools: [Bool] = [false, false, false, false, false]
    @State private var alertMessage = "Currently, importing p5.sound makes the infinite loading problem.(<script src=\"https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.1.9/addons/p5.sound.min.js\"></script>)"
    @State private var isLoading = false // set it true to call loadingView(), false to stop
    
    let remarks = ["Size Adaptive","A/V","Mouse","Keyboard","Capturing"]
    let remarkIcons = ["arrow.up.left.and.arrow.down.right","exclamationmark.triangle","exclamationmark.triangle","exclamationmark.triangle","exclamationmark.triangle"]
    let remarkColors = [Color.green,Color.red,Color.red,Color.red,Color.red]
    private var unsupportedMarkShow: Bool {
        remarkBools.dropFirst().contains(true)
    }// not used;
    
    let myCanvasSize:(Int,Int)=(1000,1000)
    let desiredWidth:Int=Int((UIScreen.main.bounds.width*0.95).rounded())
    var myViewportSize: (Int, Int) {
        (desiredWidth, desiredWidth)
    }// not used;
    
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                // Top-aligned content
                HStack(spacing: 3) { // Reduce or remove spacing if needed
                    Text(author)
                        .font(.system(size: 15, weight: .regular))
                    //                        .foregroundColor(.gray)
                        .padding(.horizontal, 1) // Reduce padding or remove it completely
                    
                    Image(systemName: "arrow.up.forward.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 14)
                    //                        .foregroundColor(.gray)
                }.padding(.bottom,7)
                
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
                
                
                if !isPresentingFullScreenView{
                    if let unzippedURL = unzippedContentURL {
                        WebView(url: unzippedURL).id(key)
                            .frame(width: CGFloat(desiredWidth), height: CGFloat(desiredWidth)*1.33)
                    } else {
                        ProgressView()
                            .onAppear {
                                unzipContent(sourceURL: sourceURL) { unzippedURL,tagResults in
                                    self.unzippedContentURL = unzippedURL
                                    self.remarkBools = tagResults
                                }
                            }
                    }
                }
                
                Spacer() // Pushes the following content to the bottom
                
                

                
                
                // Bottom-aligned buttons
                HStack {
                    Button("Refresh") {
                        self.key = UUID() // Change the key to force the WebView to reload
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(15)
                    
                    Button("Full Screen") {
                        self.isPresentingFullScreenView = true
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(15)
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
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.blue)
                            .padding(15)
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
                                if let unzippedURL = unzippedContentURL {
                                    CollectionManager.shared.collect(title: self.title, author: self.author, originalHtmlURL: unzippedURL)
                                }
                            },
                            .cancel()
                        ])
                    }
                }
            }
            .navigationBarTitle(Text(title), displayMode: .inline)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if isLoading {
                LoadingView()
            }
        }
    }
    
    
    func saveImageAction() {
        if let unzippedURL = unzippedContentURL {
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            
            // Correct instantiation with trailing closure and additional parameters
            webViewSnapshotter = WebViewSnapshotter(url: unzippedURL, width: Int(screenWidth), height: Int(screenHeight)) { image in
                if let image = image {
                    print("--- WebContentView -> saveImageAction -> 4. Image is valid from the URL below: \(unzippedURL)")
                    ImageSaver.shared.saveImage(image)
                    self.webViewSnapshotter = nil // Clear the reference once done
                } else {
                    print("--- WebContentView -> saveImageAction -> 4. Failed to take snapshot")
                }
            }
        }

    }
    
    func startAnimationCaptureAction() {
        isLoading = true
        
    }
    
}
