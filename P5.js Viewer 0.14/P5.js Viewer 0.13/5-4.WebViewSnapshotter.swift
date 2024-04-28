import Foundation
import WebKit
import UIKit
// This is the former version


class WebViewSnapshotter: NSObject, WKNavigationDelegate {
    var webView: WKWebView!
    var completion: ((UIImage?) -> Void)?
    var width: Int
    var height: Int
    
    
    init(url: URL, width: Int, height: Int, completion: @escaping (UIImage?) -> Void) {
        print("[WebViewSnapshotter][init]: Starting initialization.")
        self.width = width
        self.height = height
        self.completion = completion
        super.init()
        
        // Create a WKWebView instance
        webView = WKWebView()
        webView.navigationDelegate = self
        
        // Attempt to add WebView to an off-screen container
        if let windowScene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .first as? UIWindowScene,
           let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
            print("[WebViewSnapshotter][init]: Adding WebView to an off-screen container.")
            let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            containerView.clipsToBounds = true  // Ensure content outside this frame is not visible
            webView.frame = CGRect(x: -width, y: 0, width: width, height: height)  // Positioned entirely outside the container view's visible area
            containerView.addSubview(webView)
            keyWindow.addSubview(containerView)  // Minimize the impact on the visible UI
        } else {
            print("[WebViewSnapshotter][init]: Failed to find an active window scene or key window.")
        }
        
        // Load the URL request
        let request = URLRequest(url: url)
        webView.load(request)
        
        print("[WebViewSnapshotter][init]: Initialization completed.")
    }
    
    // Called when the web content has finished loading
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Call the method to take a snapshot of the web content
        print("[WebViewSnapshotter][webView](didFinish)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Adjust delay as necessary
            self.takeSnapshot { [weak self] image in
                self?.completion?(image)
            }
        }
    }
    
    // Called if the web content loading fails
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("[WebViewSnapshotter][webView](withError): \(error.localizedDescription) ---")
        completion?(nil)
    }
    
    // Take a snapshot of the web content
    private func takeSnapshot(completion: @escaping (UIImage?) -> Void) {
        print("[WebViewSnapshotter][takeSnapshot]: Initiating snapshot process.")
        
        let config = WKSnapshotConfiguration()
        // Adjust configuration if necessary (e.g., specifying a specific rect to snapshot)
        // Example: config.rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        print("[WebViewSnapshotter][takeSnapshot]: Snapshot configuration set. Details: \(config)")
        
        webView.takeSnapshot(with: config) { [weak self] image, error in
            // Log the entry into the snapshot completion handler
            print("[WebViewSnapshotter][takeSnapshot]: Entered snapshot completion handler.")
            
            defer {
                // Ensure webView is removed from its parent view in all cases
                DispatchQueue.main.async {
                    print("[WebViewSnapshotter][takeSnapshot]: Removing webView from its parent view.")
                    self?.webView.removeFromSuperview()
                }
            }
            
            if let error = error {
                // Log the error if snapshot failed
                print("[WebViewSnapshotter][takeSnapshot][Error]: Snapshot process failed with an error: \(error.localizedDescription)")
                completion(nil)
            } else if let image = image {
                // Log success and pass the image to the completion handler
                print("[WebViewSnapshotter][takeSnapshot][Success]: Snapshot taken successfully. Image info: Size - \(image.size.width)x\(image.size.height), Scale - \(image.scale)")
                completion(image)
            } else {
                // Log when there is no error but the snapshot returns a nil image
                print("[WebViewSnapshotter][takeSnapshot][Error]: Snapshot process completed but returned a nil image.")
                completion(nil)
            }
        }
    }

}

