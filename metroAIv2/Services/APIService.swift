import Foundation

/// Error types for API operations
enum APIError: LocalizedError {
    case invalidURL
    case invalidFile
    case serverError(statusCode: Int)
    case networkError(Error)
    case decodingError
    case unauthorized
    case authenticationFailed(String)
    case tokenExpired
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidFile:
            return "Invalid or corrupted file"
        case .serverError(let statusCode):
            return "Server error: \(statusCode)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to decode server response"
        case .unauthorized:
            return "Unauthorized access"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .tokenExpired:
            return "Your session has expired. Please login again."
        case .invalidCredentials:
            return "Invalid username or password"
        }
    }
}

/// Response model for photo upload — API returns `{ "points": 101 }`
struct UploadResponse: Codable {
    let points: Int
}

/// Response model for user stats from GET /api/user/stats
struct UserStatsResponse: Codable {
    let userId: String
    let username: String
    let points: Int
    let photosUploaded: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case points
        case photosUploaded = "photos_uploaded"
    }
}

/// Service for handling API communication with the backend
@MainActor
final class APIService {
    static let shared = APIService()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Config.uploadTimeout
        self.session = URLSession(configuration: config)
    }

    // MARK: - Helpers

    /// Build an authenticated URLRequest with Bearer token
    private func authenticatedRequest(url: URL, method: String = "GET") throws -> URLRequest {
        guard let token = KeychainService.shared.getAccessToken() else {
            throw APIError.unauthorized
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    // MARK: - Photo Upload

    /// Uploads a photo to the server
    /// - Parameters:
    ///   - photo: Photo model containing metadata
    ///   - imageData: Compressed image data
    /// - Returns: Updated user points after upload
    func uploadPhoto(_ photo: Photo, imageData: Data) async throws -> Int {
        guard let url = URL(string: "\(Config.apiBaseURL)/api/photos/upload") else {
            throw APIError.invalidURL
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = try authenticatedRequest(url: url, method: "POST")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Encode metadata JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let metadataData = try encoder.encode(photo.buildMetadata())
        guard let metadataString = String(data: metadataData, encoding: .utf8) else {
            throw APIError.invalidFile
        }

        // Build multipart body
        var body = Data()

        // Add metadata JSON field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"metadata\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(metadataString)\r\n".data(using: .utf8)!)

        // Add image file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(NSError(domain: "Invalid response", code: -1))
            }

            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError(statusCode: httpResponse.statusCode)
            }

            let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
            return uploadResponse.points
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Annotation Update

    /// Updates annotation metadata for a photo
    /// - Parameters:
    ///   - photoId: Server-side photo ID
    ///   - photo: Photo with updated annotation data
    func uploadAnnotation(photoId: String, photo: Photo) async throws {
        guard let url = URL(string: "\(Config.apiBaseURL)/api/photos/\(photoId)/annotation") else {
            throw APIError.invalidURL
        }

        var request = try authenticatedRequest(url: url, method: "PATCH")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(photo.buildMetadata())

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "Invalid response", code: -1))
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - User Stats

    /// Fetches user statistics from the server
    /// - Returns: User stats response from API
    func fetchUserStats() async throws -> UserStatsResponse {
        guard let url = URL(string: "\(Config.apiBaseURL)/api/user/stats") else {
            throw APIError.invalidURL
        }

        let request = try authenticatedRequest(url: url)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "Invalid response", code: -1))
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        do {
            return try JSONDecoder().decode(UserStatsResponse.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }

    // MARK: - Leaderboard

    /// Fetches leaderboard from the server
    /// - Parameters:
    ///   - limit: Maximum number of entries to fetch (default: 50)
    ///   - offset: Offset for pagination (default: 0)
    /// - Returns: Array of leaderboard entries
    func fetchLeaderboard(limit: Int = 50, offset: Int = 0) async throws -> [LeaderboardEntry] {
        guard let url = URL(string: "\(Config.apiBaseURL)/api/leaderboard?limit=\(limit)&offset=\(offset)") else {
            throw APIError.invalidURL
        }

        let request = try authenticatedRequest(url: url)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "Invalid response", code: -1))
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode([LeaderboardEntry].self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }
}
