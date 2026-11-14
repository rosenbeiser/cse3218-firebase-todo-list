import SwiftUI

/// Main entry point for the Firebase Integrated Todo List Application.
@main
struct FirebaseTodoListApp: App {
    // Connect UIKit AppDelegate for Firebase configuration
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Instantiate top-level ViewModels shared via environment
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var todoViewModel = TodoViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(todoViewModel)
        }
    }
}
