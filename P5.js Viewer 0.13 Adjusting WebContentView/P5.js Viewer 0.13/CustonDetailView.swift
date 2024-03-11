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
            Text("1. Sound")
                .font(.subheadline)
            Text("Currently, due to browser privacy settings, the sound library does not cooperate with mobile browser \n- *<script src=\"https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.1.9/addons/p5.sound.min.js\"></script>*")
                .font(.body)
            Text("2. Mouse")
                .font(.subheadline)
            Text("Mouse functions are disabled due to touchscreen interaction, and MouseX and MouseY remains 0 here ")
                .font(.body)
            Text("3. Keyboard")
                .font(.subheadline)
            Text("Keyboard functions are disabled here. Please use web editor on computers")
                .font(.body)
            Text("4. External Media Files / Links")
                .font(.subheadline)
            Text("Due to pravicy settings, any external file or link is by default disabled")
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
