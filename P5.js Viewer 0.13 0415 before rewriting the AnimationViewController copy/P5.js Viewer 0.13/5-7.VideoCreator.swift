import UIKit
import AVFoundation
import Photos

class VideoCreator {
    var assetWriter: AVAssetWriter?
    var videoInput: AVAssetWriterInput?
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    var frameTime: CMTime = CMTime.zero
    
    var videoURL: URL?
    var imageURL: URL?
    
    init(name: String) {
        print("[VideoCreator][init]: Initialized with name: \(name)")
        setupVideoPath(named: name)
    }
    
    func setupVideoPath(named videoName: String) {
        print("[VideoCreator][setupVideoPath]: Setting up video path with name: \(videoName)")
        let outputPath = "\(NSTemporaryDirectory())\(videoName).mov"
        videoURL = URL(fileURLWithPath: outputPath)  // Ensure videoURL is set here for later use
        
        do {
            try FileManager.default.removeItem(at: videoURL!)
        } catch {
            print("[VideoCreator][setupVideoPath]: Could not remove old video file: \(error)")
        }
        
        do {
            assetWriter = try AVAssetWriter(url: videoURL!, fileType: .mov)
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 400,  // Width in pixels
                AVVideoHeightKey: 150  // Height in pixels
            ]
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            let sourcePixelBufferAttributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: 400,
                kCVPixelBufferHeightKey as String: 150,
                kCVPixelBufferMetalCompatibilityKey as String: true
            ]
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: videoInput!,
                sourcePixelBufferAttributes: sourcePixelBufferAttributes
            )
            assetWriter!.add(videoInput!)
            assetWriter!.startWriting()
            assetWriter!.startSession(atSourceTime: .zero)
        } catch let error {
            print("[VideoCreator][setupVideoPath]: Error creating AVAssetWriter: \(error)")
        }
    }
    
    func addImageToVideo(image: UIImage) {
        print("[VideoCreator][addImageToVideo]: Adding image to video")
        guard let writer = videoInput, writer.isReadyForMoreMediaData, let buffer = image.toBuffer() else {
            print("[VideoCreator][addImageToVideo]: Failed to prepare data for writing")
            return
        }
        
        let frameDuration = CMTime(value: 1, timescale: 10)  // 10 frames per second
        let lastFrameTime = frameTime
        frameTime = lastFrameTime + frameDuration
        
        pixelBufferAdaptor?.append(buffer, withPresentationTime: lastFrameTime)
    }
    
    func finalizeVideo(completion: @escaping () -> Void) { // Stops getting new images
        print("[VideoCreator][finalizeVideo]: Finalizing video")
        videoInput?.markAsFinished()
        assetWriter?.finishWriting {
            print("[VideoCreator][finalizeVideo]: Video is finished and saved at \(self.assetWriter?.outputURL.path ?? "unknown path")")
            completion()
        }
    }
    
    func generateThumbnail(completion: @escaping (URL?) -> Void) { // get the first frame as jpeg
        print("[VideoCreator][generateThumbnail]: Generating thumbnail")
        guard let videoURL = self.videoURL else {
            print("[VideoCreator][generateThumbnail]: Video URL is missing")
            completion(nil)
            return
        }
        
        let asset = AVAsset(url: videoURL)
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.0, preferredTimescale: 600)
        
        do {
            let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            let thumbnail = UIImage(cgImage: img)
            if let data = thumbnail.jpegData(compressionQuality: 0.8) {
                let imageURL = URL(fileURLWithPath: "\(NSTemporaryDirectory())thumbnail.jpg")
                try data.write(to: imageURL)
                self.imageURL = imageURL
                completion(imageURL)
            } else {
                completion(nil)
            }
        } catch {
            print("[VideoCreator][generateThumbnail]: Error generating thumbnail: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    func createLivePhoto(completion: @escaping (PHLivePhoto?) -> Void) { // make them a live photo
        print("[VideoCreator][createLivePhoto]: Creating Live Photo")
        guard let videoURL = self.videoURL, let imageURL = self.imageURL else {
            print("[VideoCreator][createLivePhoto]: Video or Image URL is missing")
            completion(nil)
            return
        }
        
        PHLivePhoto.request(withResourceFileURLs: [videoURL, imageURL],
                            placeholderImage: nil,
                            targetSize: CGSize.zero,
                            contentMode: .aspectFit) { livePhoto, infoDict in
            if let livePhoto = livePhoto {
                print("[VideoCreator][createLivePhoto]: Live Photo created successfully")
                completion(livePhoto)
            } else {
                print("[VideoCreator][createLivePhoto]: Failed to create Live Photo: \(infoDict)")
                completion(nil)
            }
        }
    }
    
    
    func completeVideoProcess(completion: @escaping (Bool, String) -> Void) { // Run the three funcs above
        finalizeVideo {
            print("[VideoCreator][completeVideoProcess]:Video has been finalized.")
            self.generateThumbnail { thumbnailURL in
                guard let thumbnailURL = thumbnailURL else {
                    completion(false, "[VideoCreator][completeVideoProcess]:Failed to generate thumbnail.")
                    return
                }
                self.imageURL = thumbnailURL
                print("[VideoCreator][completeVideoProcess]:Thumbnail generated at: \(thumbnailURL.path)")
                
                self.createLivePhoto { livePhoto in
                    guard let livePhoto = livePhoto else {
                        completion(false, "[VideoCreator][completeVideoProcess]:Failed to create Live Photo.")
                        return
                    }
                    print("[VideoCreator][completeVideoProcess]:Live Photo created successfully.")
                    
                    // Optionally, save the Live Photo to the photo album
                    self.saveLivePhoto(livePhoto, completion: completion)
                }
            }
        }
    }
    
    /// Saves the Live Photo to the user's photo album.
    /// Saves the Live Photo to the user's photo album.
    private func saveLivePhoto(_ livePhoto: PHLivePhoto, completion: @escaping (Bool, String) -> Void) {
        // Check for Photos library access permission and request if not already granted
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    completion(false, "[VideoCreator][saveLivePhoto]:Photo Library access is denied by the user.")
                }
                return
            }
            
            // Perform the save operation
            PHPhotoLibrary.shared().performChanges({
                // Create a Live Photo asset request
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, fileURL: self.imageURL!, options: nil)
                if let videoURL = self.videoURL {
                    creationRequest.addResource(with: .pairedVideo, fileURL: videoURL, options: nil)
                }
            }, completionHandler: { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(true, "[VideoCreator][saveLivePhoto]:Live Photo saved to the album.")
                    } else {
                        completion(false, "[VideoCreator][saveLivePhoto]:Failed to save Live Photo: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            })
        }
    }

}




extension UIImage {
        func toBuffer() -> CVPixelBuffer? {
            let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                 kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
            var pixelBuffer: CVPixelBuffer?
            let width = Int(self.size.width)
            let height = Int(self.size.height)
            let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                             width,
                                             height,
                                             kCVPixelFormatType_32ARGB,
                                             attrs,
                                             &pixelBuffer)
            
            if status != kCVReturnSuccess {
                return nil
            }
            
            CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
            let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
            
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: pixelData,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
                                    space: rgbColorSpace,
                                    bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
            
            context?.translateBy(x: 0, y: CGFloat(height))
            context?.scaleBy(x: 1.0, y: -1.0)
            
            UIGraphicsPushContext(context!)
            self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            UIGraphicsPopContext()
            CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
            
            return pixelBuffer
        }
}



