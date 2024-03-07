import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchHistory: [String] = []
    
    var body: some View {
        NavigationView {

            VStack(alignment: .leading) {
                HStack {
                    TextField("Search...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .border(Color(red: 0.4, green: 0.41, blue: 0.44), width: 1.2)
                        .submitLabel(.search)
                        .onSubmit {
                            search()
                        }
                    
                    Button(action: {
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
                
                Text("You can also paste the link of the sketch here")
                    .font(.system(size: 12, weight: .regular))
                    .padding(.horizontal)
                    .foregroundColor(.gray)
                
                Text("Search History:")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.vertical,5)
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("Search")
        }
    }
    
    func search() {
        if !searchText.isEmpty && !searchHistory.contains(searchText) {
            searchHistory.insert(searchText, at: 0)
            // Optionally, limit the search history length
            if searchHistory.count > 10 {
                searchHistory.removeLast()
            }
        }
        // Implement your search logic here
        // For demonstration, this simply clears the search text
        searchText = ""
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
