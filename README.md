# Mobile Computing Lab Assignment – Firebase Integrated Todo List Application

**Course:** Mobile Computing (CSE 3218)  
**Development Target:** iOS 16.0+ | Xcode 15.2 | macOS 13 (VMware)  
**Frameworks:** SwiftUI, Firebase iOS SDK (Authentication, Cloud Firestore)  
**Architecture:** Model-View-ViewModel (MVVM)

---

## 📱 Table of Contents
1. [Project Overview](#project-overview)
2. [Application Architecture](#application-architecture)
3. [Features & CRUD Matrix](#features--crud-matrix)
4. [Project Structure](#project-structure)
5. [Step-by-Step Firebase Setup Guide](#step-by-step-firebase-setup-guide)
6. [Firestore Security Rules](#firestore-security-rules)
7. [Running the Application on macOS / Xcode 15.2](#running-the-application-on-macos--xcode-152)
8. [GitHub Repository Setup & Submission Guide](#github-repository-setup--submission-guide)
9. [Troubleshooting Guide](#troubleshooting-guide)
10. [Requirements Verification Status](#requirements-verification-status)

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

## 5. Step-by-Step Firebase Setup Guide

Follow these steps in your web browser:

### Step 1: Create a Firebase Project
1. Open [Firebase Console](https://console.firebase.google.com/) and sign in with your Google account.
2. Click **Add project** (or **Create a project**).
3. Enter a project name (e.g. `todo-mobile-lab`).
4. Disable or enable Google Analytics (disable is recommended for faster setup), then click **Create project**.

### Step 2: Register the iOS Application
1. On your Firebase project dashboard, click the **iOS icon** (`</>`) to add an iOS app.
2. Enter the **Apple bundle ID**:
   ```
   com.university.firebasetodolist
   ```
   *(Note: If you customize the bundle identifier in Xcode, make sure this exact string matches).*
3. App nickname: `Firebase Todo App` (optional).
4. Click **Register app**.

### Step 3: Download `GoogleService-Info.plist`
1. Click **Download GoogleService-Info.plist**.
2. Save the file to your computer.
3. Replace the placeholder file at:
   `FirebaseTodoList/FirebaseTodoList/Resources/GoogleService-Info.plist`
   with your downloaded file.
4. In the Firebase wizard, click **Next** through the remaining steps and click **Continue to console**.

### Step 4: Enable Firebase Authentication
1. In the Firebase Console left sidebar, go to **Build** > **Authentication**.
2. Click **Get Started**.
3. Under the **Sign-in method** tab, click **Email/Password**.
4. Toggle **Enable** to ON for "Email/Password" (leave "Email link / passwordless" OFF).
5. Click **Save**.

### Step 5: Create Cloud Firestore Database
1. In the Firebase Console left sidebar, go to **Build** > **Firestore Database**.
2. Click **Create database**.
3. Choose a Firestore location close to you (e.g. `nam5 (us-central)` or `asia-east1`).
4. Select **Start in production mode** (or test mode, but we will publish secure rules in the next step).
5. Click **Create**.

### Step 6: Publish Security Rules
1. In the Firestore Database section, navigate to the **Rules** tab.
2. Delete any existing template rules in the editor.
3. Copy the contents of the `firestore.rules` file included in this repository.
4. Click **Publish**.

---

## 6. Firestore Security Rules

The application uses security rules stored in `firestore.rules`.
These rules enforce strict authenticated user isolation:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() {
      return request.auth != null && request.auth.uid != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Default deny all access
    match /{document=**} {
      allow read, write: if false;
    }

    // User profile documents
    match /users/{userUID} {
      allow read, write: if isOwner(userUID);

      // Tasks subcollection: users/{userUID}/tasks/{taskID}
      match /tasks/{taskID} {
        allow read, delete: if isOwner(userUID);
        
        allow create: if isOwner(userUID) &&
          request.resource.data.title is string &&
          request.resource.data.title.size() >= 1 &&
          request.resource.data.title.size() <= 200 &&
          request.resource.data.createdAt is timestamp &&
          request.resource.data.updatedAt is timestamp;
          
        allow update: if isOwner(userUID) &&
          request.resource.data.title is string &&
          request.resource.data.title.size() >= 1 &&
          request.resource.data.title.size() <= 200 &&
          request.resource.data.updatedAt is timestamp;
      }
    }
  }
}
```

---

## 7. Running the Application on macOS / Xcode 15.2

If developing in VMware running macOS 13 (Ventura):

### Step 1: Transfer or Clone the Repository
Transfer the project folder to your macOS environment (via shared folders, Git clone, or USB).

### Step 2: Open in Xcode
1. Launch **Xcode 15.2**.
2. Open `FirebaseTodoList/FirebaseTodoList.xcodeproj`.

### Step 3: Verify Swift Package Dependencies
1. Xcode will automatically resolve the Swift Package `firebase-ios-sdk`.
2. If dependencies do not resolve automatically:
   - Select **File** > **Packages** > **Reset Package Caches** or **Resolve Package Versions**.
   - Make sure your Mac/VM has an active internet connection during this initial download.

### Step 4: Verify `GoogleService-Info.plist`
1. In Xcode's Project Navigator (left sidebar), expand `FirebaseTodoList` > `Resources`.
2. Confirm that `GoogleService-Info.plist` is present.
3. Select the file and verify in the **File Inspector** (right sidebar) that under **Target Membership**, `FirebaseTodoList` is **checked**.

### Step 5: Select Simulator & Run
1. In the top toolbar, select an iOS Simulator (e.g. **iPhone 15** running iOS 17.2 or iOS 16).
2. Press **Cmd + R** or click the **Play** button.
3. The simulator will boot and launch the application.

---

## 8. GitHub Repository Setup & Submission Guide

To prepare and submit your assignment:

### Step 1: Initialize Git and Commit
Open **Terminal** in macOS (or Windows PowerShell in the project directory):

```bash
# Navigate to the assignment directory
cd "path/to/Assignment"

# Initialize git repository
git init

# Check status
git status

# Stage all files
git add .

# Create initial commit
git commit -m "feat: complete Firebase-integrated Todo List application in SwiftUI"
```

### Step 2: Create a Repository on GitHub
1. Go to [GitHub](https://github.com/) and sign in.
2. Click the **+** icon in the top right corner and select **New repository**.
3. Name your repository (e.g., `cse3218-mobile-computing-firebase-todo`).
4. Set visibility to **Public** (or **Private** with your instructor added as collaborator, according to the instructor's instructions).
5. Do **not** check "Initialize with a README" (we already have one).
6. Click **Create repository**.

### Step 3: Link and Push
In your Terminal:

```bash
# Rename branch to main
git branch -M main

# Add your remote origin (replace with your actual GitHub URL)
git remote add origin https://github.com/<your-username>/<your-repo-name>.git

# Push to GitHub
git push -u origin main
```

### Step 4: Verify on GitHub
1. Refresh your GitHub repository page.
2. Confirm that all source files, `firestore.rules`, and `README.md` are visible.
3. Copy the repository URL and submit it through the course submission form.

---

## 9. Troubleshooting Guide

### Issue 1: `Missing GoogleService-Info.plist` or Crash on App Launch
- **Cause:** Firebase cannot find the configuration file or `FirebaseApp.configure()` failed.
- **Fix:** Ensure you downloaded `GoogleService-Info.plist` from your Firebase project, copied it to `FirebaseTodoList/FirebaseTodoList/Resources/`, and verified that **Target Membership** is checked for `FirebaseTodoList`.

### Issue 2: `The email address is already in use by another account`
- **Cause:** Attempting to register an email that already exists in Firebase Authentication.
- **Fix:** Navigate to the Sign In screen and log in, or use a new email address.

### Issue 3: `Missing or insufficient permissions` (Firestore Error)
- **Cause:** Firestore security rules are blocking the operation, or the user is not authenticated.
- **Fix:** Ensure that `firestore.rules` have been published in the Firebase Console under **Firestore Database** > **Rules**. Verify that the user UID in the request matches `users/{userUID}`.

### Issue 4: Xcode Linker Error (`-ObjC` flag)
- **Cause:** Firebase's Objective-C categories were stripped during static compilation.
- **Fix:** The project includes `OTHER_LDFLAGS = ( "$(inherited)", "-ObjC" );` in `project.pbxproj`. If creating a new Xcode project manually, go to **Build Settings** > **Other Linker Flags** and add `-ObjC`.

### Issue 5: Swift Package Manager Resolution Fails in VMware
- **Cause:** Network connection issue inside VMware.
- **Fix:** Check VMware Network Adapter settings (switch between NAT and Bridged mode if internet is unavailable). In Xcode, select **File** > **Packages** > **Reset Package Caches**.

---

## 10. Requirements Verification Status

| Requirement | Category | Status | Notes |
| :--- | :--- | :--- | :--- |
| **Create Task** | Mandatory | Completed | Title, description, timestamps saved to Firestore |
| **Read Tasks** | Mandatory | Completed | Real-time snapshot listener ordered by `createdAt` |
| **Update Task** | Mandatory | Completed | Title, description, completion status editable |
| **Delete Task** | Mandatory | Completed | Permanent deletion with confirmation alert |
| **User Sign Up** | Mandatory | Completed | Email & Password with regex & match validation |
| **User Sign In** | Mandatory | Completed | Secure Firebase Auth login with error alerts |
| **User Sign Out** | Mandatory | Completed | Safe listener detachment and session clear |
| **User Data Isolation** | Mandatory | Completed | Strict path `users/{userUID}/tasks/{taskID}` |
| **Firestore Security Rules** | Mandatory | Completed | `firestore.rules` created with strict validation |
| **Search & Filtering** | Usability | Completed | Filter by All/Active/Done and search by text |
| **MVVM Architecture** | Technical | Completed | Clean separation: Models, ViewModels, Services, Views |
| **Xcode 15.2 / macOS 13** | Compatibility | Completed | SPM setup, iOS 16+ deployment target |
| **GitHub Ready** | Technical | Completed | Clean git structure with comprehensive `.gitignore` |

---
*Created for University Laboratory Assignment in Mobile Computing (CSE 3218).*
