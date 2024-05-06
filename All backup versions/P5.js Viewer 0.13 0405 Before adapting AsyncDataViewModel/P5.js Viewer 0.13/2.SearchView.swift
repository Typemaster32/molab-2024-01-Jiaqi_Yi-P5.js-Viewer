import SwiftUI
import Foundation

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchPlaceholder = "Name of the Artist"
    @State private var searchHistory: [String] = []
    @State private var sketches: [Sketch] = [] // State to hold fetched sketches
    @State private var errorMessage: String = ""
    @State private var showingErrorAlert: Bool = false
    @State private var currentAuthor: String = ""
    
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                searchSection
                // Search field + icon
                    Text("You can also paste the link of the sketch here")
                        .font(.system(size: 12, weight: .regular))
                        .padding(.horizontal)
                        .foregroundColor(.gray)
                    
                
                HStack{
                    Text("Search History:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.vertical, 5)
                    Spacer()
                    Button(action: {
                        self.searchHistory = []
                    }) {
                        Text("Clear")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                }
                // Instruction texts
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(searchHistory, id: \.self) { historyItem in
                            Button(action: {
                                self.searchText = historyItem
                                self.searchArtist()
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
                HStack{
                    Text("Results:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.vertical, 5)
                    Spacer()
                    Button(action: {
                        self.sketches = []
                        self.searchPlaceholder = "Name of the Artist"
                    }) {
                        Text("Refresh")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                // Banner of the result page
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray)
                //Divider
                
                if !sketches.isEmpty {
                    List(sketches.indices, id: \.self) { index in
                        NavigationLink(destination: downloadSketchWithURL(urlString: "https://editor.p5js.org/editor/projects/\(sketches[index].id)/zip",author:currentAuthor,title:sketches[index].name)) {
                            Text("\(index + 1). \(sketches[index].name)")
                        }
                    }.background(Color.white) // Set the background color of the List
                        .listStyle(PlainListStyle())
                }
                // Search Result
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("Search")
        }
        .alert(isPresented: $showingErrorAlert) {
            Alert(title: Text("Error"),
                  message: Text(errorMessage),
                  dismissButton: .default(Text("OK")) {
                // Reset the error message or perform any other dismiss action
                self.errorMessage = ""
            })
        }
    }
    
    private var searchSection: some View {
        HStack {
            TextField(self.searchPlaceholder, text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disableAutocorrection(true)
                .border(Color(red: 0.4, green: 0.41, blue: 0.44), width: 1.2)
                .submitLabel(.search)
                .onSubmit {
                    print("Search has been submitted")
                    searchArtist()
                }
            
            Button(action: {
                print("Search button has been clicked")
                searchArtist()
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
    
    func searchArtist() {
        // Add to the search history if it is not blank and not repeated
        if !searchText.isEmpty && !searchHistory.contains(searchText) {
            searchHistory.insert(searchText, at: 0)
            // Optionally, limit the search history length
            self.searchPlaceholder = "Name of the Sketch"
            if searchHistory.count > 5 {
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
                    currentAuthor = searchText
                case .failure(let error):
                    print("Error fetching sketches: \(error.localizedDescription)")
                    // Update the state to show the error message to the user
                    self.errorMessage = "Sorry, it might have been: 1. Invalid artist name of P5.js Web Editor;  2.Internet Problem."
                    self.showingErrorAlert = true
                }
            }
        }
//        searchText = "Sketch of the artist" // Clear the search text
    }
    
    func searchSketch() {
        // TBD
    }
    
}


struct Sketch: Decodable {
    var name: String
    var _id: String
    var files: [File]
    var id: String
    var createdAt: Date
    var updatedAt: Date
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
struct ErrorResponse: Codable {
    let message: String
}

func fetchSketchArray(from urlString: String, completion: @escaping (Result<[Sketch], Error>) -> Void) {
    guard let url = URL(string: urlString) else {
        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
        return
    }
    //    print(urlString)
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
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            let items = try decoder.decode([Sketch].self, from: data)
            completion(.success(items))
        } catch {
            // New logic to check for specific error message starts here
            do {
                let decoder = JSONDecoder()
                let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
                if errorResponse.message == "User with that username does not exist." {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "", code: -4, userInfo: [NSLocalizedDescriptionKey: errorResponse.message])))
                    }
                    return
                }
            } catch DecodingError.keyNotFound {
                // Handle the case where the key 'message' is not found, which might indicate a different error structure
                print("Error response not in expected format or different error")
            } catch {
                print("Failed to decode error response")
            }
            // Original error handling logic if the specific error message is not detected
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



//struct SearchView_Previews: PreviewProvider {
//    static var previews: some View {
//        SearchView()
//    }
//}

