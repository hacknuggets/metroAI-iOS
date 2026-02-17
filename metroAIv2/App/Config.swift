import Foundation

/// Configuration constants for the MetroAI app
struct Config {
  // MARK: - API Configuration

  /// Backend API base URL - configurable per environment
  static var apiBaseURL: String {
    get {
      UserDefaults.standard.string(forKey: "apiBaseURL") ?? defaultAPIBaseURL
    }
    set {
      UserDefaults.standard.set(newValue, forKey: "apiBaseURL")
    }
  }

  private static let defaultAPIBaseURL = "http://147.45.153.120:8000"

  // MARK: - User Configuration

  /// User name for the current user
  static var userName: String {
    get {
      UserDefaults.standard.string(forKey: "userName") ?? "User\(Int.random(in: 1000...9999))"
    }
    set {
      UserDefaults.standard.set(newValue, forKey: "userName")
    }
  }

  /// User ID (generated once and persisted)
  static var userId: String {
    if let existingId = UserDefaults.standard.string(forKey: "userId") {
      return existingId
    }
    let newId = UUID().uuidString
    UserDefaults.standard.set(newId, forKey: "userId")
    return newId
  }

  // MARK: - Authentication State

  /// Current authenticated user's username
  static var currentUsername: String? {
    get {
      UserDefaults.standard.string(forKey: "currentUsername")
    }
    set {
      UserDefaults.standard.set(newValue, forKey: "currentUsername")
    }
  }

  /// Current authenticated user's email
  static var currentUserEmail: String? {
    get {
      UserDefaults.standard.string(forKey: "currentUserEmail")
    }
    set {
      UserDefaults.standard.set(newValue, forKey: "currentUserEmail")
    }
  }

  // MARK: - Image Processing Constants

  /// Maximum image dimensions (maintains aspect ratio)
  static let maxImageWidth: CGFloat = 1920
  static let maxImageHeight: CGFloat = 1080

  /// JPEG compression quality (0.0 - 1.0)
  static let imageCompressionQuality: CGFloat = 0.85

  /// Thumbnail size for queue view
  static let thumbnailSize: CGFloat = 300

  // MARK: - Upload Configuration

  /// Maximum retry attempts for failed uploads
  static let maxRetryAttempts = 3

  /// Upload timeout in seconds
  static let uploadTimeout: TimeInterval = 30

  // MARK: - Data Retention

  /// Days to keep uploaded photos before cleanup
  static let photoRetentionDays = 7

}
