import SwiftUI

/// Registration screen for new users
struct RegisterView: View {
    @Bindable var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.blue)
                    
                    Text("Register")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Create your account")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)
                
                // Form
                VStack(spacing: 16) {
                    // Username
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Username")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            if !authViewModel.username.isEmpty {
                                Image(systemName: authViewModel.isValidUsername ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(authViewModel.isValidUsername ? .green : .red)
                                    .font(.caption)
                            }
                        }
                        
                        TextField("Choose a username", text: $authViewModel.username)
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .padding()
                            .background(.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        if !authViewModel.username.isEmpty && !authViewModel.isValidUsername {
                            Text("Username must be 1-255 characters")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    
                    // Email
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Email")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            if !authViewModel.email.isEmpty {
                                Image(systemName: authViewModel.isValidEmail ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(authViewModel.isValidEmail ? .green : .red)
                                    .font(.caption)
                            }
                        }
                        
                        TextField("Enter your email", text: $authViewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .padding()
                            .background(.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        if !authViewModel.email.isEmpty && !authViewModel.isValidEmail {
                            Text("Please enter a valid email address")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    
                    // Password
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Password")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            if !authViewModel.password.isEmpty {
                                Image(systemName: authViewModel.isValidPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(authViewModel.isValidPassword ? .green : .red)
                                    .font(.caption)
                            }
                        }
                        
                        SecureField("Create a password", text: $authViewModel.password)
                            .textContentType(.newPassword)
                            .padding()
                            .background(.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        if !authViewModel.password.isEmpty && !authViewModel.isValidPassword {
                            Text("Password must be at least 8 characters")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Register Button
                Button {
                    Task {
                        await authViewModel.register()
                    }
                } label: {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text("Register")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundStyle(.white)
                    .background(authViewModel.canRegister ? .blue : .gray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!authViewModel.canRegister)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Login Link
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundStyle(.secondary)
                        Text("Login")
                            .foregroundStyle(.blue)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .padding(.top, 8)
                
                Spacer()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .constant(authViewModel.errorMessage != nil)) {
            Button("OK") {
                authViewModel.clearError()
            }
        } message: {
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView(authViewModel: AuthViewModel())
    }
}
