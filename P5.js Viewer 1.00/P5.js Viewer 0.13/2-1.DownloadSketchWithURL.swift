import SwiftUI

struct downloadSketchWithURL: View { // This is including WebContentView
    let urlString: String
    let author: String
    let title: String
    let p5id: String
    let createdAt: Date
        //    let updatedAt: String
    @State private var downloadedFileURL: URL? = nil
    @State private var isDownloadComplete = false
    @State private var progress = 0.0
    
    var body: some View {
        VStack {
            if isDownloadComplete, let downloadedFileURL = downloadedFileURL {
                WebContentView(sourceLocalURL: downloadedFileURL,title:title,author:author,p5id:p5id,createdAt: createdAt)//implement p5id;
            } else {
                    //                Text("Downloading...")
                ProgressView(value: progress, total: 100)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(height: 12)
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
                        withAnimation(.linear(duration: 8)) {
                            self.progress = 100
                        }
                    }
                
            }
        }
    }
    
    private func downloadFile(from urlString: String, completion: @escaping (Result<URL, Error>) -> Void) {
        print("[downloadFile]: Initiated download from URL: \(urlString)")
        guard let url = URL(string: urlString) else {
            print("[downloadFile]: Invalid URL.")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[downloadFile]: Error downloading file: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("[downloadFile]: Received HTTP response code: \(String(describing: (response as? HTTPURLResponse)?.statusCode)).")
                    completion(.failure(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])))
                    return
                }
                
                guard let data = data else {
                    print("[downloadFile]: No data received from the server.")
                    completion(.failure(NSError(domain: "", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                    return
                }
                
                let suggestedFilename = httpResponse.value(forHTTPHeaderField: "Content-Disposition")?.extractFilename() ?? url.lastPathComponent
                
                let fileManager = FileManager.default
                guard let documentsDirectory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
                    print("[downloadFile]: Unable to find documents directory.")
                    completion(.failure(NSError(domain: "", code: -4, userInfo: [NSLocalizedDescriptionKey: "Unable to find documents directory"])))
                    return
                }
                
                let savedURL = documentsDirectory.appendingPathComponent(suggestedFilename)
                do {
                    try data.write(to: savedURL)
                    print("[downloadFile]: File successfully saved to \(savedURL).")
                    completion(.success(savedURL))
                } catch {
                    print("[downloadFile]: Failed to save file: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
        print("[downloadFile]: HTTP request initiated.")
    }
    
}




extension String {
    func extractFilename() -> String? {
        if let regex = try? NSRegularExpression(pattern: "filename[^;=\\n]*=((['\"]).*?\\2|[^;\\n]*)", options: .caseInsensitive) {
            let nsString = self as NSString
            let results = regex.matches(in: self, options: [], range: NSRange(location: 0, length: nsString.length))
            for result in results {
                if let range = Range(result.range(at: 1), in: self) {
                    return String(self[range]).trimmingCharacters(in: .init(charactersIn: "\"'"))
                }
            }
        }
        return nil
    }
}
