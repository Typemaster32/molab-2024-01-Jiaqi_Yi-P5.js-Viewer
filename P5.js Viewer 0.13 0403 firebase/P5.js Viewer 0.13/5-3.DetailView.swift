//
//  CustonDetailView.swift
//  P5.js Viewer 0.13
//
//  Created by Jiaqi Yi on 3/11/24.
//

import SwiftUI

struct CustomDetailView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("**Display Information**")
                .font(.title)
                .bold()
            
            Text("0. Naming of the files")
                .font(.subheadline)
            Text("To use P5 Viewer, you have to use some of the default name settings in your sketch, which includes: \n\n- **index.html**\n- *single canvas*\n-")
            Text("1. No Sound?")
                .font(.subheadline)
            Text("Currently, due to browser privacy settings, the sound library does not cooperate with mobile browser \n- *<script src=\"https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.1.9/addons/p5.sound.min.js\"></script>*")
                .font(.body)
            Text("2. Using Mouse Function?")
                .font(.subheadline)
            Text("Mouse functions are disabled due to touchscreen interaction, and MouseX and MouseY remains 0 here ")
                .font(.body)
            Text("3. Keyboard Interaction?")
                .font(.subheadline)
            Text("Keyboard functions are disabled here. Please use web editor on computers")
                .font(.body)
            Text("4. What about External Media Files / Links")
                .font(.subheadline)
            Text("Due to pravicy settings, any external file or link is by default disabled")
                .font(.body)
            Text("5. Saving a Live Photo")
                .font(.subheadline)
            Text("Saving as a Live Photo relies on \"CCapture\" library of Javascript, which is recording the canvas only and nothing besides. For better performance, it is not encouraged to move and rotate the canvas. \n- Due to the limit of the mobile divices, consider use a smaller canvas size if it runs slow.")
                .font(.body)
//            Text("This is an example of a *custom detail view* where you can apply rich text formatting, including:\n\n- **Bold**\n- *Italic*\n- `Monospaced`")
//                .font(.body)
//                .lineLimit(nil)
//            
//            Text("You can further customize this view to include images, links, or any other SwiftUI views.")
//                .font(.body)
//                .underline()
            
            Spacer()
        }
        .padding()
    }
}


//#Preview {
//    CustonDetailView()
//}


/*
 1.Capture raw frame data in JavaScript without encoding it into a video format.
 1-1: delete comments
 1-2: find the only "function draw"...Or error
 1-3: insert canvas,toDataURL
 
 2.Stream this raw data from JavaScript to Swift using a communication channel like WebSockets or the postMessage method of WKScriptMessageHandler.
 2-1: deploy websocket on both side
 2-2: make completion
 
 3.Convert the raw data into images in Swift, creating individual frames.
 4.Combine these frames into a video, leveraging iOS frameworks such as AVFoundation to produce the final video file.
 5.Make a Live Photo!!!

 */
