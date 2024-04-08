import SwiftUI

struct downloadSketchWithURL: View {
    let urlString: String
    let author: String
    let title: String
    @State private var downloadedFileURL: URL? = nil
    @State private var isDownloadComplete = false
    
    var body: some View {
        VStack {
            if isDownloadComplete, let downloadedFileURL = downloadedFileURL {
                // Assuming WebContentView takes a URL in its initializer
                WebContentView(sourceLocalURL: downloadedFileURL,title:title,author:author)
            } else {
                Text("Downloading...")
                    .onAppear {
                        downloadFile(from: urlString) { result in
                            switch result {
                            case .success(let fileURL):
                                self.downloadedFileURL = fileURL
                                self.isDownloadComplete = true
                                
                            case .failure(let error):
                                print("Download error: \(error)")
                                // Handle error, possibly by showing an alert
                            }
                        }
                    }
            }
        }
    }
    
    private func downloadFile(from urlString: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
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
                
                let fileManager = FileManager.default
                guard let documentsDirectory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
                    completion(.failure(NSError(domain: "", code: -4, userInfo: [NSLocalizedDescriptionKey: "Unable to find documents directory"])))
                    return
                }
                
                let savedURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
                do {
                    try data.write(to: savedURL)
                    completion(.success(savedURL))
                } catch {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
  
}




