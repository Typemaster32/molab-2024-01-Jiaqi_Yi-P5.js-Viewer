import SwiftUI
import FirebaseCore
import FirebaseAnalytics

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        Analytics.setAnalyticsCollectionEnabled(false)
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        return true
    }
}


@main
struct P5_js_Viewer_0_13App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}




//More to do:
//Manually (windowWidth,windowHeight)
//Displaying the labels
//Tapping are now still magnifying!
//disable downloading; Delete console.log();
// URL session (make a url request)
// https://editor.p5js.org/YiJiaqi/sketches/rmPFWh6Ou/zip
// https://editor.p5js.org/editor/${my.user_name}/projects
// https://editor.p5js.org/editor/YiJiaqi/projects
// https://editor.p5js.org/editor/projects/L-7h--MYf/zip
// https://editor.p5js.org/editor/projects/\(id)/zip
// L-7h--MYf
// threads
// ios api for snapshot wkwv
// 1. (p5js) framerate / completion callback
// 2. (swift) ios api for snapshot wkwv


// Big Stuff:
// 1. Save Animation
// 2. Touch Interaction / Wake Keyboard
// 3. Resize the canvas to fit viewport （TOO HARD）(ZOOMing has a bug)
// 4. Handle Fullscreen to stop
// 5. Save My Collection
// 6. Examples Refreshes (DONE)
// 7. More Tags
// 8. Ban downloads (ALMOST DONE)
// 9. Go to p5.web editor
