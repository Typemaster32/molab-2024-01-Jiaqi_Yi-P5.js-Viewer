import SwiftUI

    // Define an animatable data structure for the transformation
struct AnimatableLineToCircle: Shape {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
            // Interpolate width from full width to smaller width for the circle
        let effectiveWidth = rect.width * (1 - 0.8 * progress) // Circle becomes 50% width of the line
        
            // Height adjusts from initial 5 to the full width of the circle
        let height = 5 + (effectiveWidth - 5) * progress
        
            // Corner radius for smooth transition from line to circle
        let cornerRadius = height / 2
        
            // X position starts from the right edge and moves leftwards as it becomes a circle
        let xPos = rect.width - effectiveWidth
        
        return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .path(in: CGRect(x: xPos, y: rect.midY - height / 2, width: effectiveWidth, height: height))
    }

}

struct TestPage: View {
    @State private var animate = false
    
    var body: some View {
        VStack {
            Spacer()
            GeometryReader { geometry in
                AnimatableLineToCircle(progress: animate ? 1 : 0)
                    .stroke(Color.blue, lineWidth: 5)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 2)) {
                            self.animate.toggle()
                        }
                    }
            }
            Spacer()
        }
    }
}


#Preview {
    TestPage()
}
