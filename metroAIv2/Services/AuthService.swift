import Foundation

/// Service for handling authentication operations with the backend
@MainActor
final class AuthService {
    static let shared = AuthService()
    
    private let keychainService = KeychainService.shared
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Authentication State
    
    /// Check if user is currently authenticated
    var isAuthenticated: Bool {
        return keychainService.getAccessToken() != nil
    }
    
    // MARK: - Registration
    
    /// Register a new user account
    /// - Parameters:
    ///   - username: Desired username (1-255 characters)
    ///   - email: Valid email address
    ///   - password: Password (minimum 8 characters)
    /// - Returns: Token response with access and refresh tokens
    /// - Throws: APIError if registration fails
    func register(username: String, email: String, password: String) async throws -> TokenResponse {
        guard let url = URL(string: "\(Config.apiBaseURL)/api/auth/register") else {
            throw APIError.invalidURL
        }
        
        let requestBody = RegisterRequest(username: username, email: email, password: password)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(NSError(domain: "Invalid response", code: -1))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    throw APIError.authenticationFailed("Registration failed")
                }
                throw APIError.serverError(statusCode: httpResponse.statusCode)
            }
            
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            
            // Save tokens to keychain
            try keychainService.saveTokens(
                accessToken: tokenResponse.access_token,
                refreshToken: tokenResponse.refresh_token
            )
            
            // Store username in Config
            Config.currentUsername = username
            Config.currentUserEmail = email
            
            return tokenResponse
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Login
    
    /// Login with username or email and password
    /// - Parameters:
    ///   - usernameOrEmail: Username or email address
    ///   - password: User's password
    /// - Returns: Token response with access and refresh tokens
    /// - Throws: APIError if login fails
    func login(usernameOrEmail: String, password: String) async throws -> TokenResponse {
        guard let url = URL(string: "\(Config.apiBaseURL)/api/auth/login") else {
            throw APIError.invalidURL
        }
        
        let requestBody = LoginRequest(username_or_email: usernameOrEmail, password: password)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(NSError(domain: "Invalid response", code: -1))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    throw APIError.invalidCredentials
                }
                throw APIError.serverError(statusCode: httpResponse.statusCode)
            }
            
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            
            // Save tokens to keychain
            try keychainService.saveTokens(
                accessToken: tokenResponse.access_token,
                refreshToken: tokenResponse.refresh_token
            )
            
            return tokenResponse
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Token Refresh
    
    /// Refresh access token using refresh token
    /// - Parameter refreshToken: Valid refresh token
    /// - Returns: New token response with updated tokens
    /// - Throws: APIError if refresh fails
    func refresh(refreshToken: String) async throws -> TokenResponse {
        guard let url = URL(string: "\(Config.apiBaseURL)/api/auth/refresh") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["refresh_token": refreshToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(NSError(domain: "Invalid response", code: -1))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    throw APIError.tokenExpired
                }
                throw APIError.serverError(statusCode: httpResponse.statusCode)
            }
            
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            
            // Save new tokens to keychain
            try keychainService.saveTokens(
                accessToken: tokenResponse.access_token,
                refreshToken: tokenResponse.refresh_token
            )
            
            return tokenResponse
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Logout
    
    /// Logout current user by clearing stored tokens
    /// - Throws: Keychain errors if token removal fails
    func logout() throws {
        try keychainService.clearTokens()
        Config.currentUsername = nil
        Config.currentUserEmail = nil
    }
}
