import Foundation
import WebKit
import UIKit

// Helper extension to resize images
extension UIImage {
    func resizedToThumbnail() -> UIImage? {
        print("---resizedToThumbnail---")
        let targetSize = CGSize(width: 100, height: 100) // Adjust the size as needed
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(targetSize, false, scale) // Built-in
        self.draw(in: CGRect(origin: .zero, size: targetSize)) // draws the current image (self) into the target size
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() //captures the new, resized image from the context with UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}

class WebViewSnapshotter: NSObject, WKNavigationDelegate {
    var webView: WKWebView!
    var completion: ((UIImage?, Bool) -> Void)?
    var saveToURL: URL?
    
    init(url: URL, saveToURL: URL? = nil, completion: @escaping (UIImage?, Bool) -> Void) {
        super.init()
        print("---WebViewSnapshotter---")
        self.webView = WKWebView()
        self.webView.navigationDelegate = self
        self.saveToURL = saveToURL
        self.completion = completion
        setupWebView()
        loadURL(url)
    }
    
    private func setupWebView() {
        
        print("---WebViewSnapshotter->setupWebView---")
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
    }

    
    private func loadURL(_ url: URL) {
        
        print("---WebViewSnapshotter->loadURL---")
        let request = URLRequest(url: url)
        webView.load(request)
    }

    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("---WebViewSnapshotter->webView---")
        // Content has loaded, now take the snapshot
        takeSnapshot { [weak self] image in
            guard let self = self, let image = image else {
                self?.completion?(nil, false)
                return
            }
            
            if let saveToURL = self.saveToURL {
                // If saving to URL, resize and save image
                self.saveImage(image)
            } else {
                // If not saving to URL, directly use ImageSaver
                ImageSaver.shared.saveImage(image) { success in
                    self.completion?(image, success)
                }
            }
        }
    }

    
    // Snapshot function accessible from SwiftUI
    func takeSnapshot(completion: @escaping (UIImage?) -> Void) {
        print("---WebViewSnapshotter->takeSnapshot---")
        let config = WKSnapshotConfiguration()
        // Configure your snapshot here (e.g., specify rect, afterScreenUpdates, etc.)
        
        webView.takeSnapshot(with: config) { image, error in
            DispatchQueue.main.async {
                guard let image = image, error == nil else {
                    print(error?.localizedDescription ?? "Unknown error")
                    completion(nil)
                    return
                }
                completion(image)
            }
        }
    }

    
    // New method to handle image saving based on the mode
    private func saveImage(_ image: UIImage) {
        print("---WebViewSnapshotter->saveImage---")
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
        print("---ImageSaver->saveImage---[5]Trying to Save")
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
            print("---ImageSaver->saveImage---[6]Image saved successfully")
            completion(true)
        }
        
        // Free the allocated contextInfo now that we're done with it
        contextInfo.deallocate()
    }
}


