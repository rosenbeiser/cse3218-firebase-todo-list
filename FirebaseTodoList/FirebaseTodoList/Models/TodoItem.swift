import Foundation
import FirebaseFirestore

/// Represents a Todo task stored in Cloud Firestore under `users/{userUID}/tasks/{taskID}`.
struct TodoItem: Identifiable, Codable, Equatable {
    /// Firestore Document ID (automatically mapped by FirebaseFirestore)
    @DocumentID var id: String?
    
    /// The mandatory title/heading of the task
    var title: String
    
    /// Detailed description of the task
    var description: String
    
    /// Optional status flag indicating completion
    var isCompleted: Bool
    
    /// Server timestamp when the task was initially created
    @ServerTimestamp var createdAt: Date?
    
    /// Server timestamp when the task was last edited
    @ServerTimestamp var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case isCompleted
        case createdAt
        case updatedAt
    }
    
    init(id: String? = nil,
         title: String,
         description: String,
         isCompleted: Bool = false,
         createdAt: Date? = nil,
         updatedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
