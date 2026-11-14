import Foundation
import FirebaseFirestore
import Combine

enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case active = "Active"
    case completed = "Done"
    
    var id: String { self.rawValue }
}

/// ViewModel managing Todo tasks, search, filtering, and CRUD operations.
@MainActor
final class TodoViewModel: ObservableObject {
    @Published var tasks: [TodoItem] = []
    @Published var searchQuery: String = ""
    @Published var selectedFilter: TaskFilter = .all
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showErrorAlert: Bool = false
    
    // Delete Confirmation State
    @Published var showDeleteAlert: Bool = false
    @Published var taskToDelete: TodoItem?
    
    private let firestoreService = FirestoreService.shared
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Bind to FirestoreService updates
        firestoreService.$tasks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tasks in
                self?.tasks = tasks
            }
            .store(in: &cancellables)
        
        firestoreService.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.isLoading = isLoading
            }
            .store(in: &cancellables)
        
        firestoreService.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.errorMessage = error
                    self?.showErrorAlert = true
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Filtered Tasks
    
    var filteredTasks: [TodoItem] {
        tasks.filter { task in
            // Filter by completion status
            let matchesFilter: Bool
            switch selectedFilter {
            case .all:
                matchesFilter = true
            case .active:
                matchesFilter = !task.isCompleted
            case .completed:
                matchesFilter = task.isCompleted
            }
            
            // Filter by search query
            if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return matchesFilter
            } else {
                let query = searchQuery.lowercased()
                let matchesSearch = task.title.lowercased().contains(query) ||
                                   task.description.lowercased().contains(query)
                return matchesFilter && matchesSearch
            }
        }
    }
    
    // MARK: - Task Statistics
    
    var totalCount: Int { tasks.count }
    var completedCount: Int { tasks.filter { $0.isCompleted }.count }
    var activeCount: Int { tasks.filter { !$0.isCompleted }.count }
    
    // MARK: - Lifecycle / Listener
    
    func startListening() {
        guard let uid = authService.currentUser?.uid else { return }
        firestoreService.startListening(for: uid)
    }
    
    func stopListening() {
        firestoreService.stopListening()
    }
    
    // MARK: - CRUD Operations
    
    /// Create (Add)
    func addTask(title: String, description: String) async -> Bool {
        guard let uid = authService.currentUser?.uid else {
            showError("User is not authenticated.")
            return false
        }
        
        isLoading = true
        do {
            try await firestoreService.addTask(userUID: uid, title: title, description: description)
            isLoading = false
            return true
        } catch {
            isLoading = false
            showError("Failed to add task: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Update (Edit)
    func updateTask(task: TodoItem, title: String, description: String, isCompleted: Bool) async -> Bool {
        guard let uid = authService.currentUser?.uid, let taskID = task.id else {
            showError("Unable to update task: Missing ID or user.")
            return false
        }
        
        isLoading = true
        do {
            try await firestoreService.updateTask(
                userUID: uid,
                taskID: taskID,
                title: title,
                description: description,
                isCompleted: isCompleted
            )
            isLoading = false
            return true
        } catch {
            isLoading = false
            showError("Failed to update task: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Toggle Completion
    func toggleTaskCompletion(task: TodoItem) {
        guard let uid = authService.currentUser?.uid else { return }
        Task {
            do {
                try await firestoreService.toggleTaskCompletion(userUID: uid, task: task)
            } catch {
                showError("Failed to update task status: \(error.localizedDescription)")
            }
        }
    }
    
    /// Delete Confirmation Request
    func requestDelete(task: TodoItem) {
        self.taskToDelete = task
        self.showDeleteAlert = true
    }
    
    /// Perform Delete after confirmation
    func confirmDelete() {
        guard let task = taskToDelete,
              let taskID = task.id,
              let uid = authService.currentUser?.uid else {
            taskToDelete = nil
            return
        }
        
        Task {
            do {
                try await firestoreService.deleteTask(userUID: uid, taskID: taskID)
                self.taskToDelete = nil
            } catch {
                self.taskToDelete = nil
                showError("Failed to delete task: \(error.localizedDescription)")
            }
        }
    }
    
    private func showError(_ message: String) {
        self.errorMessage = message
        self.showErrorAlert = true
    }
}
