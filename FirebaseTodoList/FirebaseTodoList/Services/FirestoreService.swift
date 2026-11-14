import Foundation
import FirebaseFirestore
import Combine

/// Service layer responsible for all Cloud Firestore operations.
/// Tasks are stored under the user-specific path: `users/{userUID}/tasks/{taskID}`.
@MainActor
final class FirestoreService: ObservableObject {
    static let shared = FirestoreService()
    
    private let db = Firestore.firestore()
    private var tasksListener: ListenerRegistration?
    
    @Published var tasks: [TodoItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Firestore References
    
    /// Returns the collection reference for the given user's tasks: `users/{userUID}/tasks`
    private func tasksCollection(for userUID: String) -> CollectionReference {
        return db.collection("users").document(userUID).collection("tasks")
    }
    
    // MARK: - Real-time Listener (Read)
    
    /// Starts listening to real-time changes in the user's tasks collection.
    /// Ordered by creation date descending so newly created tasks appear on top.
    func startListening(for userUID: String) {
        // Stop any existing listener first
        stopListening()
        
        self.isLoading = true
        self.errorMessage = nil
        
        let query = tasksCollection(for: userUID)
            .order(by: "createdAt", descending: true)
        
        self.tasksListener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Failed to load tasks: \(error.localizedDescription)"
                return
            }
            
            guard let documents = snapshot?.documents else {
                self.tasks = []
                return
            }
            
            self.tasks = documents.compactMap { document in
                do {
                    var task = try document.data(as: TodoItem.self)
                    task.id = document.documentID
                    return task
                } catch {
                    print("Error decoding task \(document.documentID): \(error.localizedDescription)")
                    return nil
                }
            }
        }
    }
    
    /// Stops the active snapshot listener (called on user sign out or when leaving screen)
    func stopListening() {
        tasksListener?.remove()
        tasksListener = nil
        tasks = []
    }
    
    // MARK: - Create Task
    
    /// Adds a new task to `users/{userUID}/tasks`
    func addTask(userUID: String, title: String, description: String) async throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty else {
            throw NSError(
                domain: "FirestoreService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Task title cannot be empty."]
            )
        }
        
        let newTaskData: [String: Any] = [
            "title": trimmedTitle,
            "description": trimmedDescription,
            "isCompleted": false,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        _ = try await tasksCollection(for: userUID).addDocument(data: newTaskData)
    }
    
    // MARK: - Update Task
    
    /// Updates an existing task's title, description, and updatedAt timestamp
    func updateTask(userUID: String, taskID: String, title: String, description: String, isCompleted: Bool) async throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty else {
            throw NSError(
                domain: "FirestoreService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Task title cannot be empty."]
            )
        }
        
        let updateData: [String: Any] = [
            "title": trimmedTitle,
            "description": trimmedDescription,
            "isCompleted": isCompleted,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await tasksCollection(for: userUID).document(taskID).updateData(updateData)
    }
    
    /// Toggles the completion status of a task
    func toggleTaskCompletion(userUID: String, task: TodoItem) async throws {
        guard let taskID = task.id else { return }
        
        let updateData: [String: Any] = [
            "isCompleted": !task.isCompleted,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await tasksCollection(for: userUID).document(taskID).updateData(updateData)
    }
    
    // MARK: - Delete Task
    
    /// Deletes a task from `users/{userUID}/tasks/{taskID}`
    func deleteTask(userUID: String, taskID: String) async throws {
        try await tasksCollection(for: userUID).document(taskID).delete()
    }
}
