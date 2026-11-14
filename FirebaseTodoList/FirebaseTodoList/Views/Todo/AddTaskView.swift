import SwiftUI

/// Screen allowing the user to create and add a new Todo task to Firestore.
struct AddTaskView: View {
    @EnvironmentObject var todoViewModel: TodoViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var isSaving: Bool = false
    @FocusState private var isTitleFocused: Bool
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Enter task title", text: $title)
                        .focused($isTitleFocused)
                        .font(.headline)
                        .submitLabel(.next)
                    
                    Text("\(title.count)/200 characters")
                        .font(.caption2)
                        .foregroundColor(title.count > 200 ? .red : .secondary)
                } header: {
                    HStack {
                        Text("Task Title")
                        Text("*").foregroundColor(.red)
                    }
                } footer: {
                    Text("Give your task a clear, concise name.")
                }
                
                Section {
                    TextEditor(text: $description)
                        .frame(minHeight: 120)
                        .font(.body)
                    
                    Text("\(description.count)/2000 characters")
                        .font(.caption2)
                        .foregroundColor(description.count > 2000 ? .red : .secondary)
                } header: {
                    Text("Description (Optional)")
                } footer: {
                    Text("Add details, notes, or instructions for this task.")
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                    .fontWeight(.bold)
                    .disabled(!isFormValid || isSaving || title.count > 200 || description.count > 2000)
                }
            }
            .overlay {
                if isSaving {
                    LoadingOverlay(message: "Saving task to Firestore...")
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTitleFocused = true
                }
            }
        }
    }
    
    private func saveTask() {
        guard isFormValid else { return }
        isSaving = true
        
        Task {
            let success = await todoViewModel.addTask(
                title: title,
                description: description
            )
            isSaving = false
            if success {
                dismiss()
            }
        }
    }
}
