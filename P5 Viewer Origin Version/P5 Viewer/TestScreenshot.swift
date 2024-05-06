//
//  TestScreenshot.swift
//  P5 Viewer
//
//  Created by Jiaqi Yi on 3/5/24.
//


import UIKit
import Photos
import SwiftUI


struct TestScreenshot: View {
    var body: some View {
        VStack {
            Text("Tap the button below to trigger a screenshot.")
                .padding()
            
            Button("Save Screenshot") {
                // Trigger the screenshot action
                saveScreenshot()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    func saveScreenshot() {
        // Placeholder for your screenshot saving logic
        // Actual implementation would depend on your specific needs and platform capabilities
        print("Screenshot triggered")
    }
}

func saveScreenshotOfView(_ view: UIView) {
    // Begin context
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
    guard let context = UIGraphicsGetCurrentContext() else { return }
    view.layer.render(in: context)
    guard let screenshot = UIGraphicsGetImageFromCurrentImageContext() else { return }
    UIGraphicsEndImageContext()
    
    // Save screenshot to Photos
    PHPhotoLibrary.requestAuthorization { status in
        if status == .authorized {
            UIImageWriteToSavedPhotosAlbum(screenshot, nil, nil, nil)
        }
    }
}

#Preview {
    TestScreenshot()
}
