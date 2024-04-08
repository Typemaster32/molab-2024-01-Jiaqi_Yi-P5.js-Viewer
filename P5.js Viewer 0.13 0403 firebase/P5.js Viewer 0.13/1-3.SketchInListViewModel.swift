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
        fetchData()
    }
    
    func fetchData() {
        guard !isFetching else { return } // Prevent multiple fetch requests
        isFetching = true
        
        var query: Query = Firestore.firestore().collection("sketches").order(by: "updatedAt", descending: true).limit(to: pageSize)
        
        // Use the last document fetched as the starting point for the next query
        if let lastSnapshot = lastDocumentSnapshot {
            query = query.start(afterDocument: lastSnapshot)
        }
        
        query.getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self, let documents = querySnapshot?.documents else {
                self?.isFetching = false
                print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            let newItems = documents.compactMap { doc -> Item? in
                try? doc.data(as: Item.self)
            }
            self.items.append(contentsOf: newItems)
            self.lastDocumentSnapshot = documents.last // Keep the last document for pagination
            self.isFetching = false
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
}


func fetchAllDocumentIDs(from collection: String, completion: @escaping ([String]) -> Void) {
    let db = Firestore.firestore()
    db.collection(collection).getDocuments { (querySnapshot, error) in
        guard let documents = querySnapshot?.documents else {
            print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
            completion([])
            return
        }
        let ids = documents.map { $0.documentID }
        completion(ids)
    }
}
