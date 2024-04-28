import SwiftUI
import WebKit
import UIKit
import Combine
import ZIPFoundation
import Firebase
import FirebaseFirestore


class ViewModel: ObservableObject {//This is an updater of isPublished
    @Published var isPublished = false
    @Published var isLoading = false
    @Published var likesNumber: Int = 0
    private var p5id: String
    
    init(p5id: String) {
        self.p5id = p5id
        print("[ViewModel][init]: Initialized with p5id: \(p5id)")
    }
    
    func checkPublishStatusAndLikes() async {
        print("[ViewModel][checkPublishStatusAndLikes]: Checking publish status and likes started for p5id: \(p5id).")
        
        DispatchQueue.main.async {
            self.isLoading = true
            print("[ViewModel][checkPublishStatusAndLikes]: isLoading set to true.")
        }
        
        if let item = await fetchSketchAsync(byFieldName: "p5id", fieldValue: p5id) {
            DispatchQueue.main.async {
                self.isPublished = true
                self.likesNumber = item.likes
                self.isLoading = false
                print("[ViewModel][checkPublishStatusAndLikes]: Fetch successful. Publish status set to true, likes updated to \(item.likes), isLoading set to false.")
            }
        } else {
            DispatchQueue.main.async {
                self.isPublished = false
                self.isLoading = false
                print("[ViewModel][checkPublishStatusAndLikes]: Fetch failed. No item found for p5id: \(self.p5id). Publish status set to false, isLoading set to false.")
            }
        }
    }
    
    func publishAction(title: String, author: String, unzippedContentURL: URL?, p5id: String, createdAt: Date) {
        
        print("\(green)[WebContentView][publishAction]\(green)")
        guard let unzippedURL = unzippedContentURL else {
            print("[WebContentView][publishAction]:Invalid URL provided.")
            return
        }
        // Publish: (!) Check if already exist in firebase -> generate preview -> fulfill thisItem -> upload preview with storage -> addDocument(thisItem)
        // 0. Check if this is already published:
        if !self.isPublished{
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
                    p5id: p5id,
                    title: title,
                    author: author,
                    createdAt: createdAt,
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
        self.isPublished = true
        //        self.key = UUID() // Refresh!
        //        print("\(yellow)[WebContentView][publishAction]\(yellow)")
    }
    
    
}
