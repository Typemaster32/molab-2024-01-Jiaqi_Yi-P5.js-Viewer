import SwiftUI
import Foundation

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchHistory: [String] = []
    @State private var sketches: [Sketch] = [] // State to hold fetched sketches
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                searchSection
                // Search field + icon
                Text("You can also paste the link of the sketch here")
                    .font(.system(size: 12, weight: .regular))
                    .padding(.horizontal)
                    .foregroundColor(.gray)
                Text("Search History:")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                // Instruction texts
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(searchHistory, id: \.self) { historyItem in
                            Button(action: {
                                self.searchText = historyItem
                                self.search()
                            }) {
                                Text(historyItem)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 6)
                                    .background(Color.gray.opacity(0.2)) // Light gray background
                                    .foregroundColor(.gray) // Text color
                                    .cornerRadius(12) // Rounded corners
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                // Section for searching history
                
                if !sketches.isEmpty {
                    List(sketches.indices, id: \.self) { index in
                        NavigationLink(destination: SketchDetailView(sketch: sketches[index])) {
                            Text("\(index + 1). \(sketches[index].name)")
                        }
                    }
                }
                // Search Result
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("Search")
        }
    }
    
    private var searchSection: some View {
        HStack {
            TextField("Search...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disableAutocorrection(true)
                .border(Color(red: 0.4, green: 0.41, blue: 0.44), width: 1.2)
                .submitLabel(.search)
                .onSubmit {
                    print("Search has been submitted")
                    search()
                }
            
            Button(action: {
                print("Search button has been clicked")
                search()
            }) {
                Image(systemName: "magnifyingglass")
                    .imageScale(.large)
                    .foregroundColor(.black)
                    .font(.system(size: 20, weight: .semibold))
            }
            .padding(5)
        }
        .padding(.horizontal)
    }
    
    func search() {
        // Add to the search history if it is not blank and not repeated
        if !searchText.isEmpty && !searchHistory.contains(searchText) {
            searchHistory.insert(searchText, at: 0)
            // Optionally, limit the search history length
            
            if searchHistory.count > 10 {
                searchHistory.removeLast()
                print("The last of search history is removed")
            }
        }
        
        // Assuming 'fetchSketchArray' fetches sketches and updates 'sketches' state
        fetchSketchArray(from: "https://editor.p5js.org/editor/\(searchText)/projects") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedSketches):
                    self.sketches = fetchedSketches
                case .failure(let error):
                    print("Error fetching sketches: \(error.localizedDescription)")
                }
            }
        }
        searchText = "" // Clear the search text
    }
}

struct SketchDetailView: View {
    let sketch: Sketch
    
    var body: some View {
        VStack {
            Text(sketch.name)
            // Add more details as needed
        }
        .navigationTitle("Sketch Details")
    }
}

// Define your Sketch struct and fetchSketchArray function as previously described


// Define a struct that matches the JSON structure
struct Sketch: Decodable {
    let name: String
    let _id: String
    let files: [File]
    let id: String
    let createdAt: Date
    let updatedAt: Date
}

struct File: Codable {
    let name: String
    let content: String
    let children: [String]?
    let fileType: String
    let _id: String
    let isSelectedFile: Bool?
    let createdAt: Date
    let updatedAt: Date
}

func fetchSketchArray(from urlString: String, completion: @escaping (Result<[Sketch], Error>) -> Void) {
    guard let url = URL(string: urlString) else {
        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
        return
    }
    print(urlString)
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            completion(.failure(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])))
            return
        }
        
        guard let data = data else {
            completion(.failure(NSError(domain: "", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data"])))
            return
        }
        
        do {
            let decoder = JSONDecoder()
            // decoder.dateDecodingStrategy = .iso8601 // Or use a custom formatter if necessary
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'" // Adjust this format to match your actual date strings
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // Adjust if your dates aren't in UTC
            dateFormatter.locale = Locale(identifier: "en_US_POSIX") // Recommended for fixed-format date strings
            
            // Use the custom DateFormatter
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            let items = try decoder.decode([Sketch].self, from: data)
            completion(.success(items))
        } catch {
            print("Decoding failed with error: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .dataCorrupted(let context),
                        .keyNotFound(_, let context),
                        .typeMismatch(_, let context),
                        .valueNotFound(_, let context):
                    print("Decoding error: \(context.debugDescription)")
                    print("CodingPath: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                @unknown default:
                    break
                }
            }
            completion(.failure(error))
        }
    }
    
    task.resume()
}


// Example usage
//let urlString = "https://yourapi.com/items.json"
//fetchItems(from: urlString)


//struct SearchView_Previews: PreviewProvider {
//    static var previews: some View {
//        SearchView()
//    }
//}

