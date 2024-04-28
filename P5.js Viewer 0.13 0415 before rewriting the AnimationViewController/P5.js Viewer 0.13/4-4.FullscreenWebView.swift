import SwiftUI

struct FullScreenWebView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var webViewStore = WebViewStore()

    var sourceURL: URL
    
    var body: some View {
        ZStack {
            WebView(url: sourceURL, store: webViewStore)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    self.presentationMode.wrappedValue.dismiss()
                }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}
