import Foundation
import WebKit
import UIKit



class WebViewSnapshotter: NSObject, WKNavigationDelegate {
    var webView: WKWebView!
    var completion: ((UIImage?) -> Void)?
    
    init(url: URL, completion: @escaping (UIImage?) -> Void) {
        super.init()
        // Create a WKWebView instance and set its navigation delegate
        webView = WKWebView()
        webView.frame = CGRect(x: 0, y: 0, width: 500, height: 500)

        if let windowScene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .first as? UIWindowScene,
           let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
            let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            containerView.clipsToBounds = true  // Ensure content outside this frame is not visible
            webView.frame = CGRect(x: -500, y: 0, width: 500, height: 500)  // Positioned entirely outside the container view's visible area
            containerView.addSubview(webView)
            keyWindow.addSubview(containerView)  // Minimize the impact on the visible UI
        }

        
        webView.navigationDelegate = self
        
        self.completion = completion
        
        // Load the URL request
        if Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "TestSketch1981360") != nil {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        print("1.WebViewSnapshotter Initiated")
    }
    
    // Called when the web content has finished loading
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Call the method to take a snapshot of the web content
        print("2. webView didFinish executed")
        //        takeSnapshot { [weak self] image in
        //            self?.completion?(image)
        //        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Adjust delay as necessary
            self.takeSnapshot { [weak self] image in
                self?.completion?(image)
            }
        }
    }
    
    // Called if the web content loading fails
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Web content loading failed: \(error.localizedDescription)")
        completion?(nil)
    }
    
    // Take a snapshot of the web content
    private func takeSnapshot(completion: @escaping (UIImage?) -> Void) {
        let config = WKSnapshotConfiguration()
        // Adjust configuration if necessary (e.g., specifying a specific rect to snapshot)
        
        webView.takeSnapshot(with: config) { [weak self] image, error in
            defer {
                // Ensure webView is removed from its parent view in all cases
                DispatchQueue.main.async {
                    self?.webView.removeFromSuperview()
                }
            }
            
            if let error = error {
                print("Snapshot error: \(error.localizedDescription)")
                completion(nil)
            } else if let image = image {
                print("3. Snapshot is taken successfully")
                completion(image)
            } else {
                print("Snapshot returned nil image")
                completion(nil)
            }
        }
    }
}
// This is in charge of saving the image from the WKWebView


class ImageSaver: NSObject {
    static let shared = ImageSaver()
    
    func saveImage(_ image: UIImage) {
        print("5. Trying to Save")
        DispatchQueue.main.async {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error saving image: \(error.localizedDescription)")
        } else {
            print("6. Image saved successfully")
        }
    }
}
// This is in charge of put the image into photo album
