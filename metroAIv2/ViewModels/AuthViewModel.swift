import Foundation
import SwiftUI

/// View model for managing authentication state and operations
@Observable
@MainActor
final class AuthViewModel {
    // MARK: - Form Properties
    
    var username = ""
    var email = ""
    var password = ""
    
    // MARK: - State Properties
    
    var isLoading = false
    var errorMessage: String?
    var isAuthenticated = false
    
    // MARK: - Services
    
    private let authService = AuthService.shared
    private let keychainService = KeychainService.shared
    
    // MARK: - Initialization
    
    init() {
        checkAuthStatus()
    }
    
    // MARK: - Authentication Status
    
    /// Check if user is currently authenticated
    func checkAuthStatus() {
        isAuthenticated = authService.isAuthenticated
    }
    
    // MARK: - Validation
    
    var isValidUsername: Bool {
        username.count >= 1 && username.count <= 255
    }
    
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }
    
    var isValidPassword: Bool {
        password.count >= 8
    }
    
    var canLogin: Bool {
        !username.isEmpty && !password.isEmpty && !isLoading
    }
    
    var canRegister: Bool {
        isValidUsername && isValidEmail && isValidPassword && !isLoading
    }
    
    // MARK: - Registration
    
    /// Register a new user account
    func register() async {
        guard canRegister else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await authService.register(
                username: username,
                email: email,
                password: password
            )
            
            // Clear sensitive data
            clearFields()

            // Update authentication state
            isAuthenticated = true

            // Fetch reference data in background (non-blocking)
            Task { try? await BootstrapService.shared.fetchBootstrapData() }

        } catch APIError.authenticationFailed(let message) {
            errorMessage = "Registration failed: \(message)"
        } catch APIError.networkError(let error) {
            errorMessage = "Network error: \(error.localizedDescription)"
        } catch {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Login
    
    /// Login with existing credentials
    func login() async {
        guard canLogin else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await authService.login(
                usernameOrEmail: username,
                password: password
            )
            
            // Clear sensitive data
            clearFields()

            // Update authentication state
            isAuthenticated = true

            // Fetch reference data in background (non-blocking)
            Task { try? await BootstrapService.shared.fetchBootstrapData() }

        } catch APIError.invalidCredentials {
            errorMessage = "Invalid username or password"
        } catch APIError.networkError(let error) {
            errorMessage = "Network error: \(error.localizedDescription)"
        } catch {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Logout
    
    /// Logout current user
    func logout() {
        do {
            try authService.logout()
            isAuthenticated = false
            clearFields()
        } catch {
            errorMessage = "Failed to logout: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Helpers
    
    /// Clear all form fields
    func clearFields() {
        username = ""
        email = ""
        password = ""
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
