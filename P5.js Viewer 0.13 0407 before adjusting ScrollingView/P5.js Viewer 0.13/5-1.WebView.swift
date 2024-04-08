import SwiftUI
import WebKit
import ZIPFoundation
import UIKit

//By ChatGPT, modified
struct WebView: UIViewRepresentable {
    var url: URL
 
    private let webView = WKWebView()   // Reference to WKWebView for direct access
    
    func refresh() {
//        print("[WebView][refresh]")
        webView.reload()
    }
    
    func makeUIView(context: Context) -> WKWebView {
//        print("[WebView][makeUIView]")
        setupSnapshotListener() // Setup the listener when the view is created
        
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        self.webView.isInspectable = true;

        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
//        print("[WebView][updateUIView]")
        guard context.coordinator.lastLoadedURL != url else { return }
        uiView.load(URLRequest(url: url))
        context.coordinator.lastLoadedURL = url //prevent frequent refreshing
    }
    
    func setupSnapshotListener() {
//        print("[WebView][setupSnapshotListener]")
        NotificationCenter.default.addObserver(forName: .takeWebViewSnapshot, object: nil, queue: .main) { _ in
            self.takeSnapshot { image in
                // Here you can handle the snapshot image
                // For example, save it to the photo library
                if let image = image {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                }
            }
        }
    }
    
    // Snapshot function accessible from SwiftUI
    func takeSnapshot(completion: @escaping (UIImage?) -> Void) {
//        print("[WebView][takeSnapshot]: Initiated snapshot capture.")
        let config = WKSnapshotConfiguration()
        // Configure your snapshot here (e.g., specify rect, afterScreenUpdates, etc.)
        
        webView.takeSnapshot(with: config) { image, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[WebView][takeSnapshot]: Snapshot capture failed with error: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                guard let image = image else {
//                    print("[WebView][takeSnapshot]: Snapshot capture failed, no image returned.")
                    completion(nil)
                    return
                }
//                print("[WebView][takeSnapshot]: Snapshot capture successful.")
                completion(image)
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)  // Optionally add a completion handler to log result of saving to Photos.
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
//        print("[WebView][makeCoordinator]: Coordinator creation initiated.")
        return Coordinator(self)
    }
    
    // Coordinator class
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var lastLoadedURL: URL?
        
        init(_ webView: WebView) {
            self.parent = webView
//            print("[WebView][Coordinator]: Initialized for WebView.")
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//            print("[WebView][Coordinator][decidePolicyFor]: Evaluating navigation action.")
            if let url = navigationAction.request.url {
//                print("[WebView][Coordinator][decidePolicyFor]: URL being loaded: \(url.absoluteString)")
                // List of extensions you wish to block
                let blockedExtensions = ["pdf", "zip", "mp3", "doc", "docx", "xls", "xlsx"]
                if blockedExtensions.contains(where: url.pathExtension.lowercased().contains) {
//                    print("[WebView][Coordinator][decidePolicyFor]: Navigation canceled due to blocked file type in URL.")
                    decisionHandler(.cancel)
                    return
                }
            }
//            print("[WebView][Coordinator][decidePolicyFor]: Navigation allowed.")
            decisionHandler(.allow)
        }
    }

}

//By ChatGPT, exclusively
extension Notification.Name {
    static let takeWebViewSnapshot = Notification.Name("takeWebViewSnapshotNotification")
}



