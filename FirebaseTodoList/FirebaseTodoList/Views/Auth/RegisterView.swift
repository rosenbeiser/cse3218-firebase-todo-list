import SwiftUI

/// User Registration (Sign Up) screen with email and password confirmation.
struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding(.top, 16)
                        
                        Text("Create Account")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Register with Firebase Authentication to start storing tasks in Cloud Firestore")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // MARK: - Form Card
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email Address")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            CustomTextField(
                                icon: "envelope.fill",
                                placeholder: "student@university.edu",
                                text: $authViewModel.email,
                                keyboardType: .emailAddress
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password (minimum 6 characters)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            CustomTextField(
                                icon: "lock.fill",
                                placeholder: "Enter password",
                                text: $authViewModel.password,
                                isSecure: true
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Confirm Password")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            CustomTextField(
                                icon: "lock.rotation",
                                placeholder: "Re-enter password",
                                text: $authViewModel.confirmPassword,
                                isSecure: true
                            )
                        }
                        
                        // Validation hints
                        VStack(alignment: .leading, spacing: 4) {
                            if !authViewModel.password.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: authViewModel.password.count >= 6 ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(authViewModel.password.count >= 6 ? .green : .red)
                                    Text("At least 6 characters")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if !authViewModel.confirmPassword.isEmpty {
                                HStack(spacing: 6) {
                                    let passwordsMatch = authViewModel.password == authViewModel.confirmPassword
                                    Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(passwordsMatch ? .green : .red)
                                    Text(passwordsMatch ? "Passwords match" : "Passwords do not match")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Register Button
                        Button(action: {
                            Task {
                                await authViewModel.register()
                            }
                        }) {
                            HStack(spacing: 8) {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Register Account")
                                        .fontWeight(.bold)
                                    Image(systemName: "checkmark")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(authViewModel.isRegistrationFormValid ? Color.blue : Color.gray.opacity(0.5))
                            )
                            .foregroundColor(.white)
                        }
                        .disabled(!authViewModel.isRegistrationFormValid || authViewModel.isLoading)
                        .padding(.top, 8)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal, 20)
                    
                    // MARK: - Back to Sign In
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Text("Already have an account?")
                                .foregroundColor(.secondary)
                            Text("Sign In")
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        .font(.subheadline)
                    }
                    .padding(.top, 4)
                }
                .padding(.bottom, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Registration Error", isPresented: $authViewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authViewModel.errorMessage ?? "An error occurred during registration.")
        }
        .overlay {
            if authViewModel.isLoading {
                LoadingOverlay(message: "Creating account...")
            }
        }
    }
}
