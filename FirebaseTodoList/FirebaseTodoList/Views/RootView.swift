import SwiftUI

/// Root view determining navigation hierarchy based on Firebase Authentication state.
struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                TodoListView()
                    .transition(.opacity.combined(with: .scale))
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authViewModel.isAuthenticated)
    }
}
