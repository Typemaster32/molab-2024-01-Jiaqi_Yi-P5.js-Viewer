import SwiftUI
import WebKit
import ZIPFoundation
import UIKit

//By ChatGPT, modified
struct WebView: UIViewRepresentable {
    var url: URL
    var videoCreator: VideoCreator? = nil
    
    private let webView = WKWebView()   // Reference to WKWebView for direct access
    
    func refresh() {
                print("[WebView][refresh]")
        webView.reload()
    }
    
//    func makeUIView(context: Context) -> WKWebView {
//        print("[WebView][makeUIView]: url: \(url)")
//        webView.scrollView.showsVerticalScrollIndicator = false
//        webView.scrollView.showsHorizontalScrollIndicator = false
//        self.webView.isInspectable = true;
//        let webConfiguration = WKWebViewConfiguration()
//        let userContentController = WKUserContentController()
//        userContentController.add(context.coordinator, name: "p5js_viewer")
//        webConfiguration.userContentController = userContentController
//        webView.configuration = webConfiguration
//        setupSnapshotListener() // Setup the listener when the view is created
//        return webView
//    }
    
    func makeUIView(context: Context) -> WKWebView {
        print("[WebView][makeUIView]: url: \(url)")
        
            // Create and configure the user content controller
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "p5js_viewer")
        
            // Create the web configuration and assign the user content controller
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = userContentController
        
            // Initialize the WKWebView with the configuration
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.isInspectable = true
        
        setupSnapshotListener() // Setup the listener when the view is created
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        print("[WebView][updateUIView]")
        guard context.coordinator.lastLoadedURL != url else { return }
        uiView.load(URLRequest(url: url))
        context.coordinator.lastLoadedURL = url //prevent frequent refreshing
    }
    
    func setupSnapshotListener() {
        print("[WebView][setupSnapshotListener]")
        NotificationCenter.default.addObserver(forName: .takeWebViewSnapshot, object: nil, queue: .main) { _ in
            self.getCanvasImage { image in
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
        Coordinator(self,  videoCreator: videoCreator) {
            // Define the completion action here. This will be called when the image count reaches max.
            print("[WebView][videoCreator][completion] All images processed, executing completion tasks.")
            DispatchQueue.main.async {
                self.webView.stopLoading()
                self.webView.removeFromSuperview()
                // Additional cleanup and notification logic as needed.
                // it is here to continue in video creator
            }
        }
    }
    
        // Function to call the JavaScript and handle the returned Base64 image data
    func getCanvasImage(completion: @escaping (UIImage?) -> Void) {
        webView.evaluateJavaScript(insertedJSCodeForSaveImage) { result, error in
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
    
    // Coordinator class
    class Coordinator: NSObject, WKNavigationDelegate,WKScriptMessageHandler {
        var parent: WebView
        var lastLoadedURL: URL?
        var maxImages = 59
        var countImages = 0
        var videoCreator: VideoCreator?
        var onCompletion: (() -> Void)? // Closure to be called on completion
        
        init(_ webView: WebView, videoCreator: VideoCreator?=nil, completion: @escaping () -> Void) {
            self.parent = webView
            self.videoCreator = videoCreator
            self.onCompletion = completion
            if videoCreator == nil{
                print("[WebView][Coordinator]: Initialized for WebView.")
            } else {
                print("[WebView][Coordinator]: Initialized for WebView with a VideoCreator. ")
            }
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
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if countImages <= maxImages, message.name == "p5js_viewer", let messageBody = message.body as? String {
                countImages += 1
                print("[webView][Coordinator][userContentController]: Received base64 string from JS: No. \(countImages)")
                // Handle the base64 string here, such as converting it to UIImage
                // when it reaches maximum, have a callback to terminate itself and notify SaveAnimation through a callback.
                processImage(base64: messageBody)
                
//                if countImages > maxImages { // pay special attention here. it is > instead of >=
//                    print("[webView][Coordinator][userContentController]:Reaching Maximum")
//                    if let vc = videoCreator{
//                        finalizeCreationAndCleanup()
//                        vc.finalizeVideo() {
//                            print("[webView][Coordinator][userContentController]:Video finalization complete.")
//                        }
//                    } else{
//                        print("[webView][Coordinator][userContentController]: video creator is nil")
//                    }
//                    onCompletion?()
//                }
            }
        }
        func processImage(base64: String) { // Take images, and end if reaching 180
            if let image = decodeImage(from: base64),let vc = videoCreator {
                print("[webView][Coordinator][ProcessImage][Success]: Image decoded successfully.")
                vc.addImageToVideo(image: image)
            } else {
                print("[webView][Coordinator][ProcessImage][Error]: Failed to decode image from base64 string.")
            }
        }
        
        func decodeImage(from base64String: String) -> UIImage? {
            var base64String = base64String
                // This removes the prefix if it exists.
            if base64String.contains(",") {
                base64String = base64String.components(separatedBy: ",").last ?? ""
            }
            
            guard let imageData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters),
                  let image = UIImage(data: imageData) else {
                return nil
            }
            return image
        }

        
        func finalizeCreationAndCleanup() { // It finalizes the video, not the live photo
            if let vc = videoCreator{
                vc.completeVideoProcess { success, message in
                    if success {
                        print("Success: \(message)")
                    } else {
                        print("Error: \(message)")
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


