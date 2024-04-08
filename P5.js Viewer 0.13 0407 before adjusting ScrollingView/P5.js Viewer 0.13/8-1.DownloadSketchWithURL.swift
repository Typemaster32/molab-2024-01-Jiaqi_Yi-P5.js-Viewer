import SwiftUI

struct downloadSketchWithURL: View {
    let urlString: String
    let author: String
    let title: String
    let p5id: String
    let createdAt: Date
//    let updatedAt: String
    @State private var downloadedFileURL: URL? = nil
    @State private var isDownloadComplete = false
    
    var body: some View {
        VStack {
            if isDownloadComplete, let downloadedFileURL = downloadedFileURL {
                WebContentView(sourceLocalURL: downloadedFileURL,title:title,author:author,p5id:p5id,createdAt: createdAt)//implement p5id;
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
        print("[downloadFile][downloadFile]: Initiated download from URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("[downloadFile][downloadFile]: Invalid URL.")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[downloadFile][downloadFile]: Error downloading file: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("[downloadFile][downloadFile]: Received HTTP response code: \(String(describing: (response as? HTTPURLResponse)?.statusCode)).")
                    completion(.failure(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])))
                    return
                }
                
                guard let data = data else {
                    print("[downloadFile][downloadFile]: No data received from the server.")
                    completion(.failure(NSError(domain: "", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                    return
                }
                
                let fileManager = FileManager.default
                guard let documentsDirectory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
                    print("[downloadFile][downloadFile]: Unable to find documents directory.")
                    completion(.failure(NSError(domain: "", code: -4, userInfo: [NSLocalizedDescriptionKey: "Unable to find documents directory"])))
                    return
                }
                
                let savedURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
                do {
                    try data.write(to: savedURL)
                    print("[downloadFile][downloadFile]: File successfully saved to \(savedURL.lastPathComponent).")
                    completion(.success(savedURL))
                } catch {
                    print("[downloadFile][downloadFile]: Failed to save file: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
        print("[downloadFile][downloadFile]: HTTP request initiated.")
    }

  
}




