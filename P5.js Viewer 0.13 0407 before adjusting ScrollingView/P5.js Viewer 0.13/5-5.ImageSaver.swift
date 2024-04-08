import Foundation
import WebKit
import UIKit


class ImageSaver: NSObject { // This is saving the photo, preview and thumbnail
    static let shared = ImageSaver()
    
    // Enhanced saveImage method to include a resize option for saving a preview image.
    // Enhanced saveImage method to include a resize option for saving a preview image.
    func saveImage(_ image: UIImage, compress: Bool = false, toURL url: URL? = nil, resizeToWidth width: CGFloat? = nil, completion: ((Bool, Error?) -> Void)? = nil) {
        print("[ImageSaver][saveImage]:Started")
//        print("[ImageSaver][saveImage]:toURL: \(String(describing: url))")
        if let url = url {
            DispatchQueue.global(qos: .background).async {
                var imageToSave = image
                
                // Resize the image if a specific width is provided and maintain the aspect ratio.
                if let width = width {
//                    _ = image.size.height / image.size.width
//                    let resizedHeight = width * aspectRatio
                    imageToSave = image.resized(toWidth: width) ?? image // Fallback to original if resize fails.
                }
                
                // Compress if required, otherwise save the resized image directly.
                let imageData = compress ? imageToSave.jpegData(compressionQuality: 0.8) : imageToSave.pngData()
                
                if let imageData = imageData {
                    do {
                        try imageData.write(to: url)
                        print("[ImageSaver][saveImage]:Image saved successfully")
//                        print("[ImageSaver][saveImage]:Image saved successfully to URL: \(url)")
                        completion?(true, nil) // Call completion with success and no error
                    } catch {
                        print("[ImageSaver][saveImage]:Error saving image to URL: \(error)")
                        completion?(false, error) // Call completion with failure and an error
                    }
                } else {
                    completion?(false, nil) // No imageData could be generated, calling completion with failure
                }
            }
        } else {
            DispatchQueue.main.async {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
                // The callback for photo album save is handled separately in the 'image' method.
            }
        }
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("\(red)[ImageSaver][@objc private func image]:Error saving image: \(error.localizedDescription)")
        } else {
            print("[ImageSaver][@objc private func image]:Image saved successfully to the photo album")
        }
    }
}

extension UIImage {
    // Resizes the image to a specified width while maintaining the aspect ratio.
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

