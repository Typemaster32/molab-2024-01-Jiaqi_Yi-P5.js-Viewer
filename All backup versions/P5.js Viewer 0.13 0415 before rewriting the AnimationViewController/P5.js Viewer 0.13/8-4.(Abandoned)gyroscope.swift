import Foundation
import CoreMotion
import SwiftUI

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var mouseX: CGFloat = UIScreen.main.bounds.width / 2
    @Published var mouseY: CGFloat = UIScreen.main.bounds.height / 2
    var isTracking = false
    
    func startUpdates() {
        guard !isTracking else { return }
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
                guard let strongSelf = self, let motion = motion else { return }
                DispatchQueue.main.async {
                    // Assuming rotationRate is used to simulate acceleration
                    let sensitivity: CGFloat = 10.0 // Adjust based on testing
                    strongSelf.mouseX += CGFloat(motion.rotationRate.x) * sensitivity
                    strongSelf.mouseY += CGFloat(motion.rotationRate.y) * sensitivity
                    
                    // Keep the "mouse" within screen bounds
                    strongSelf.mouseX = min(max(strongSelf.mouseX, 0), UIScreen.main.bounds.width)
                    strongSelf.mouseY = min(max(strongSelf.mouseY, 0), UIScreen.main.bounds.height)
                }
            }
            isTracking = true
        }
    }
    
    func stopUpdates() {
        if isTracking {
            motionManager.stopDeviceMotionUpdates()
            isTracking = false
        }
    }
}
