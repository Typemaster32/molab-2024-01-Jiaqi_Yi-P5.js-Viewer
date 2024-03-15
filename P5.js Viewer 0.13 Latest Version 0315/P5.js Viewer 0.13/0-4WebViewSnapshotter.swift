import Foundation
import WebKit
import UIKit
// This is the former version


class WebViewSnapshotter: NSObject, WKNavigationDelegate {
    var webView: WKWebView!
    var completion: ((UIImage?) -> Void)?
    var width: Int
    var height: Int
    
    
    init(url: URL, width:Int, height:Int, completion: @escaping (UIImage?) -> Void) {
        //CAUTION: it uses URL towards index.html
        print("--- WebViewSnapshotter -> init (starting) ---")
        self.width = width
        self.height = height
        super.init()
        // Create a WKWebView instance and set its navigation delegate
        webView = WKWebView()
//        webView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        
        if let windowScene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .first as? UIWindowScene,
           let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
            let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            containerView.clipsToBounds = true  // Ensure content outside this frame is not visible
            webView.frame = CGRect(x: -width, y: 0, width: width, height: height)  // Positioned entirely outside the container view's visible area
            containerView.addSubview(webView)
            keyWindow.addSubview(containerView)  // Minimize the impact on the visible UI
        }
        
        
        webView.navigationDelegate = self
        
        self.completion = completion
        
        // Load the URL request
        let request = URLRequest(url: url)
        print(request)
        webView.load(request)
        print("--- WebViewSnapshotter -> init (ending) ---")
    }
    
    // Called when the web content has finished loading
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Call the method to take a snapshot of the web content
        print("--- WebViewSnapshotter -> webView (didFinish) ---")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Adjust delay as necessary
            self.takeSnapshot { [weak self] image in
                self?.completion?(image)
            }
        }
    }
    
    // Called if the web content loading fails
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("--- WebViewSnapshotter -> webView (withError) -> \(error.localizedDescription) ---")
        completion?(nil)
    }
    
    // Take a snapshot of the web content
    private func takeSnapshot(completion: @escaping (UIImage?) -> Void) {
        print("--- WebViewSnapshotter -> takeSnapshot ---")
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
                print("Snapshot is taken successfully")
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
    
    func saveImage(_ image: UIImage, compress: Bool = false, toURL url: URL? = nil) {
        print("--- WebViewSnapshotter -> saveImage -> 5. Trying to Save ---")
        
        // If a URL is provided, handle saving a thumbnail there.
        if let url = url, compress {
            // Compress and save the image to the provided URL.
            DispatchQueue.global(qos: .background).async {
                guard let imageToSave = image.resized(withPercentage: 0.2) else {
                    print("Unable to resize image.")
                    return
                }
                
                // Assuming JPEG format and a compression quality of 0.8
                if let imageData = imageToSave.jpegData(compressionQuality: 0.8) {
                    do {
                        try imageData.write(to: url)
                        print("Thumbnail image saved successfully to URL: \(url)")
                    } catch {
                        print("Error saving thumbnail image to URL: \(error)")
                    }
                }
            }
        } else {
            // Save the original image to the photo album without compression.
            DispatchQueue.main.async {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        print("--- WebViewSnapshotter -> saveImage -> @objc func image ---")
        if let error = error {
            print("Error saving image: \(error.localizedDescription)")
        } else {
            print("Image saved successfully to the photo album")
        }
    }
}



// This is in charge of put the image into photo album

extension UIImage {
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: size.width * percentage, height: size.height * percentage)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, self.scale)
        defer { UIGraphicsEndImageContext() }
        self.draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}


//class ImageSaver: NSObject {
//    static let shared = ImageSaver()
//
//    func saveImage(_ image: UIImage) {
//        print("--- WebViewSnapshotter -> saveImage -> 5. Trying to Save ---")
//        DispatchQueue.main.async {
//            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
//        }
//    }
//
//
//    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
//        print("--- WebViewSnapshotter -> saveImage -> @objc func image ---")
//        if let error = error {
//            print("Error saving image: \(error.localizedDescription)")
//        } else {
//            print("6. Image saved successfully")
//        }
//    }
//}
