import SwiftUI
import UIKit

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct LoadingView: View {
    var onCancel: (() -> Void)?
    
    var body: some View {
        ZStack {
            BlurView(style: .systemMaterial) // Custom blur view using UIViewRepresentable
            VStack {
                ProgressView("Loading...")
                Button("Cancel", action: onCancel ?? {})
            }
        }
    }
}
