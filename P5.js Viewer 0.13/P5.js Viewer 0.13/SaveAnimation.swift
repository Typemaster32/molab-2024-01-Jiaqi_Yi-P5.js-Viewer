import UIKit
import WebKit

class SaveAnimation: UIViewController {
    var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup WKWebView (not shown for brevity; see previous examples)
        
        // Example: Setup UI Buttons for control (not fully implemented)
        let startButton = UIButton(frame: CGRect(x: 50, y: 100, width: 100, height: 50))
        startButton.backgroundColor = .blue
        startButton.setTitle("Start", for: .normal)
        startButton.addTarget(self, action: #selector(startCapture), for: .touchUpInside)
        view.addSubview(startButton)
        
        let stopButton = UIButton(frame: CGRect(x: 200, y: 100, width: 100, height: 50))
        stopButton.backgroundColor = .red
        stopButton.setTitle("Stop", for: .normal)
        stopButton.addTarget(self, action: #selector(stopCapture), for: .touchUpInside)
        view.addSubview(stopButton)
    }
    
    @objc func startCapture() {
        webView.evaluateJavaScript("startCapture()", completionHandler: { (result, error) in
            if let error = error {
                print("Error starting capture: \(error.localizedDescription)")
            }
        })
    }
    
    @objc func stopCapture() {
        webView.evaluateJavaScript("stopCapture()", completionHandler: { (result, error) in
            if let error = error {
                print("Error stopping capture: \(error.localizedDescription)")
            }
        })
    }
}



// To save as animation, you have to:
// 1. Slow it down with frameRate() to setup(); (Optional)
// 2. Inject saveQueue() and processQueue() to draw();
// 3. Attach saveQueue() and processQueue();

//import SwiftUI
//
//struct SaveAnimation: View {
//    var body: some View {
//        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
//    }
//}
