import SwiftUI
import WebKit
import UIKit
import Combine
import ZIPFoundation
import Firebase
import FirebaseFirestore
import Photos
let screenWidth = UIScreen.main.bounds.width
let screenHeight = UIScreen.main.bounds.height


struct WebContentView: View {
    /*
     Different URLs:
     +----------------------+------------+-----------+
     | Name                 | Kind       | Usage     |
     +----------------------+------------+-----------+
     | sourceLocalURL       | "zip"      | to unzip  |
     | originOnlineURL      | online     | web editor|
     | unzippedURL          | index.html | webview   |
     | unzippedContentURL   | index.html | buttons   |
     | unzippedContentURL   | index.html | buttons   |
     +----------------------+------------+-----------+
     */

    @EnvironmentObject var viewModelSearch: SearchViewModel

    
    @StateObject private var likesManager = LikesManager()
    @StateObject private var viewModelFirebase: ViewModelOfFirebaseStatus
    @StateObject private var viewModelAnimation: ViewModelOfAnimation
    @StateObject private var webViewStore = WebViewStore()
    
    
    
    var sourceLocalURL: URL //This is an local URL
    var originOnlineURL: URL? = nil //This is the p5.js web editor URL
    var title: String
    var author: String
    var fbid: String = "Unknown" //fbid is not necessary
    var p5id: String = "Unknown"
    var isFromExamples: Bool {
        return p5id != "Unknown"
    }
    var didIPressedLike:Bool{
        return likesManager.doesIDExist(p5id)
    }
    var createdAt: Date
    var updatedAt: String = "Unknown" // Be careful: Due to mutable function not usable in buttons, you'll have to get this from firebase.
    var alertMessageSound = "Currently, importing p5.sound makes the infinite loading problem.(<script src=\"https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.1.9/addons/p5.sound.min.js\"></script>)"
    var alertMessageSavingError = "The Live Photo saving has failed."
    
    init(sourceLocalURL: URL, originOnlineURL: URL? = nil, title: String, author: String, fbid: String = "Unknown", p5id: String = "Unknown", createdAt: Date, updatedAt: String = "Unknown") {
        self.sourceLocalURL = sourceLocalURL
        self.originOnlineURL = originOnlineURL
        self.title = title
        self.author = author
        self.fbid = fbid
        self.p5id = p5id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        _viewModelFirebase = StateObject(wrappedValue: ViewModelOfFirebaseStatus(p5id: p5id)) // Initialize the ViewModel with p5id
        _viewModelAnimation = StateObject(wrappedValue: ViewModelOfAnimation(sketchTitle: title, author: author))
        print("-------------------------WebContentView-------------------------")
    }
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
    
    @State private var showingActionSheet = false // For "Save"
    @State private var showingActionSheet2 = false // For "Actions"
    @State private var isPresentingFullScreenView = false
    @State private var unzippedContentURL: URL? = nil
    @State private var webViewSnapshotter: WebViewSnapshotter?
    @State private var key: UUID = UUID() // Used to refresh the WebView
    @State private var showAlert = false
    @State private var remarkBools: [Bool] = [false, false, false, false, false]
    @State private var isLoading = false // set it true to call loadingView(), false to stop
    @State private var buttonText = "Like/Publish" // This is controlling the button to show "Like" or "Publish"
    @State private var webView: WKWebView?
    @State private var progress = 0.0
    
    
    let remarks = ["Size Adaptive","A/V","Mouse","Keyboard","Capturing"]
    let remarkIcons = ["arrow.up.left.and.arrow.down.right","exclamationmark.triangle","exclamationmark.triangle","exclamationmark.triangle","exclamationmark.triangle"]
    let remarkColors = [Color.green,Color.red,Color.red,Color.red,Color.red]
    private var isPublishing = false // This prevents publishAction to run overlappedly.
    private var unsupportedMarkShow: Bool {
        remarkBools.dropFirst().contains(true)
    }// not used;
    
    let myCanvasSize:(Int,Int)=(1000,1000)
    let desiredWidth:Int=Int((UIScreen.main.bounds.width*0.95).rounded())
    var myViewportSize: (Int, Int) {
        (desiredWidth, desiredWidth)
    }// not used;
    
    var body: some View {
        /*
         In the View we have:
         +-------------+--------------+-----------+
         | Object      | Action       | Others    |
         +-------------+--------------+-----------+
         | Title       | N            | -         |
         | Author      | Y            | -         |
         +-------------+--------------+-----------+
         | Canvas      | Y            | -         |
         +-------------+--------------+-----------+
         | Buttons     | Y            | -         |
         +-------------+--------------+-----------+
         */
            GeometryReader { geometry in
                VStack {
                    if viewModelFirebase.isLoading {
                        // Show a progress indicator if the ViewModel is currently loading
                        ProgressView(value: progress, total: 100)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(height: 8)
                            .onAppear {
                                withAnimation(.linear(duration: 7)) {
                                    self.progress = 100
                                }
                            }
                    } else {// Otherwise, show the rest of your UI
                        VStack {
                            AuthorView(author: author)
                            HStack { //Symbols
                                ForEach(Array(zip(remarks.indices, remarks)), id: \.0) { index, remark in
                                    if remarkBools[index] {
                                        Button(action: { // Trigger the sheet to open
                                            self.showAlert = true
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: remarkIcons[index]).resizable().aspectRatio(contentMode: .fit).frame(height: 10)
                                                Text(remark).padding(.vertical, 8)
                                            }.padding(.horizontal, 4).font(.system(size: 12, weight: .semibold)).foregroundColor(remarkColors[index])
                                        }.buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .sheet(isPresented: $showAlert) {
                                CustomDetailView()
                            }
                            /*
                             This is the conditions of showing different webView:
                                Init -> unzip -> unzippedURL -> webView ().
                                Button -> ViewModel... -> ViewModel.bool ->change webView
                             */
                            Spacer()
                            if !isPresentingFullScreenView{
                                if !viewModelAnimation.shouldShowWebView,let unzippedURL = unzippedContentURL {
//                                    WebView(url: unzippedURL,store: webViewStore).id(key).frame(width: CGFloat(desiredWidth), height: CGFloat(desiredWidth)*1.33)
                                    WebView(url: unzippedURL,store: webViewStore).id(key).frame(/*width: geometry.size.width, */maxHeight: .infinity)/*.border(Color.red, width: 2)*/
                                        
                                } else {
                                    ProgressView(value: progress, total: 100)
                                        .progressViewStyle(LinearProgressViewStyle())
                                        .frame(height: 8)
                                        .onAppear {
                                            withAnimation(.linear(duration: 7)) {
                                                self.progress = 100
                                            }
                                            unzipContent(sourceURL: sourceLocalURL) { unzippedURL,tagResults in
                                                self.unzippedContentURL = unzippedURL
                                                self.remarkBools = tagResults
                                            }
                                        }
                                }
                            }
                            
                            Spacer()
//                            Spacer() // Pushes the following content to the bottom
                            /*
                             BUTTONS:
                             +---------+----------------+---------------------------+
                             | Name    | Also           | Integrated?               |
                             +---------+----------------+---------------------------+
                             | Publish | Publish        | publishAction()           |
                             |         | Like           | Y                         |
                             |         | Unlike         | Y                         |
                             +---------+----------------+---------------------------+
                             | Actions | Open in Editor | TBD                       |
                             |         | Full Screen    | Y                         |
                             |         | Refresh        | Y                         |
                             +---------+----------------+---------------------------+
                             | Save    | Image          | saveImageAction()         |
                             |         | Animation      | saveAnimationAction()     |
                             |         | Collection     | Y                         |
                             +---------+----------------+---------------------------+
                             */
                            
                            
                            HStack {// Publish if it is not published; Like if it is published;
                                Button(action: {
                                    if !viewModelFirebase.isPublished {
                                        publishAction(title: title, author: author, unzippedContentURL: unzippedContentURL)
                                    } else {
                                        
                                        if didIPressedLike {// Unlike
                                            UnlikeAction(likesManager: likesManager, p5id: p5id, viewModel: viewModelFirebase)
                                        } else {// Like
                                            self.triggerHapticFeedback()
                                            LikeAction(likesManager: likesManager, p5id: p5id, viewModel: viewModelFirebase)
                                        }
                                    }
                                }) {
                                    HStack(spacing: 2) {  // Use minimal spacing between the icon and text
                                        if !viewModelFirebase.isPublished {
                                            Image(systemName: "arrow.up.to.line").resizable().scaledToFit().frame(height: 15).padding(.horizontal, 1)  // Adjust height to match the text size approximately
                                            Text("Publish")
                                        } else {
                                            if didIPressedLike {  // "Like" state
                                                Image(systemName: "heart").resizable().scaledToFit().frame(height: 15).padding(.horizontal, 1)  // Adjust height to match the text size approximately
                                                Text("Like \(viewModelFirebase.likesNumber)")
                                            } else {  // "Liked" state
                                                Image(systemName: "heart.fill").resizable().scaledToFit().frame(height: 15).padding(.horizontal, 1)  // Adjust height to match the text size approximately
                                                Text("Liked! \(viewModelFirebase.likesNumber)")
                                            }
                                        }
                                    }
                                    .font(.system(size: 14, weight: .bold))  // Apply font settings to all text within the HStack
                                    .foregroundColor(viewModelFirebase.isPublished ? .blue : .green)
                                    .padding(15)
                                }

                                
                                
                                
                                Button(action: {
                                    self.showingActionSheet2 = true
                                }) {
                                    HStack {
                                        Image(systemName: "ellipsis")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 16) // Adjust the icon size to match the text
                                        Text("Actions")
                                    }
                                    .font(.system(size: 14, weight: .bold)) // Apply the font to both the image and text
                                    .foregroundColor(.blue)
                                    .padding(15)
                                }
                                .actionSheet(isPresented: $showingActionSheet2) {
                                    ActionSheet(title: Text("Action"), buttons: [
                                        .default(Text("Refresh")) {self.key = UUID()}, // Change the key to force the WebView to reload
                                        .default(Text("Full Screen")) {self.isPresentingFullScreenView = true},
                                        .default(Text("Open in Editor")) {
                                            if let url = URL(string: "https://editor.p5js.org/\(author)/sketches/\(p5id)"), UIApplication.shared.canOpenURL(url) {
                                                UIApplication.shared.open(url)
                                            }
                                        },
                                        .cancel()
                                    ])
                                }
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
                                    
                                    HStack {
                                        Image(systemName: "arrow.down.to.line")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 16) // Adjust the icon size to match the text
                                        Text("Save")
                                    }
                                    .font(.system(size: 14, weight: .bold)) // Apply the font to both the image and text
                                    .foregroundColor(.blue)
                                    .padding(15)
                                }
                                .actionSheet(isPresented: $showingActionSheet) {
                                    ActionSheet(title: Text("Choose an option"), message: nil, buttons: [
                                        .default(Text("Save Image")) {
                                            saveImageActionNew()
                                        },
//                                        .default(Text("Save Live Photo")) {
//                                            saveAnimationLocalAction()
//                                        },
                                        .default(Text("Save to My Collection")) {
                                            if let unzippedURL = unzippedContentURL {
                                                CollectionManager.shared.collect(title: self.title, author: self.author, originalHtmlURL: unzippedURL,p5id: self.p5id,createdAt:self.createdAt)
                                            }
                                        },
                                        .cancel()
                                    ])
                                }
                            }
                        }
                    }
                }
                .navigationBarTitle(Text(title), displayMode: .inline)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onAppear {
                Task {
                    await viewModelFirebase.checkPublishStatusAndLikes()
                }
            }
        /*
         .alert("Welcome", isPresented: $isShowingUser, presenting: selectedUser) { user in
         Button(user.id) { }
         https://www.hackingwithswift.com/books/ios-swiftui/using-alert-and-sheet-with-optionals
         }
         */
    }
    /*
     This is everything related to save an image as photo / thumbnail / preview:
     +-------------------+----------------------+-------------------------------------------+
     | Name              | Has                  | Role                                      |
     +-------------------+----------------------+-------------------------------------------+
     | WebViewSnapshotter| init                 | opens index.html                          |
     |                   | webView (didFinish)  | delay 1s to ensure loading                |
     |                   | takeSnapshot         | take the snapshot as image data           |
     +-------------------+----------------------+-------------------------------------------+
     | ImageSaver        | saveImage            | save the image                            |
     |                   | @objc private func   | handle errors                             |
     |                   | image                |                                           |
     +-------------------+----------------------+-------------------------------------------+
     | UIImage           | resized              | resize the image                          |
     +-------------------+----------------------+-------------------------------------------+
     | CollectionManager | collect              | wrapped up, including saving thumbnails   |
     |                   |                      | save the preview locally                  |
     +-------------------+----------------------+-------------------------------------------+
     
     Save Image:
     WCV -> WVSS -> ImageSaver
     
     Collect (Save Thumbnail):
     WCV -> CM.collect {get paths -> copying -> WVSS -> ImageSaver}
     
     Publish (Save Preview):
     WCV -> CM.getPreviewImage -> ImageSaver -> uploadImageToFirebaseStorage -> ...
     */
    
    func saveImageActionNew() {
        print("\(green)[WebContentView][saveImageAction][New]\(green)")

            captureCanvas()
    }

    func publishAction(title: String, author: String, unzippedContentURL: URL?) {
        
        print("\(green)[WebContentView][publishAction]\(green)")
        guard let unzippedURL = unzippedContentURL else {
            print("[WebContentView][publishAction]:Invalid URL provided.")
            return
        }
        // Publish: (!) Check if already exist in firebase -> generate preview -> fulfill thisItem -> upload preview with storage -> addDocument(thisItem)
        // 0. Check if this is already published:
        if !viewModelFirebase.isPublished{
            // 1. Making the preview in a temp folder, named "author - title" to identify.
            
            CollectionManager.shared.getPreviewImage(originalHtmlURL: unzippedURL, title: title, author: author) { (savedImageURL) in
                guard let savedImageURL = savedImageURL else {
                    print("\(red)[WebContentView][publishAction]:Failed to save the preview image.")
                    return
                }
                uploadImageToFirebaseStorage(imageURL: savedImageURL)
                // savedImageURL is given a value internally by the getPreviewImage method.
                // If the image was saved successfully, proceed to upload it to Firebase Storage
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                let now = Date()
                let dateString = dateFormatter.string(from: now)
                // 2. Complete an Item here
                let thisItem = Item(
                    id: "",//this is fbid
                    p5id: self.p5id,
                    title: self.title,
                    author: self.author,
                    createdAt: self.createdAt,
                    updatedAt: dateString,
                    previewName: savedImageURL.lastPathComponent // this URL is talking about firebase
                )
                
                // 3. upload this into firebase
                addDocument(thisItem) { updatedItem in
                    if let updatedItem = updatedItem {
                        // Handle success - the item was added and we have the updated item with the Firestore-generated ID
                        print("[WebContentView][publishAction][addDocument]:Successfully added item with ID: \(updatedItem.id)")
                    } else {
                        // Handle failure - there was an error adding the item to Firestore
                        print("\(red)[WebContentView][publishAction][addDocument]:Failed to add the item.")
                    }
                }
                
            }
            
        } else{print("This Sketch is already Published")}
        viewModelFirebase.isPublished = true
        //        print("\(yellow)[WebContentView][publishAction]\(yellow)")
    }
    
    
    private func captureCanvas() {
        print("[WebContentView][captureCanvas]")
        guard let webView = webViewStore.webView else {
            print("[WebContentView][captureCanvas]:returned 1")
            return }
        webViewStore.coordinator?.captureCanvasImage(webView: webView) { image in
            guard let image = image else {
                print("[WebContentView][captureCanvas]:returned 2")
                return
            }
            saveImage(image)
        }
    }
    
    private func saveImage(_ image: UIImage) {
        ImageSaver.shared.saveImage(image, compress: false) { success, error in
            if success {
                print("Image saved successfully.")
            } else if let error = error {
                print("Error saving image: \(error.localizedDescription)")
            }
        }
    }
    
    func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()  // Prepare the generator to reduce latency
        generator.impactOccurred()  // Trigger the haptic feedback
    }
    
}


