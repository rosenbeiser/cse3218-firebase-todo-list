import SwiftUI

/// Main Home screen displaying the authenticated user's tasks with real-time Firestore sync.
struct TodoListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var todoViewModel: TodoViewModel
    
    @State private var showingAddTask: Bool = false
    @State private var taskToEdit: TodoItem? = nil
    @State private var showingLogoutConfirmation: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Filter Segment Control
                Picker("Filter", selection: $todoViewModel.selectedFilter) {
                    ForEach(TaskFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
                
                // MARK: - Task Summary Chips
                HStack(spacing: 12) {
                    summaryChip(title: "Total", count: todoViewModel.totalCount, color: .blue)
                    summaryChip(title: "Active", count: todoViewModel.activeCount, color: .orange)
                    summaryChip(title: "Done", count: todoViewModel.completedCount, color: .green)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                
                Divider()
                
                // MARK: - Task List / Empty State
                ZStack {
                    if todoViewModel.isLoading && todoViewModel.tasks.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading tasks from Cloud Firestore...")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if todoViewModel.tasks.isEmpty {
                        EmptyStateView(
                            icon: "checklist.unchecked",
                            title: "No Tasks Yet",
                            message: "Your todo list is currently empty. Tap the '+' button above to add your first task to Cloud Firestore.",
                            actionTitle: "Add New Task",
                            action: { showingAddTask = true }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if todoViewModel.filteredTasks.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No Results Found",
                            message: "No tasks matched your current filter or search query.",
                            actionTitle: "Reset Filters",
                            action: {
                                todoViewModel.searchQuery = ""
                                todoViewModel.selectedFilter = .all
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(todoViewModel.filteredTasks) { task in
                                TodoRowView(
                                    task: task,
                                    onToggleCompletion: {
                                        todoViewModel.toggleTaskCompletion(task: task)
                                    },
                                    onEdit: {
                                        taskToEdit = task
                                    }
                                )
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        todoViewModel.requestDelete(task: task)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        taskToEdit = task
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        todoViewModel.toggleTaskCompletion(task: task)
                                    } label: {
                                        Label(
                                            task.isCompleted ? "Unmark" : "Complete",
                                            systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark"
                                        )
                                    }
                                    .tint(task.isCompleted ? .orange : .green)
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .refreshable {
                            todoViewModel.startListening()
                        }
                    }
                }
            }
            .navigationTitle("My Tasks")
            .searchable(text: $todoViewModel.searchQuery, prompt: "Search by title or description")
            .toolbar {
                // Logout & User Info
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingLogoutConfirmation = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("Logout")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Add Task Button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTask = true
                    }) {
                        Image(systemName: "plus")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
            .sheet(item: $taskToEdit) { task in
                EditTaskView(task: task)
            }
            // MARK: - Delete Confirmation Alert
            .confirmationDialog(
                "Delete Task",
                isPresented: $todoViewModel.showDeleteAlert,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    todoViewModel.confirmDelete()
                }
                Button("Cancel", role: .cancel) {
                    todoViewModel.taskToDelete = nil
                }
            } message: {
                if let task = todoViewModel.taskToDelete {
                    Text("Are you sure you want to delete \"\(task.title)\"? This will remove it from Cloud Firestore.")
                } else {
                    Text("Are you sure you want to delete this task?")
                }
            }
            // MARK: - Logout Confirmation Dialog
            .confirmationDialog(
                "Sign Out",
                isPresented: $showingLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    todoViewModel.stopListening()
                    authViewModel.signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Logged in as \(authViewModel.currentUser?.email ?? "User"). Are you sure you want to sign out?")
            }
            .alert("Error", isPresented: $todoViewModel.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(todoViewModel.errorMessage ?? "An error occurred.")
            }
            .onAppear {
                todoViewModel.startListening()
            }
        }
    }
    
    // MARK: - Summary Chip Helper
    private func summaryChip(title: String, count: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.15))
                .foregroundColor(color)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}
