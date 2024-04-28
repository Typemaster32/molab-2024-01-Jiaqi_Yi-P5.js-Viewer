//
//  4-4.SaveAnimationAction.swift
//  P5.js Viewer 0.13
//
//  Created by Jiaqi Yi on 4/15/24.
//

import Foundation


func saveAnimationAction() {
    // AnimationViewController is in charge of everything
    print("-------------------------Save Animation")
    
    if let unzippedURL = unzippedContentURL {
        let originalFolderURL = unzippedURL.deletingLastPathComponent()
        let animationController = AnimationViewController(sketchTitle: title, author: author, folderURL: originalFolderURL)
        animationController.saveAnimationAction()
    } else {
        print("Unzipping Failed")
    }
    
    
}
