import UIKit
import FirebaseCore

/// Application Delegate ensuring Firebase core initialization before any SwiftUI views render.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure Firebase SDK with GoogleService-Info.plist
        // Check if Firebase is already configured (prevents duplicate configure calls during previews/tests)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("Successfully configured Firebase iOS SDK.")
        }
        return true
    }
}
