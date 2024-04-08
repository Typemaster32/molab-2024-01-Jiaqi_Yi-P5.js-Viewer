import SwiftUI
import WebKit
import UIKit
import Combine
import ZIPFoundation
import Firebase
import FirebaseFirestore
let screenWidth = UIScreen.main.bounds.width
let screenHeight = UIScreen.main.bounds.height


struct WebContentView: View {
    @StateObject private var likesManager = LikesManager()
    @StateObject private var viewModel: ViewModel
    var sourceLocalURL: URL //This is an local URL
    var originOnlineURL: URL? = nil //This is the p5.js web editor URL
    var title: String
    var author: String
    var fbid: String = "Unknown"//fbid is not necessary
    var p5id: String = "Unknown"
    var isFromExamples: Bool {
        return p5id != "Unknown"
    }
    var didIPressedLike:Bool{
        return likesManager.doesIDExist(p5id)
    }
    var createdAt: Date
    var updatedAt: String = "Unknown" // Be careful: Due to mutable function not usable in buttons, you'll have to get this from firebase.
    init(sourceLocalURL: URL, originOnlineURL: URL? = nil, title: String, author: String, fbid: String = "Unknown", p5id: String = "Unknown", createdAt: Date, updatedAt: String = "Unknown") {
        self.sourceLocalURL = sourceLocalURL
        self.originOnlineURL = originOnlineURL
        self.title = title
        self.author = author
        self.fbid = fbid
        self.p5id = p5id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        _viewModel = StateObject(wrappedValue: ViewModel(p5id: p5id)) // Initialize the ViewModel with p5id
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
    @State private var alertMessage = "Currently, importing p5.sound makes the infinite loading problem.(<script src=\"https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.1.9/addons/p5.sound.min.js\"></script>)"
    @State private var isLoading = false // set it true to call loadingView(), false to stop
                                         //    @State private var asyncData: SomeAsyncDataType?
    @State private var buttonText = "Like/Publish" // This is controlling the button to show "Like" or "Publish"
    
    private var isPublishing = false // This prevents publishAction to run overlappedly.
    
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
                if viewModel.isLoading {
                    // Show a progress indicator if the ViewModel is currently loading
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {// Otherwise, show the rest of your UI
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
                        
                        
                        HStack {
                            // Publish if it is not published;
                            // Like if it is published;
                            
                            Button(action: {
                                if !viewModel.isPublished {
                                    publishAction(title: title, author: author, unzippedContentURL: unzippedContentURL)
                                } else {
                                    // Like: get the id of this WebContentView -> find it with id -> update with new value of Like
                                    // if it is already published, it should have an fbid. This is IMPORTANT, that it is passed through WebContentView.
                                    if didIPressedLike {// Unlike
                                        print("---[Button][Unlike]---")
                                        likesManager.deleteID(p5id)
                                        fetchSketch(byFieldName: "p5id", fieldValue: p5id){ item in
                                            if let item = item {
                                                var updatedItem = item
                                                updatedItem.likes -= 1
                                                viewModel.likesNumber -= 1
                                                updateSketchInFirestore(item: updatedItem) { success in
                                                    if success {
                                                        print("[Button][Unlike]:The item was successfully updated in Firestore.")
                                                    } else {
                                                        print("[Button][Unlike]:Failed to update the item in Firestore.")
                                                    }
                                                }
                                            } else {
                                                print("[Button][Unlike]:Error finding the item")
                                            }
                                        }
                                    } else {// Like
                                        print("---[Button][Like]---")
                                        likesManager.addID(p5id)
                                        fetchSketch(byFieldName: "p5id", fieldValue: p5id){ item in
                                            if let item = item {
                                                var updatedItem = item
                                                updatedItem.likes += 1
                                                viewModel.likesNumber += 1
                                                updateSketchInFirestore(item: updatedItem) { success in
                                                    if success {
                                                        print("[Button][Like]:Succeeded. There're now  \(updatedItem.likes) likes")
                                                    } else {
                                                        print("\(red)[Button][Like]:Failed to update the item in Firestore.")
                                                    }
                                                }
                                            } else {
                                                print("\(red)[Button][Like]:Error finding the item")
                                            }
                                        }
                                    }
                                }

                            }) {
                                if !viewModel.isPublished {
                                    Text("Publish")
                                } else {
                                    // Use a combination of Text views to apply different styles
                                    Text("Like \(viewModel.likesNumber)")
                                }
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(viewModel.isPublished ? .blue : .green)
                            .padding(15)
                            
                            
                            
                            Button("Actions") {
                                self.showingActionSheet2 = true
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.blue)
                            .padding(15)
                            .actionSheet(isPresented: $showingActionSheet2) {
                                ActionSheet(title: Text("Action"), buttons: [
                                    .default(Text("Refresh")) {
                                        self.key = UUID() // Change the key to force the WebView to reload
                                    },
                                    .default(Text("Full Screen")) {
                                        self.isPresentingFullScreenView = true
                                    },
                                    .default(Text("Open in Editor")) {
                                        // Perform the Open in Editor action
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
                                        saveAnimationAction()
                                    },
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
                await viewModel.checkPublishStatusAndLikes()
            }
        }
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
    func saveImageAction() {
        print("\(green)[WebContentView][saveImageAction]\(green)")
        if let unzippedURL = unzippedContentURL {
            // Correct instantiation with trailing closure and additional parameters
            webViewSnapshotter = WebViewSnapshotter(url: unzippedURL, width: Int(screenWidth), height: Int(screenHeight)) { image in
                if let image = image {
                    print("[WebContentView][saveImageAction]: 4. Image is valid from the URL below: \(unzippedURL)")
                    ImageSaver.shared.saveImage(image, completion: { success, error in
                        DispatchQueue.main.async {
                            if success {
                                print("[WebContentView][saveImageAction]: Image saved successfully.")
                            } else {
                                print("\(red)[WebContentView][saveImageAction]: Failed to save image. Error: \(String(describing: error))")
                            }
                            self.webViewSnapshotter = nil // Clear the reference once done, whether success or failure
                        }
                    })
                } else {
                    print("[---] WebContentView -> saveImageAction -> 4. Failed to take snapshot")
                }
            }
        }
//        print("\(yellow)[WebContentView][saveImageAction]\(yellow)")
    }
    func saveAnimationAction() {
        //        isLoading = true
    }
    func publishAction(title: String, author: String, unzippedContentURL: URL?) {
        
        print("\(green)[WebContentView][publishAction]\(green)")
        guard let unzippedURL = unzippedContentURL else {
            print("[WebContentView][publishAction]:Invalid URL provided.")
            return
        }
        // Publish: (!) Check if already exist in firebase -> generate preview -> fulfill thisItem -> upload preview with storage -> addDocument(thisItem)
        // 0. Check if this is already published:
        if !viewModel.isPublished{
            // 1. Making the preview in a temp folder, named "author - title" to identify.
            
            CollectionManager.shared.getPreviewImage(originalHtmlURL: unzippedURL, title: title, author: author) { (savedImageURL) in
                guard let savedImageURL = savedImageURL else {
                    print("\(red)[WebContentView][publishAction]:Failed to save the preview image.")
                    return
                }
                uploadImageToFirebaseStorage(imageURL: savedImageURL) // I don't know why it seems like to be called twice.
//                previewName = savedImageURL
                // savedImageURL is given a value internally by the getPreviewImage method.
                // If the image was saved successfully, proceed to upload it to Firebase Storage
                
                // Get the time now
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                
                // Get the current date and format it as a string
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
        viewModel.isPublished = true
//        self.key = UUID() // Refresh!
//        print("\(yellow)[WebContentView][publishAction]\(yellow)")
    }
}


