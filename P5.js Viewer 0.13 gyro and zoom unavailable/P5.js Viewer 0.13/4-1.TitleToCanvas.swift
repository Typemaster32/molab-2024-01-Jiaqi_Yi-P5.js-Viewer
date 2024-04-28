//
//  4-1.TitleToCanvas.swift
//  P5.js Viewer 0.13
//
//  Created by Jiaqi Yi on 4/15/24.
//

import SwiftUI

struct TitleToCanvas: View {
    var p5id:String
    var author:String
    var title:String
    var createdAt:Date
    let remarks = ["Size Adaptive","A/V","Mouse","Keyboard","Capturing"]
    let remarkIcons = ["arrow.up.left.and.arrow.down.right","exclamationmark.triangle","exclamationmark.triangle","exclamationmark.triangle","exclamationmark.triangle"]
    let remarkColors = [Color.green,Color.red,Color.red,Color.red,Color.red]
    @State var remarkBools: [Bool] = [false, false, false, false, false]
    var sourceLocalURL: URL
    let desiredWidth:Int=Int((UIScreen.main.bounds.width*0.95).rounded())
    
    
    @StateObject private var likesManager = LikesManager()
    var didIPressedLike:Bool{
        return likesManager.doesIDExist(p5id)
    }
    
    
    @State private var showAlert = false
    @State private var isPresentingFullScreenView = false
    @State private var unzippedContentURL: URL? = nil
    @State private var key: UUID = UUID() // Used to refresh the WebView
    @StateObject private var viewModel: ViewModel
    @State private var showingActionSheet = false // For "Save"
    @State private var showingActionSheet2 = false // For "Actions"
    @State private var webViewSnapshotter: WebViewSnapshotter?
    var body: some View {
        VStack {
            HStack(spacing: 3) { // Title + author
                Text(author)
                    .font(.system(size: 15, weight: .regular))
                    .padding(.horizontal, 1)
                
                Image(systemName: "arrow.up.forward.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 14)
            }.padding(.bottom,7)
            
            HStack { //Symbols
                ForEach(Array(zip(remarks.indices, remarks)), id: \.0) { index, remark in
                    if remarkBools[index] {
                        Button(action: { // Trigger the sheet to open
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
                        viewModel.publishAction(p5id: p5id, title: title, author: author, unzippedContentURL: unzippedContentURL)
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
}

