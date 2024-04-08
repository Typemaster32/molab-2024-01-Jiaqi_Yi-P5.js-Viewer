import SwiftUI
import WebKit
import UIKit
import ZIPFoundation
import FirebaseFirestore

let defaultThumbnailURLString = "https://www.example.com/default-thumbnail.jpg"
let defaultSketchURLString = "https://www.example.com/default-sketch.jpg"

// Convert placeholder URL strings to URL objects
let defaultThumbnailURL = URL(string: defaultThumbnailURLString)!
let defaultSketchURL = URL(string: defaultSketchURLString)!

let screenWidth = UIScreen.main.bounds.width
let screenHeight = UIScreen.main.bounds.height
// ATTENTION: consider id(p5)s and id(fb)s:
// Examples does not have any id;
// SearchViews & Collections only have p5id, should consider "checking the URL in fb, and get the fbid";
// ScrollingViews should have both;
struct WebContentView: View {
    var sourceLocalURL: URL //This is an local URL
    var originOnlineURL: URL? = nil //This is the p5.js web editor URL
    var title: String
    var author: String
    var fbid: String = "Unknown"//fbid is not necessary
    var p5id: String = "Unknown"
    var isFromExamples: Bool {
        return p5id != "Unknown"
    }
    var isPublished: Bool {
        var isPublishedTemporaryVersion = true
        fetchSketch(byFieldName: "p5id", fieldValue: p5id) { item in
            if let item = item {
                print("This sketch is already published: \(p5id)")
            } else {
                isPublishedTemporaryVersion = false
            }
        }
        return isPublishedTemporaryVersion
    }
    var didIPressedLiked:Bool{
        return false
    }
    var likesNumber:Int = 0;
    //
    /*
     Considering the work to be done, Let me set a rule here: if opening from scrolling, then give it a fbid; if opening from searching and collection, then give it a p5id.
     One more thing: we have to make a local list of those sketched already liked by the user.
     Types of WebContentView Calling:
     +-------------+--------------+-----------+
     | Kind        | fbid         | p5id      |
     +-------------+--------------+-----------+
     | Example     | no           | no        |
     | Collection  | yes/no       | yes       | (to be done)
     | Search      | yes/no       | yes       |
     | Scrolling   | yes          | yes       |
     +-------------+--------------+-----------+
     */
    var createdAt: String = "Unknown"
    var updatedAt: String = "Unknown"
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
    @State private var buttonText = "Like/Publish" // This is controlling the button to show "Like" or "Publish"
    
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
                            .onAppear {// upon appeared, this completion handler is executed and save the URL into the "unzippedContentURL"
                                       // "if let unzippedURL = unzippedContentURL" is to ensure that it's indeed unzipped, here unzippedURL can be anything.
                                       // and below "unzippedURL" is used only once here.
                                unzipContent(sourceURL: sourceLocalURL) { unzippedURL,tagResults in
                                    self.unzippedContentURL = unzippedURL
                                    self.remarkBools = tagResults
                                }
                            }
                    }
                }
                
                Spacer() // Pushes the following content to the bottom
                HStack {
                    // Publish if it is not published;
                    // Like if it is published;
                    Button(buttonText) {
                        if !isPublished{
                            publishAction(title: title, author: author, unzippedContentURL: unzippedContentURL)
                        }else{likeAction()}
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(15)
                    .onAppear{
                        buttonText = isPublished ? "Like" : "Publish"
                    }
                    

                    
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
    
    
    func publishAction(title: String, author: String, unzippedContentURL: URL?) {
        guard let unzippedURL = unzippedContentURL else {
            print("Invalid URL provided.")
            return
        }
        // Publish: generate preview -> fulfill thisItem -> upload preview with storage -> addDocument(thisItem)
        // 1. Making the preview in a temp folder, named "author - title" to identify.
        CollectionManager.shared.getPreviewImage(originalHtmlURL: unzippedURL, title: title, author: author) { (savedImageURL) in
            guard let savedImageURL = savedImageURL else {
                print("Failed to save the preview image.")
                return
            }
            // savedImageURL is given a value internally by the getPreviewImage method.
            // If the image was saved successfully, proceed to upload it to Firebase Storage
            uploadImageToFirebaseStorage(imageURL: savedImageURL)
            
            var sketchURLString:String
            // 2. Completing the Item
            if p5id==""{sketchURLString = "https://editor.p5js.org/editor/projects/\(self.p5id)/zip"} else {
                print("[MakingItem]: p5id is missing!")
                sketchURLString = "www.google.com"
            }
            
            var thisItem = Item(
                id: "",//this is fbid
                p5id: self.p5id,
                title: self.title,
                author: self.author,
                createdAt: self.createdAt,
                updatedAt: self.updatedAt,
                previewURL: savedImageURL, // this URL is in firebase
                sketchURL: sketchURLString //ensure it's an URL later.
            )
            
            addDocument(thisItem, completion: <#T##(Item?) -> Void#>)
            // 3. upload this into firebase
        }
        
    }
    
    
    func likeAction(){
        // Like: get the id of this WebContentView -> find it with id -> update with new value of Like
        // if it is already published, it should have an fbid. This is IMPORTANT, that it is passed through WebContentView.
        
    }
}


// Function to fetch an element from the "sketches" collection based on field name and value
func fetchSketch(byFieldName fieldName: String, fieldValue: String, completion: @escaping (Item?) -> Void) {
    // Reference to Firestore and the specific collection
    let db = Firestore.firestore()
    let collectionRef = db.collection("sketches")
    
    // Query the collection for documents where the specified field matches the given value
    collectionRef.whereField(fieldName, isEqualTo: fieldValue).getDocuments { (querySnapshot, error) in
        if let error = error {
            // If there's an error fetching the documents, print the error and call completion with nil
            print("Error fetching document: \(error)")
            completion(nil)
        } else {
            // Attempt to initialize an Item from the first document found
            if let document = querySnapshot?.documents.first, let item = Item(document: document) {
                // If successful, call completion with the item
                completion(item)
            } else {
                // If no document was found or the Item could not be initialized, call completion with nil
                completion(nil)
            }
        }
    }
}
