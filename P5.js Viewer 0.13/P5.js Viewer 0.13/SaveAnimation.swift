import Foundation
import WebKit
import UIKit

class SaveAnimation: NSObject, WKNavigationDelegate {
    var webView: WKWebView!
    var completion: (() -> Void)?
    
    // Initialize with a URL and a completion handler for after stopCapture() is called
    init(url: URL, completion: (() -> Void)? = nil) {
        super.init()
        webView = WKWebView()
        
        // Set up the webView off-screen or invisibly as in WebViewSnapshotter example
        if let windowScene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .first as? UIWindowScene,
           let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
            let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            containerView.clipsToBounds = true
            webView.frame = CGRect(x: 500, y: 0, width: 500, height: 500) // Positioned off-screen
            containerView.addSubview(webView)
            keyWindow.addSubview(containerView)
        }
        
        webView.navigationDelegate = self
        self.completion = completion
        
        // Load the URL
        let request = URLRequest(url: url)
        webView.load(request)
        print("SaveAnimation Initiated")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("WebView content loaded, starting capture.")
        // Start the capture
        startCapture {
            // Wait for 3 seconds then stop capture
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.stopCapture()
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Web content loading failed: \(error.localizedDescription)")
    }
    
    // Method to start capture
    private func startCapture(completion: @escaping () -> Void) {
        webView.evaluateJavaScript("startCapture()") { result, error in
            if let error = error {
                print("Error starting capture: \(error)")
            } else if let result = result {
                print("Capture started with result: \(result)")
            } else {
                print("Capture started with no result and no error.")
                completion()
            }
        }
    }
    
    // Method to stop capture
    private func stopCapture() {
        webView.evaluateJavaScript("stopCapture()") { result, error in
            if let error = error {
                print("Error stopping capture: \(error)")
            } else if let result = result {
                print("Capture stopped with result: \(result)")
            } else {
                print("Capture stopped with no result and no error.")
                // Call the completion handler if set
                self.completion?()
                // Ensure webView is removed from its parent view
                DispatchQueue.main.async {
                    self.webView.removeFromSuperview()
                }
            }
        }
    }

}
