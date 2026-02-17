import SwiftUI

/// Login screen for existing users
struct LoginView: View {
    @Bindable var authViewModel: AuthViewModel
    @State private var showRegister = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.blue)
                    
                    Text("Login")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Welcome back!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)
                
                // Form
                VStack(spacing: 16) {
                    // Username or Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username or Email")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        TextField("Enter username or email", text: $authViewModel.username)
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .padding()
                            .background(.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        SecureField("Enter password", text: $authViewModel.password)
                            .textContentType(.password)
                            .padding()
                            .background(.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 20)
                
                // Login Button
                Button {
                    Task {
                        await authViewModel.login()
                    }
                } label: {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text("Login")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundStyle(.white)
                    .background(authViewModel.canLogin ? .blue : .gray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!authViewModel.canLogin)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Register Link
                Button {
                    showRegister = true
                } label: {
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundStyle(.secondary)
                        Text("Register")
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
        .navigationDestination(isPresented: $showRegister) {
            RegisterView(authViewModel: authViewModel)
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
        LoginView(authViewModel: AuthViewModel())
    }
}
