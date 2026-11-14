import Foundation
import FirebaseAuth
import Combine

/// Service layer responsible for all Firebase Authentication operations.
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    private init() {
        // Register Firebase Auth listener for real-time authentication state updates
        self.authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = (user != nil)
            }
        }
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    /// Registers a new user with Email and Password
    func signUp(email: String, password: String) async throws -> User {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.currentUser = result.user
            self.isAuthenticated = true
            return result.user
        } catch {
            throw mapAuthError(error)
        }
    }
    
    /// Signs in an existing user with Email and Password
    func signIn(email: String, password: String) async throws -> User {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.currentUser = result.user
            self.isAuthenticated = true
            return result.user
        } catch {
            throw mapAuthError(error)
        }
    }
    
    /// Signs out the currently logged in user
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            self.isAuthenticated = false
        } catch {
            throw mapAuthError(error)
        }
    }
    
    /// Maps low-level Firebase Auth errors into clear, friendly error messages for students/users
    private func mapAuthError(_ error: Error) -> Error {
        let nsError = error as NSError
        guard nsError.domain == AuthErrorDomain else {
            return error
        }
        
        let message: String
        if let code = AuthErrorCode.Code(rawValue: nsError.code) {
            switch code {
            case .invalidEmail:
                message = "The email address format is invalid. Please check and try again."
            case .emailAlreadyInUse:
                message = "This email is already registered. Please sign in instead."
            case .wrongPassword:
                message = "Incorrect email or password. Please verify your credentials."
            case .userNotFound:
                message = "No account found with this email. Please register first."
            case .weakPassword:
                message = "Password must be at least 6 characters long."
            case .networkError:
                message = "Network error. Please check your internet connection."
            case .userDisabled:
                message = "This account has been disabled. Please contact support."
            case .tooManyRequests:
                message = "Too many failed attempts. Please try again after a few minutes."
            default:
                if nsError.code == 17004 || nsError.code == 17009 {
                    message = "Incorrect email or password. Please verify your credentials."
                } else {
                    message = error.localizedDescription
                }
            }
        } else if nsError.code == 17004 || nsError.code == 17009 {
            message = "Incorrect email or password. Please verify your credentials."
        } else {
            message = error.localizedDescription
        }
        
        return NSError(domain: "AuthService", code: nsError.code, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
