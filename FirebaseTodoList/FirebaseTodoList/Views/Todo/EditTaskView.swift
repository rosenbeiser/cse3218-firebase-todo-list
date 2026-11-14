import SwiftUI

/// Screen allowing the user to view, edit, or delete an existing task in Firestore.
struct EditTaskView: View {
    let task: TodoItem
    @EnvironmentObject var todoViewModel: TodoViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var isCompleted: Bool = false
    @State private var isSaving: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var hasChanges: Bool {
        title != task.title ||
        description != task.description ||
        isCompleted != task.isCompleted
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Status Section
                Section {
                    Toggle(isOn: $isCompleted) {
                        HStack(spacing: 12) {
                            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isCompleted ? .green : .secondary)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isCompleted ? "Completed" : "Mark as Completed")
                                    .fontWeight(.medium)
                                Text(isCompleted ? "This task is finished" : "Task is still in progress")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Status")
                }
                
                // MARK: - Task Details
                Section {
                    TextField("Enter task title", text: $title)
                        .font(.headline)
                    
                    Text("\(title.count)/200 characters")
                        .font(.caption2)
                        .foregroundColor(title.count > 200 ? .red : .secondary)
                } header: {
                    HStack {
                        Text("Task Title")
                        Text("*").foregroundColor(.red)
                    }
                }
                
                Section {
                    TextEditor(text: $description)
                        .frame(minHeight: 120)
                        .font(.body)
                    
                    Text("\(description.count)/2000 characters")
                        .font(.caption2)
                        .foregroundColor(description.count > 2000 ? .red : .secondary)
                } header: {
                    Text("Description")
                }
                
                // MARK: - Metadata
                Section {
                    HStack {
                        Text("Created")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formattedDate(task.createdAt))
                            .foregroundColor(.primary)
                    }
                    .font(.footnote)
                    
                    if let updated = task.updatedAt {
                        HStack {
                            Text("Last Modified")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formattedDate(updated))
                                .foregroundColor(.primary)
                        }
                        .font(.footnote)
                    }
                } header: {
                    Text("Information")
                }
                
                // MARK: - Delete Action
                Section {
                    Button(role: .destructive, action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "trash")
                            Text("Delete Task")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.bold)
                    .disabled(!isFormValid || !hasChanges || isSaving || title.count > 200 || description.count > 2000)
                }
            }
            .confirmationDialog(
                "Delete Task",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Task", role: .destructive) {
                    deleteTask()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to permanently delete \"\(task.title)\"? This action cannot be undone.")
            }
            .overlay {
                if isSaving {
                    LoadingOverlay(message: "Updating Firestore...")
                }
            }
            .onAppear {
                title = task.title
                description = task.description
                isCompleted = task.isCompleted
            }
        }
    }
    
    private func saveChanges() {
        guard isFormValid else { return }
        isSaving = true
        
        Task {
            let success = await todoViewModel.updateTask(
                task: task,
                title: title,
                description: description,
                isCompleted: isCompleted
            )
            isSaving = false
            if success {
                dismiss()
            }
        }
    }
    
    private func deleteTask() {
        todoViewModel.requestDelete(task: task)
        todoViewModel.confirmDelete()
        dismiss()
    }
}
