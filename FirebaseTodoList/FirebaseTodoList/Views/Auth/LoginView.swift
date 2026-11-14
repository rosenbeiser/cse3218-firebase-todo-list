import SwiftUI

/// User Login (Sign In) screen using Firebase Authentication.
struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var navigateToRegister: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "checklist")
                                    .font(.system(size: 38, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 24)
                            
                            Text("Welcome Back")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Sign in to manage your tasks with Cloud Firestore")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        
                        // MARK: - Input Fields Card
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
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
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                CustomTextField(
                                    icon: "lock.fill",
                                    placeholder: "Enter your password",
                                    text: $authViewModel.password,
                                    isSecure: true
                                )
                            }
                            
                            // Sign In Button
                            Button(action: {
                                Task {
                                    await authViewModel.login()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    if authViewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Sign In")
                                            .fontWeight(.bold)
                                        Image(systemName: "arrow.right")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(authViewModel.isLoginFormValid ? Color.blue : Color.gray.opacity(0.5))
                                )
                                .foregroundColor(.white)
                            }
                            .disabled(!authViewModel.isLoginFormValid || authViewModel.isLoading)
                            .padding(.top, 8)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(UIColor.secondarySystemGroupedBackground))
                        )
                        .padding(.horizontal, 20)
                        
                        // MARK: - Navigation to Register
                        HStack(spacing: 6) {
                            Text("Don't have an account?")
                                .foregroundColor(.secondary)
                            
                            NavigationLink(destination: RegisterView()) {
                                Text("Sign Up")
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                        }
                        .font(.subheadline)
                        .padding(.top, 8)
                        
                        // Footer notice
                        VStack(spacing: 4) {
                            Text("Mobile Computing Laboratory")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Text("Firebase Authentication • Cloud Firestore")
                                .font(.caption2)
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .padding(.top, 32)
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Authentication Error", isPresented: $authViewModel.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(authViewModel.errorMessage ?? "An unknown error occurred.")
            }
            .overlay {
                if authViewModel.isLoading {
                    LoadingOverlay(message: "Signing in...")
                }
            }
        }
    }
}
