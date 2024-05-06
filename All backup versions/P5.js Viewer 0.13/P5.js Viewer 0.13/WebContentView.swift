import SwiftUI
import WebKit
import UIKit
import ZIPFoundation

struct WebContentView: View {
    var sourceURL: URL
    var title: String
    var author: String
    //    @StateObject var motionManager = MotionManager()
    //    @State var tracking = false //added for gyroscope
    @State private var showingActionSheet = false
    @State private var isPresentingFullScreenView = false
    @State private var unzippedContentURL: URL? = nil
    @State private var webViewSnapshotter: WebViewSnapshotter?
    //    @State private var saveAnimation: SaveAnimation? // Added for SaveAnimation
    //    @State private var showZoomSlider: Bool = false
    //    @State private var zoomLevel: CGFloat = 1.0 // Default zoom level
    @State private var key: UUID = UUID() // Used to refresh the WebView
    @State private var showAlert = false
    @State private var remarkBools: [Bool] = [false, false, false, false, false]
    @State private var alertMessage = "Currently, importing p5.sound makes the infinite loading problem.(<script src=\"https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.1.9/addons/p5.sound.min.js\"></script>)"
    
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
                
                
                //                if showZoomSlider {
                //                    Slider(value: $zoomLevel, in: 0.5...3.0, step: 0.1)
                //                        .padding()
                //                }
                //                Button(showZoomSlider ? "Hide Zoom" : "Show Zoom") {
                //                    showZoomSlider.toggle()
                //                }
                //                .padding()
                
                
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
                                saveToMyCollectionAction()
                            },
                            .cancel()
                        ])
                    }
                }
                
                //                ZStack {
                //                    Color.white
                //                        .edgesIgnoringSafeArea(.all)
                //                        .onTapGesture(perform: {
                //                            // Update mouse position to tap location
                //                        })
                //
                //                    Circle()
                //                        .frame(width: 20, height: 20)
                //                        .position(x: motionManager.mouseX, y: motionManager.mouseY)
                //                        .foregroundColor(.blue)
                //
                //                    Button(action: {
                //                        self.tracking.toggle()
                //                        if self.tracking {
                //                            self.motionManager.startUpdates()
                //                        } else {
                //                            self.motionManager.stopUpdates()
                //                        }
                //                    }) {
                //                        Text(tracking ? "Stop Tracking" : "Start Tracking")
                //                    }
                //                    .position(x: UIScreen.main.bounds.width / 2, y: 50)
                //                }
                //                .gesture(
                //                    DragGesture().onChanged({ value in
                //                        self.motionManager.mouseX = value.location.x
                //                        self.motionManager.mouseY = value.location.y
                //                    })
                //                )
                // It causes the page to blink
                
            }
            .navigationBarTitle(Text(title), displayMode: .inline)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    
    func saveImageAction() {
        print("---saveImageAction---")
        if let unzippedURL = unzippedContentURL {
            webViewSnapshotter = WebViewSnapshotter(url: unzippedURL) { (image, success) in
                guard let image = image, success else {
                    print("Failed to capture snapshot or image is nil.")
                    return
                }
                
                // Save the original image to the photo album
                ImageSaver.shared.saveImage(image) { success in
                    if success {
                        print("Original image saved to photo album successfully.")
                    } else {
                        print("Failed to save original image to photo album.")
                    }
                }
            }
        }
    }

    
    func startAnimationCaptureAction() {
        // Your animation capture logic here
    }
    
    func saveToMyCollectionAction() {
        print("---saveToMyCollectionAction---")
        if let unzippedURL = unzippedContentURL {
            // First, add the element to the collection
            let handler = CollectionHandler(fileURL: unzippedURL)
            handler.addElement(title: self.title, author: self.author)
            
            // Define where to save the thumbnail
            if let destinationURL = handler.destinationFileURL {
                let thumbnailURL = destinationURL.appendingPathComponent("thumbnail.jpg") // or .png as needed
                
                // Initialize WebViewSnapshotter to capture the web content and save a thumbnail
                _ = WebViewSnapshotter(url: unzippedURL, saveToURL: thumbnailURL) { (image, success) in
                    guard let _ = image, success else {
                        print("Failed to capture snapshot or image is nil.")
                        return
                    }
                    // Thumbnail image has been saved to the collection directory
                    print("Thumbnail image saved to URL successfully at: \(thumbnailURL)")
                }
            }
        }
    }
    
    
}
