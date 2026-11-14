import SwiftUI

/// A modern, interactive row displaying a single task in the Todo list.
struct TodoRowView: View {
    let task: TodoItem
    let onToggleCompletion: () -> Void
    let onEdit: () -> Void
    
    private var formattedDate: String {
        let date = task.updatedAt ?? task.createdAt ?? Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // MARK: - Toggle Checkbox
            Button(action: onToggleCompletion) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(.top, 2)
            
            // MARK: - Task Info
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted, color: .secondary)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .lineLimit(2)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if task.isCompleted {
                        Text("• Completed")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.top, 2)
            }
            
            Spacer()
            
            // MARK: - Edit Action Button
            Button(action: onEdit) {
                Image(systemName: "pencil.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.blue.opacity(0.8))
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(.top, 2)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
    }
}
