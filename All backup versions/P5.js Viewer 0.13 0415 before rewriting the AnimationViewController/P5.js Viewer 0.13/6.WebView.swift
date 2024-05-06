import SwiftUI
import WebKit
import ZIPFoundation
import UIKit

    //By ChatGPT, modified
struct WebView: UIViewRepresentable {
    
    
    var url: URL
    @StateObject var store = WebViewStore()  // Now WebView controls the lifecycle
    
    private let webView = WKWebView()   // Reference to WKWebView for direct access
    
    func refresh() {
        print("[WebView][refresh]")
        webView.reload()
    }
    
    func makeUIView(context: Context) -> WKWebView {
        print("[WebView][makeUIView]: url: \(url)")
        let webConfiguration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.isInspectable = true
        webView.navigationDelegate = context.coordinator
        
        DispatchQueue.main.async {  // Ensure assignment does not trigger view update directly
            self.store.webView = webView
            self.store.coordinator = context.coordinator
        }
        
        setupSnapshotListener() // Setup the listener when the view is created
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
            print("[WebView][updateUIView]: Triggered")
            uiView.load(URLRequest(url: url))
        } else{
            print("[Not Triggered][WebView][updateUIView]")
        }
    }
    
    func setupSnapshotListener() {
        print("[WebView][setupSnapshotListener]")
        NotificationCenter.default.addObserver(forName: .takeWebViewSnapshot, object: nil, queue: .main) { _ in
                //            self.captureCanvasImage { image in
                //                // Here you can handle the snapshot image
                //                // For example, save it to the photo library
                //                if let image = image {
                //                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                //                }
                //            }
        }
    }
    
        // Snapshot function accessible from SwiftUI
    func takeSnapshot(completion: @escaping (UIImage?) -> Void) {
        print("[WebView][takeSnapshot]: Initiated snapshot capture.")
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
        Coordinator(self)
    }
        // Coordinator class
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ webView: WebView) {
            self.parent = webView
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            print("[WebView][Coordinator][decidePolicyFor]: Evaluating navigation action.")
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
        
        func captureCanvasImage(webView: WKWebView, completion: @escaping (UIImage?) -> Void) {
            let javascript = """
            var canvas = document.querySelector('canvas');
            canvas ? canvas.toDataURL('image/png') : '';
            """
            webView.evaluateJavaScript(javascript) { result, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("JavaScript execution error: \(error)")
                        completion(nil)
                        return
                    }
                    if let base64String = result as? String, !base64String.isEmpty {
                        let cleanBase64String = base64String.replacingOccurrences(of: "data:image/png;base64,", with: "")
                        if let imageData = Data(base64Encoded: cleanBase64String) {
                            let image = UIImage(data: imageData)
                            completion(image)
                        } else {
                            completion(nil)
                        }
                    } else {
                        completion(nil)
                    }
                }
            }
        }
    }
}

    //By ChatGPT, exclusively
extension Notification.Name {
    static let takeWebViewSnapshot = Notification.Name("takeWebViewSnapshotNotification")
}



let insertedJSCodeForSaveImage = """
    var canvas = document.querySelector('canvas');
    return canvas ? canvas.toDataURL('image/png') : '';
"""


class WebViewStore: ObservableObject {
    @Published var webView: WKWebView? = nil
    var coordinator: WebView.Coordinator?
}
