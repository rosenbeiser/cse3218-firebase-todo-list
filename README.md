# Mobile Computing Lab Assignment – Firebase Integrated Todo List Application

**Development Target:** iOS 16.0+ | Xcode 15.2 | macOS 13 (VMware)  
**Frameworks:** SwiftUI, Firebase iOS SDK (Authentication, Cloud Firestore)  
**Architecture:** Model-View-ViewModel (MVVM)

---

## 📱 Table of Contents
1. [Project Overview](#project-overview)
2. [Application Architecture](#application-architecture)
3. [Features & CRUD Matrix](#features--crud-matrix)
4. [Project Structure](#project-structure)

---

## 1. Project Overview

This application is a native iOS Todo List application developed using **SwiftUI** and integrated with **Google Firebase**. It enables authenticated users to manage their personal daily tasks with persistent cloud synchronization using **Cloud Firestore** and **Firebase Authentication**.

### Core Highlights:
- **Strict User Isolation:** Tasks are stored under `users/{userUID}/tasks/{taskID}`, preventing any cross-user data leakage.
- **Real-Time Synchronization:** Uses Firestore snapshot listeners so changes appear instantly without manual refreshes.
- **Secure Authentication:** Complete Email/Password sign-up, sign-in, and sign-out flows with descriptive client-side and server-side error validation.
- **Production-Grade Firestore Rules:** Rules validate field boundaries, non-empty titles, timestamps, and enforce user data boundaries.
- **Designed for Xcode 15.2 on macOS 13 (Ventura):** Optimized for VMware development environments using Swift Package Manager.

---

## 2. Application Architecture

The application strictly implements the **Model-View-ViewModel (MVVM)** architectural pattern:

```
┌────────────────────────────────────────────────────────┐
│                      SwiftUI Views                     │
│  RootView • LoginView • RegisterView • TodoListView    │
│  TodoRowView • AddTaskView • EditTaskView • Components │
└───────────────────────────▲────────────────────────────┘
                            │ (Data binding & State)
┌───────────────────────────▼────────────────────────────┐
│                    View Models                         │
│   AuthViewModel            │   TodoViewModel           │
│   (Form validation, auth   │   (CRUD, search filter,   │
│    state, loading, alerts) │    listeners, counts)     │
└───────────────────────────▲────────────────────────────┘
                            │ (Async Calls & Publishers)
┌───────────────────────────▼────────────────────────────┐
│                   Services Layer                       │
│   AuthService              │   FirestoreService        │
│   (FirebaseAuth wrapper)   │   (CRUD & real-time sync) │
└───────────────────────────▲────────────────────────────┘
                            │ (Network / Cloud SDK)
┌───────────────────────────▼────────────────────────────┐
│                     Google Firebase                    │
│   Firebase Authentication  │   Cloud Firestore         │
└────────────────────────────────────────────────────────┘
```

### Component Roles:
1. **Models (`TodoItem.swift`, `AppUser.swift`)**:
   - `TodoItem`: Represents a task document (`id`, `title`, `description`, `isCompleted`, `createdAt`, `updatedAt`). Utilizes `@DocumentID` and `@ServerTimestamp`.
   - `AppUser`: Represents the authenticated user profile.
2. **Services (`AuthService.swift`, `FirestoreService.swift`)**:
   - `AuthService`: Singleton managing user session state with `Auth.auth().addStateDidChangeListener`, error code mapping, sign-in, sign-up, and sign-out.
   - `FirestoreService`: Singleton handling Firestore queries for `users/{userUID}/tasks`, attaching snapshot listeners for real-time reads, and handling document mutations.
3. **ViewModels (`AuthViewModel.swift`, `TodoViewModel.swift`)**:
   - `AuthViewModel`: Manages login/registration input states, regex email verification, password confirmation checks, and error banners.
   - `TodoViewModel`: Exposes `filteredTasks` based on search queries and category filters (`All`, `Active`, `Done`), computes summary metrics, and manages delete confirmation state.
4. **Views (`Views/`)**:
   - `RootView`: Automatically displays `LoginView` or `TodoListView` based on reactive authentication status.
   - `TodoListView`: Main task dashboard with search, segmented filters, task statistics chips, swipe actions, and pull-to-refresh.
   - `AddTaskView`: Sheet modal to input task title (mandatory) and multiline description.
   - `EditTaskView`: Sheet modal to edit task information, toggle completion, view timestamps, or delete the task.

---

## 3. Features & CRUD Matrix

| Operation | Implementation | Firestore Method | Trigger Location |
| :--- | :--- | :--- | :--- |
| **Create** | Adds new task with title and description | `tasksCollection.addDocument(data:)` | `AddTaskView` -> Save Button |
| **Read** | Real-time task observation ordered by `createdAt` | `query.addSnapshotListener` | `TodoListView` (auto-loaded on login) |
| **Update** | Modifies title, description, or `isCompleted` | `document.updateData(...)` | `EditTaskView` or tap Checkbox |
| **Delete** | Removes document after user confirmation dialog | `document.delete()` | Swipe-to-delete or `EditTaskView` |

---

## 4. Project Structure

```
FirebaseTodoList/
├── .gitignore
├── firebase.json
├── firestore.rules
├── README.md
├── FirebaseTodoList.xcodeproj/
│   ├── project.pbxproj
│   └── project.xcworkspace/
│       └── contents.xcworkspacedata
└── FirebaseTodoList/
    ├── App/
    │   ├── AppDelegate.swift
    │   └── FirebaseTodoListApp.swift
    ├── Models/
    │   ├── AppUser.swift
    │   └── TodoItem.swift
    ├── Services/
    │   ├── AuthService.swift
    │   └── FirestoreService.swift
    ├── ViewModels/
    │   ├── AuthViewModel.swift
    │   └── TodoViewModel.swift
    ├── Views/
    │   ├── RootView.swift
    │   ├── Auth/
    │   │   ├── LoginView.swift
    │   │   └── RegisterView.swift
    │   ├── Todo/
    │   │   ├── AddTaskView.swift
    │   │   ├── EditTaskView.swift
    │   │   ├── TodoListView.swift
    │   │   └── TodoRowView.swift
    │   └── Components/
    │       ├── CustomTextField.swift
    │       ├── EmptyStateView.swift
    │       └── LoadingOverlay.swift
    ├── Resources/
    │   ├── GoogleService-Info.plist    <-- (Replace with your Firebase file)
    │   └── Assets.xcassets/
    └── Info.plist
```

---
