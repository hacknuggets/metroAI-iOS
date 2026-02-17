import Foundation

// MARK: - Token Response

/// Response model from authentication endpoints (register, login, refresh)
struct TokenResponse: Codable {
    let access_token: String
    let refresh_token: String
    let token_type: String
}

// MARK: - Request Models

/// Login request body for POST /api/auth/login
struct LoginRequest: Codable {
    let username_or_email: String
    let password: String
}

/// Register request body for POST /api/auth/register
struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
}

// MARK: - User Model

/// User model representing authenticated user data
struct User: Codable, Identifiable {
    let id: String
    let username: String
    let email: String
    let created_at: Date?
}
