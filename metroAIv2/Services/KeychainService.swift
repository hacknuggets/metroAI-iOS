import Foundation
import KeychainAccess

/// Service for secure storage of authentication tokens in iOS Keychain
final class KeychainService {
    static let shared = KeychainService()
    
    private let keychain: Keychain
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    
    private init() {
        self.keychain = Keychain(service: "com.metroai.tokens")
    }
    
    // MARK: - Token Storage
    
    /// Saves both access and refresh tokens securely to the Keychain
    /// - Parameters:
    ///   - accessToken: JWT access token
    ///   - refreshToken: JWT refresh token
    /// - Throws: Keychain access errors
    func saveTokens(accessToken: String, refreshToken: String) throws {
        try keychain.set(accessToken, key: accessTokenKey)
        try keychain.set(refreshToken, key: refreshTokenKey)
    }
    
    /// Retrieves the access token from Keychain
    /// - Returns: Access token string if available, nil otherwise
    func getAccessToken() -> String? {
        return try? keychain.get(accessTokenKey)
    }
    
    /// Retrieves the refresh token from Keychain
    /// - Returns: Refresh token string if available, nil otherwise
    func getRefreshToken() -> String? {
        return try? keychain.get(refreshTokenKey)
    }
    
    /// Clears all stored tokens from the Keychain (logout)
    /// - Throws: Keychain access errors
    func clearTokens() throws {
        try keychain.remove(accessTokenKey)
        try keychain.remove(refreshTokenKey)
    }
}
