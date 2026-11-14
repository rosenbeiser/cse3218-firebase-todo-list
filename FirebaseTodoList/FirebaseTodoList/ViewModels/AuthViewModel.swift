import Foundation
import FirebaseAuth
import Combine

/// ViewModel managing Authentication UI state, form inputs, validation, and actions.
@MainActor
final class AuthViewModel: ObservableObject {
    // Input fields
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    
    // UI state
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showErrorAlert: Bool = false
    
    private let authService = AuthService.shared
    
    var currentUser: User? {
        authService.currentUser
    }
    
    var isAuthenticated: Bool {
        authService.isAuthenticated
    }
    
    // MARK: - Validation
    
    var isLoginFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        password.count >= 6
    }
    
    var isRegistrationFormValid: Bool {
        isValidEmail(email) &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    // MARK: - Authentication Actions
    
    func login() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            showError("Please fill in both email and password.")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await authService.signIn(email: trimmedEmail, password: password)
            clearInputs()
            isLoading = false
        } catch {
            isLoading = false
            showError(error.localizedDescription)
        }
    }
    
    func register() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard isValidEmail(trimmedEmail) else {
            showError("Please enter a valid email address.")
            return
        }
        
        guard password.count >= 6 else {
            showError("Password must be at least 6 characters.")
            return
        }
        
        guard password == confirmPassword else {
            showError("Passwords do not match. Please re-enter your password.")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await authService.signUp(email: trimmedEmail, password: password)
            clearInputs()
            isLoading = false
        } catch {
            isLoading = false
            showError(error.localizedDescription)
        }
    }
    
    func signOut() {
        do {
            try authService.signOut()
            clearInputs()
        } catch {
            showError("Sign out failed: \(error.localizedDescription)")
        }
    }
    
    func clearInputs() {
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = nil
        showErrorAlert = false
    }
    
    private func showError(_ message: String) {
        self.errorMessage = message
        self.showErrorAlert = true
    }
}
