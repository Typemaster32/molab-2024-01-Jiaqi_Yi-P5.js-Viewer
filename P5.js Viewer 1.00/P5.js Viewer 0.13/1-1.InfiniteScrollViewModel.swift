import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import Combine

class InfiniteScrollViewModel: ObservableObject {
    @Published var items: [Item] = []
    private var lastDocumentSnapshot: DocumentSnapshot?
    var isFetching = false // It was "private" before.
    private let pageSize = 3 // Fetch 3 documents at a time
    
    init() {
        print("[InfiniteScrollViewModel][init]")
        loadItems() // Load locally stored items if available
        refreshData() // Fetch new items and update local storage
    }
    
    func refreshData() {
        print("[InfiniteScrollViewModel][refreshData]")
        fetchData() // Existing fetchData logic, then save new items and download images
//        saveItems()
    }
    
    func fetchData() {
        print("[InfiniteScrollViewModel][fetchData]")
        guard !isFetching else {
            print("[InfiniteScrollViewModel][fetchData]: Fetch attempt blocked, fetch already in progress.")
            return
        }
        isFetching = true
        
        var query: Query = Firestore.firestore().collection("sketches").order(by: "likes", descending: true).limit(to: pageSize)
        
        if let lastSnapshot = lastDocumentSnapshot {
            print("[InfiniteScrollViewModel][fetchData][lastSnapshot]:lastSnapshot")
            query = query.start(afterDocument: lastSnapshot)
            print("[InfiniteScrollViewModel][fetchData]: Query set to start after last known document.")
        } else {
            print("[InfiniteScrollViewModel][fetchData]: Starting new query from the beginning of the collection.")
        }
        
        query.getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else {
                print("[InfiniteScrollViewModel][fetchData]: Self is nil, returning early.")
                return
            }
            
            if let error = error {
                self.isFetching = false
                print("[InfiniteScrollViewModel][fetchData]: Error fetching documents: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                self.isFetching = false
                print("[InfiniteScrollViewModel][fetchData]: No documents fetched, or documents are empty.")
                return
            }
            
            print("[InfiniteScrollViewModel][fetchData]: Fetched \(documents.count) documents.")
            
            let newItems = documents.compactMap { doc -> Item? in
                print("[InfiniteScrollViewModel][fetchData]: Attempting to decode document with firebase ID \(doc.documentID).")
                return Item(document: doc)
            }

            
            DispatchQueue.main.async {
                let existingIDs = Set(self.items.map { $0.id })
                let filteredNewItems = newItems.filter { !existingIDs.contains($0.id) }
                
                self.items.append(contentsOf: filteredNewItems)
                self.lastDocumentSnapshot = documents.last
                self.isFetching = false
                
                print("[InfiniteScrollViewModel][fetchData]: Updated items array and lastDocumentSnapshot. Items count now \(self.items.count).")
                
                self.saveItems()
                
                newItems.forEach { item in
                    self.downloadImage(for: item.previewName)
                }
            }
        }
    }

    func downloadImage(for imageName: String) { //
        print("[InfiniteScrollViewModel][downloadImage]")
        guard let localURL = localFileURL(for: imageName), !FileManager.default.fileExists(atPath: localURL.path) else { return }
        
        let imagePath = "previews/\(imageName)"
        let storageRef = Storage.storage().reference(withPath: imagePath)
        
        // Fetch the image data
        storageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            guard let imageData = data, error == nil else { return }
            
            // Save the downloaded image to the local filesystem
            do {
                try imageData.write(to: localURL)
                print("[InfiniteScrollViewModel][downloadImage]:Image saved.")
//                print("[InfiniteScrollViewModel][downloadImage]:Image saved to \(localURL.path)")
            } catch {
                print("\(red)[InfiniteScrollViewModel][downloadImage]:Error saving image: \(error)\(red)")
            }
        }
    }
    // Call this method when nearing the end of the current list
    func loadMoreContentIfNeeded(currentItem item: Item?) {
        guard let item = item else {
            fetchData()
            return
        }
        
        let thresholdIndex = items.index(items.endIndex, offsetBy: -1)
        if let itemIndex = items.firstIndex(where: { $0.id == item.id }), itemIndex >= thresholdIndex {
            fetchData()
        }
    }
    
    func saveItems() {
        print("[InfiniteScrollViewModel][saveItems]")
        
        let fileManager = FileManager.default
        let fileURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("scrollingViewList.json")
        
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL, options: .atomicWrite)
            print("[InfiniteScrollViewModel][saveItems]: Successfully saved items.")
        } catch {
            print("[InfiniteScrollViewModel][saveItems]: Error saving items: \(error.localizedDescription)")
            
            if !fileManager.fileExists(atPath: fileURL.path) {
                print("[InfiniteScrollViewModel][saveItems]: The file \(fileURL.lastPathComponent) does not exist and will be created.")
            } else {
                print("[InfiniteScrollViewModel][saveItems]: The file \(fileURL.lastPathComponent) exists and will be overwritten.")
            }
        }
    }

    
//    func loadItems() {
//        let fileManager = FileManager.default
//        let fileURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("scrollingViewList.json")
//        print("This is the url of the scrollingViewList.json: \(fileURL)")
//        if fileManager.fileExists(atPath: fileURL.path) {
//            do {
//                let data = try Data(contentsOf: fileURL)
//                items = try JSONDecoder().decode([Item].self, from: data)
//            } catch {
//                print("[InfiniteScrollViewModel][loadItems]:Error loading items: \(error)")
//            }
//        } else {
//            print("[InfiniteScrollViewModel][loadItems]:Did not found")
//            items = []  // Ensure items are reset if no file is found
//        }
//    }
    func loadItems() {
        let fileManager = FileManager.default
        let fileURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("scrollingViewList.json")
        
            // Check if the file exists
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                    // Instead of loading data, reset the file by writing an empty array to it
                let emptyData = try JSONEncoder().encode([Item]())
                try emptyData.write(to: fileURL, options: .atomicWrite)
                print("[InfiniteScrollViewModel][loadItems]: File content cleared.")
            } catch {
                print("[InfiniteScrollViewModel][loadItems]: Error resetting file: \(error)")
            }
        } else {
            print("[InfiniteScrollViewModel][loadItems]: File not found, will be created upon saving items.")
        }
            // Start with an empty items array
        items = []
    }


}


func fetchAllDocumentIDs(from collection: String, completion: @escaping ([String]) -> Void) {
    let db = Firestore.firestore()
    db.collection(collection).getDocuments { (querySnapshot, error) in
        guard let documents = querySnapshot?.documents else {
            print("\(red)[fetchAllDocumentIDs]:Error fetching documents: \(error?.localizedDescription ?? "Unknown error")\(red)")
            completion([])
            return
        }
        let ids = documents.map { $0.documentID }
        completion(ids)
    }
}

