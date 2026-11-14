import Foundation

/// Represents an authenticated user profile in the application.
struct AppUser: Identifiable, Codable, Equatable {
    let id: String
    let email: String
    var displayName: String?
    
    init(id: String, email: String, displayName: String? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
    }
}
