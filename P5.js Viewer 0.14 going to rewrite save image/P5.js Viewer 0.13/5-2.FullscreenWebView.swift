import SwiftUI

struct FullScreenWebView: View {
    @Environment(\.presentationMode) var presentationMode
    var sourceURL: URL
    
    var body: some View {
        ZStack {
            WebView(url: sourceURL)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    self.presentationMode.wrappedValue.dismiss()
                }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}
