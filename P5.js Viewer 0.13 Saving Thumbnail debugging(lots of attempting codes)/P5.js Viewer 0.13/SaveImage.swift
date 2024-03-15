import Foundation
import WebKit
import UIKit

// Helper extension to resize images
extension UIImage {
    func resizedToThumbnail() -> UIImage? {
        let targetSize = CGSize(width: 100, height: 100) // Adjust the size as needed
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(targetSize, false, scale)
        self.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}

class WebViewSnapshotter: NSObject, WKNavigationDelegate {
    var webView: WKWebView!
    var completion: ((UIImage?, Bool) -> Void)?
    var saveToURL: URL?
    
    // Modified init to include an optional saveToURL parameter
    // Update the initializer to match the new completion handler signature
    init(url: URL, saveToURL: URL? = nil, completion: @escaping (UIImage?, Bool) -> Void) {
        super.init()
        self.saveToURL = saveToURL
        self.completion = completion
        setupWebView() // Setup the web view
        loadURL(url) // Load the requested URL
    }


    
    private func setupWebView() {
        // Create a WKWebView instance and set its navigation delegate
        webView = WKWebView()
        webView.navigationDelegate = self
        
        // Positioning the webView off-screen
        if let windowScene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .first as? UIWindowScene,
           let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
            let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            containerView.clipsToBounds = true
            webView.frame = CGRect(x: -500, y: 0, width: 500, height: 500) // Positioned entirely outside the container view's visible area
            containerView.addSubview(webView)
            keyWindow.addSubview(containerView) // Minimize the impact on the visible UI
        }
        
        print("WebView setup completed.")
    }

    
    private func loadURL(_ url: URL) {
        // Load the URL request
        let request = URLRequest(url: url)
        webView.load(request)
        print("URL request loaded.")
    }

    
    // Snapshot and saving logic remains mostly unchanged
    // Adjustments made to call completion with a Bool indicating success or failure
    
    // New method to handle image saving based on the mode
    private func saveImage(_ image: UIImage) {
        guard let resizedImage = image.resizedToThumbnail() else {
            print("Failed to resize image")
            completion?(nil, false)
            return
        }
        
        if let saveToURL = saveToURL {
            // Save to specified URL
            do {
                if let imageData = resizedImage.jpegData(compressionQuality: 0.5) { // Adjust compression quality as needed
                    try imageData.write(to: saveToURL)
                    print("Image saved to URL: \(saveToURL)")
                    completion?(resizedImage, true)
                } else {
                    print("Failed to generate image data")
                    completion?(nil, false)
                }
            } catch {
                print("Error saving image to URL: \(error)")
                completion?(nil, false)
            }
        } else {
            // Use self explicitly when calling completion
            ImageSaver.shared.saveImage(resizedImage) { success in
                self.completion?(resizedImage, success)
            }
        }
    }
}


class ImageSaver: NSObject {
    static let shared = ImageSaver()
    
    // Modified to include a completion handler
    func saveImage(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        print("5. Trying to Save")
        DispatchQueue.main.async {
            // Pass the completion as contextInfo to be retrievable in the selector
            let contextInfo = UnsafeMutablePointer<((Bool) -> Void)>.allocate(capacity: 1)
            contextInfo.initialize(to: completion)
            
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), contextInfo)
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        // Retrieve the completion handler
        let completion = contextInfo.assumingMemoryBound(to: ((Bool) -> Void).self).pointee
        
        if let error = error {
            print("Error saving image: \(error.localizedDescription)")
            completion(false)
        } else {
            print("6. Image saved successfully")
            completion(true)
        }
        
        // Free the allocated contextInfo now that we're done with it
        contextInfo.deallocate()
    }
}



//class WebViewSnapshotter: NSObject, WKNavigationDelegate {
//    var webView: WKWebView!
//    var completion: ((UIImage?) -> Void)?
//    
//    init(url: URL, completion: @escaping (UIImage?) -> Void) {
//        super.init()
//        // Create a WKWebView instance and set its navigation delegate
//        webView = WKWebView()
//        webView.frame = CGRect(x: 0, y: 0, width: 500, height: 500)
//
//        if let windowScene = UIApplication.shared.connectedScenes
//            .filter({ $0.activationState == .foregroundActive })
//            .first as? UIWindowScene,
//           let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
//            let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
//            containerView.clipsToBounds = true  // Ensure content outside this frame is not visible
//            webView.frame = CGRect(x: -500, y: 0, width: 500, height: 500)  // Positioned entirely outside the container view's visible area
//            containerView.addSubview(webView)
//            keyWindow.addSubview(containerView)  // Minimize the impact on the visible UI
//        }
//
//        
//        webView.navigationDelegate = self
//        
//        self.completion = completion
//        
//        // Load the URL request
//        if Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "TestSketch1981360") != nil {
//            let request = URLRequest(url: url)
//            webView.load(request)
//        }
//        print("1.WebViewSnapshotter Initiated")
//    }
//    
//    // Called when the web content has finished loading
//    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        // Call the method to take a snapshot of the web content
//        print("2. webView didFinish executed")
//        //        takeSnapshot { [weak self] image in
//        //            self?.completion?(image)
//        //        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Adjust delay as necessary
//            self.takeSnapshot { [weak self] image in
//                self?.completion?(image)
//            }
//        }
//    }
//    
//    // Called if the web content loading fails
//    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
//        print("Web content loading failed: \(error.localizedDescription)")
//        completion?(nil)
//    }
//    
//    // Take a snapshot of the web content
//    private func takeSnapshot(completion: @escaping (UIImage?) -> Void) {
//        let config = WKSnapshotConfiguration()
//        // Adjust configuration if necessary (e.g., specifying a specific rect to snapshot)
//        
//        webView.takeSnapshot(with: config) { [weak self] image, error in
//            defer {
//                // Ensure webView is removed from its parent view in all cases
//                DispatchQueue.main.async {
//                    self?.webView.removeFromSuperview()
//                }
//            }
//            
//            if let error = error {
//                print("Snapshot error: \(error.localizedDescription)")
//                completion(nil)
//            } else if let image = image {
//                print("3. Snapshot is taken successfully")
//                completion(image)
//            } else {
//                print("Snapshot returned nil image")
//                completion(nil)
//            }
//        }
//    }
//}
//// This is in charge of saving the image from the WKWebView
//
//
//class ImageSaver: NSObject {
//    static let shared = ImageSaver()
//    
//    func saveImage(_ image: UIImage) {
//        print("5. Trying to Save")
//        DispatchQueue.main.async {
//            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
//        }
//    }
//    
//    
//    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
//        if let error = error {
//            print("Error saving image: \(error.localizedDescription)")
//        } else {
//            print("6. Image saved successfully")
//        }
//    }
//}
//// This is in charge of put the image into photo album
