import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import Combine

class InfiniteScrollViewModel: ObservableObject {
    @Published var items: [Item] = []
    private var lastDocumentSnapshot: DocumentSnapshot?
    private var isFetching = false
    private let pageSize = 5 // Fetch 3 documents at a time
    
    init() {
        loadItems() // Load locally stored items if available
        refreshData() // Fetch new items and update local storage
        print("\(blue)[InfiniteScrollViewModel]: init()\(blue)")
    }
    
    func refreshData() {
        fetchData() // Existing fetchData logic, then save new items and download images
        saveItems()
    }
    
    func fetchData() {
        guard !isFetching else { return } // Prevent multiple fetch requests
        isFetching = true
        
        var query: Query = Firestore.firestore().collection("sketches").order(by: "likes", descending: true).limit(to: pageSize)
        
        // Use the last document fetched as the starting point for the next query
        if let lastSnapshot = lastDocumentSnapshot {
            query = query.start(afterDocument: lastSnapshot)
        }
        
        query.getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self, let documents = querySnapshot?.documents else {
                self?.isFetching = false
                print("\(red)[InfiniteScrollViewModel][fetchData]:Error fetching documents: \(error?.localizedDescription ?? "Unknown error")\(red)")
                return
            }
            let newItems = documents.compactMap { doc -> Item? in
                try? doc.data(as: Item.self)
            }
            DispatchQueue.main.async {
                self.items.append(contentsOf: newItems)
                self.lastDocumentSnapshot = documents.last // Keep the last document for pagination
                self.isFetching = false
                
                // Save the updated items list locally
                self.saveItems()
                
                // Download new images for new items
                newItems.forEach { self.downloadImage(for: $0.previewName) }
            }
        }
    }

    func downloadImage(for imageName: String) { //
        print("\(blue)[InfiniteScrollViewModel][downloadImage]: Initiated\(blue)")
        guard let localURL = localFileURL(for: imageName), !FileManager.default.fileExists(atPath: localURL.path) else { return }
        
        let imagePath = "previews/\(imageName)"
        let storageRef = Storage.storage().reference(withPath: imagePath)
        
        // Fetch the image data
        storageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            guard let imageData = data, error == nil else { return }
            
            // Save the downloaded image to the local filesystem
            do {
                try imageData.write(to: localURL)
                print("[InfiniteScrollViewModel][downloadImage]:Image saved to \(localURL.path)")
            } catch {
                print("\(red)[InfiniteScrollViewModel][downloadImage]:Error saving image: \(error)\(red)")
            }
        }
        print("[InfiniteScrollViewModel][downloadImage]: At \(localURL)")
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
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("scrollingViewList.json")
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL, options: .atomicWrite)
        } catch {
            print("Error saving items: \(error)")
        }
    }
    
    func loadItems() {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("scrollingViewList.json")
        do {
            let data = try Data(contentsOf: fileURL)
            items = try JSONDecoder().decode([Item].self, from: data)
        } catch {
            print("Error loading items: \(error)")
        }
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

