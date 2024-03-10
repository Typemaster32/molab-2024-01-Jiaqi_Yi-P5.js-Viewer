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
                WebContentView(sourceURL: downloadedFileURL,title:title,author:author)
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

    
    
    
    private func downlo3adFile(from urlString: String, completion: @escaping (Result<URL, Error>) -> Void) {
        print("---downloadFile---")
        print("This is the urlString: \(urlString)")
        guard let url = URL(string: urlString) else {
            let error = NSError(domain: "DownloadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            print("Error: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.downloadTask(with: url) { (tempLocalUrl, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Download Task Error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    let error = NSError(domain: "DownloadError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
                    print("Error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let tempLocalUrl = tempLocalUrl else {
                    let error = NSError(domain: "DownloadError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Download failed"])
                    print("Error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                let fileManager = FileManager.default
                // Create a temporary directory within the app's directory to hold the download temporarily
                let tempDirectory = NSTemporaryDirectory()
                let tempDirectoryURL = URL(fileURLWithPath: tempDirectory)
                let tempFileURL = tempDirectoryURL.appendingPathComponent(url.lastPathComponent)
                
                do {
                    // Copy the file from the system temporary location to the app's temporary directory
                    if fileManager.fileExists(atPath: tempFileURL.path) {
                        try fileManager.removeItem(at: tempFileURL)
                    }
                    try fileManager.copyItem(at: tempLocalUrl, to: tempFileURL)
                    print("Temporary file copy is successful to: \(tempFileURL.path)")
                } catch {
                    print("Copying temporary file failed: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                // Proceed with the rest of your handling, replacing `tempLocalUrl` with `tempFileURL`
                // For example, moving the file from the app's temporary directory to its final destination
                // This part of the code would continue as before, using `tempFileURL` instead of `tempLocalUrl`
                
                // Rest of your implementation...
//                let fileManager = FileManager.default
                guard let documentsDirectory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
                    let error = NSError(domain: "DownloadError", code: -4, userInfo: [NSLocalizedDescriptionKey: "Unable to find documents directory"])
                    print("Error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                let downloadsFolder = documentsDirectory.appendingPathComponent("downloadedSearch")
                
                if !fileManager.fileExists(atPath: downloadsFolder.path) {
                    do {
                        try fileManager.createDirectory(at: downloadsFolder, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        print("Error creating directory: \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }
                }
                
                let filename = httpResponse.suggestedFilename ?? url.lastPathComponent
                let savedUrl = downloadsFolder.appendingPathComponent(filename)
                
                if fileManager.fileExists(atPath: savedUrl.path) {
                    print("File already exists at the savedUrl: \(savedUrl)")
                    completion(.success(savedUrl))
                    return
                }
                
                if fileManager.fileExists(atPath: tempFileURL.path) {
                    print("File already exists at the tempLocalUrl: \(tempFileURL)")
                }
                
                do {
                    try fileManager.moveItem(at: tempFileURL, to: savedUrl)
                    print("Moving is successful to: \(savedUrl.path)")
                    completion(.success(savedUrl))
                } catch let moveError {
                    print("Moving File Error: \(moveError.localizedDescription)")
                    completion(.failure(moveError))
                }
            }
        }
        
        task.resume()
    }

    
    // as the trigger, leads to "downloadFile" and then WebContentView
    private func d2ownloadFile(from urlString: String, completion: @escaping (Result<URL, Error>) -> Void) {
        
        print("---downloadFile---")
        print("This is the urlString: \(urlString)")
        guard let url = URL(string: urlString) else {
            let error = NSError(domain: "DownloadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            print("Error: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.downloadTask(with: url) { (tempLocalUrl, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Download Task Error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    let error = NSError(domain: "DownloadError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
                    print("Error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let tempLocalUrl = tempLocalUrl else {
                    let error = NSError(domain: "DownloadError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Download failed"])
                    print("Error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                let fileManager = FileManager.default
                guard let documentsDirectory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
                    let error = NSError(domain: "DownloadError", code: -4, userInfo: [NSLocalizedDescriptionKey: "Unable to find documents directory"])
                    print("Error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                let downloadsFolder = documentsDirectory.appendingPathComponent("downloadedSearch")
                
                if !fileManager.fileExists(atPath: downloadsFolder.path) {
                    do {
                        try fileManager.createDirectory(at: downloadsFolder, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        print("Error creating directory: \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }
                }
                
                let filename = httpResponse.suggestedFilename ?? url.lastPathComponent
                let savedUrl = downloadsFolder.appendingPathComponent(filename)
                
                if fileManager.fileExists(atPath: savedUrl.path) {
                    print("File already exists at the savedUrl: \(savedUrl)")
                    completion(.success(savedUrl))
                    return
                }
                
                if fileManager.fileExists(atPath: tempLocalUrl.path) {
                    print("File already exists at the tempLocalUrl: \(tempLocalUrl)")
                }
                
                do {
                    try fileManager.moveItem(at: tempLocalUrl, to: savedUrl)
                    print("Moving is successful to: \(savedUrl.path)")
                    completion(.success(savedUrl))
                } catch let moveError {
                    print("Moving File Error: \(moveError.localizedDescription)")
                    completion(.failure(moveError))
                }
            }
        }
        
        task.resume()
    }
}

class DownloadManager {
    static let shared = DownloadManager()
    private var activeDownloads = 0
    private let maxActiveDownloads = 5 // Set your limit
    
    func downloadFile(from urlString: String, completion: @escaping (Result<URL, Error>) -> Void) {
        DispatchQueue.main.async {
            if self.activeDownloads >= self.maxActiveDownloads {
                completion(.failure(NSError(domain: "DownloadError", code: 429, userInfo: [NSLocalizedDescriptionKey: "Maximum concurrent downloads limit reached. Please try again later."])))
                return
            }
            self.activeDownloads += 1
            print("---downloadFile---")
            print("This is the urlString: \(urlString)")
            // Your download task setup and completion handlers...
            
            // Example completion block
            let fakeCompletionBlock = { (result: Result<URL, Error>) in
                DispatchQueue.main.async {
                    self.activeDownloads -= 1
                    completion(result)
                }
            }
            
            // Simulate a download task
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) { // Simulate network delay
                fakeCompletionBlock(.success(URL(fileURLWithPath: "path/to/file")))
            }
        }
    }
}


/*
 private func downloadFile(from urlString: String, completion: @escaping (Result<URL, Error>) -> Void) {
 
 print("---downloadFile---")
 print("This is the urlString:\(urlString)")
 guard let url = URL(string: urlString) else {
 completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
 return
 }
 
 let task = URLSession.shared.downloadTask(with: url) { (tempLocalUrl, response, error) in
 DispatchQueue.main.async {
 if let error = error {
 completion(.failure(error))
 print("downloadSketchWithURL: Download Task Error")
 return
 }
 
 guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
 completion(.failure(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])))
 print("downloadSketchWithURL: Invalid HTTP response")
 return
 }
 
 guard let tempLocalUrl = tempLocalUrl else {
 completion(.failure(NSError(domain: "", code: -3, userInfo: [NSLocalizedDescriptionKey: "Download failed"])))
 print("downloadSketchWithURL: Download failed")
 return
 }
 
 let fileManager = FileManager.default
 guard let documentsDirectory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
 completion(.failure(NSError(domain: "", code: -4, userInfo: [NSLocalizedDescriptionKey: "Unable to find documents directory"])))
 print("downloadSketchWithURL: Unable to find documents directory")
 return
 }
 
 let downloadsFolder = documentsDirectory.appendingPathComponent("downloadedSearch")
 
 if !fileManager.fileExists(atPath: downloadsFolder.path) {
 print("downloadSketchWithURL: downloadedSearch does not exist")
 do {
 try fileManager.createDirectory(at: downloadsFolder, withIntermediateDirectories: true, attributes: nil)
 } catch {
 completion(.failure(error))
 print("Error creating directory: \(error)")
 return
 }
 }
 
 let filename = httpResponse.suggestedFilename ?? url.lastPathComponent
 let savedUrl = downloadsFolder.appendingPathComponent(filename)
 print("[Download]filename:\(filename)")
 print("[Download]savedUrl:\(savedUrl)")
 print("[Download]tempLocalUrl:\(tempLocalUrl)")
 if fileManager.fileExists(atPath: savedUrl.path) {
 print("file already exists at the savedUrl:\(savedUrl)")
 completion(.success(savedUrl))
 return
 }
 
 do {
 try fileManager.moveItem(at: tempLocalUrl, to: savedUrl)
 print("Moving is successful")
 completion(.success(savedUrl))
 } catch {
 print("downloadSketchWithURL: Moving File Error")
 completion(.failure(error))
 print("(end)")
 }
 }
 }
 
 task.resume()
 }

 */
