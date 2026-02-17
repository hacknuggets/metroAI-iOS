import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class UploadService {
    static let shared = UploadService()

    // MARK: - Published State
    private(set) var isUploading: Bool = false
    private(set) var currentPhotoId: UUID?

    private init() {}

    // MARK: - Public Methods

    /// Process all pending photos in the upload queue
    /// - Parameter context: SwiftData ModelContext
    func processQueue(context: ModelContext) async {
        guard !isUploading else { return }

        isUploading = true
        defer { isUploading = false }

        // Fetch all photos ordered by capture date
        let descriptor = FetchDescriptor<Photo>(
            sortBy: [SortDescriptor(\.capturedAt, order: .forward)]
        )

        guard let allPhotos = try? context.fetch(descriptor) else {
            return
        }

        // Reset any stuck "uploading" photos back to pending (in case app was killed mid-upload)
        let stuckPhotos = allPhotos.filter { $0.uploadStatus == .uploading }
        for photo in stuckPhotos {
            print("🔄 Resetting stuck uploading photo: \(photo.id)")
            photo.uploadStatus = .pending
        }
        try? context.save()

        // Process pending photos
        let photos = allPhotos.filter { $0.uploadStatus == .pending }

        for photo in photos {
            await uploadPhoto(photo, context: context)
        }
    }

    /// Retry a single failed photo
    /// - Parameters:
    ///   - photo: The photo to retry
    ///   - context: SwiftData ModelContext
    func retryPhoto(_ photo: Photo, context: ModelContext) async {
        photo.uploadStatus = .pending
        photo.retryCount = 0
        try? context.save()
        await uploadPhoto(photo, context: context)
    }

    /// Retry all failed photos
    /// - Parameter context: SwiftData ModelContext
    func retryAllFailed(context: ModelContext) async {
        let descriptor = FetchDescriptor<Photo>()

        guard let allPhotos = try? context.fetch(descriptor) else {
            return
        }

        let failedPhotos = allPhotos.filter { $0.uploadStatus == .failed }

        for photo in failedPhotos {
            photo.uploadStatus = .pending
            photo.retryCount = 0
        }

        try? context.save()
        await processQueue(context: context)
    }

    // MARK: - Private Methods

    private func uploadPhoto(_ photo: Photo, context: ModelContext) async {
        currentPhotoId = photo.id

        // Set status to uploading
        photo.uploadStatus = .uploading
        try? context.save()

        do {
            // Read image data from disk
            let imageData = try ImageService.shared.readImageData(from: photo.localPath)

            // Upload to API
            let newPoints = try await APIService.shared.uploadPhoto(photo, imageData: imageData)

            // Mark as uploaded
            photo.uploadStatus = .uploaded
            photo.uploadedAt = Date()
            try? context.save()

            // Update local UserStats
            await updateUserStats(context: context, newPoints: newPoints)

            print("✅ Photo uploaded successfully: \(photo.id)")

        } catch {
            // Handle upload failure
            print("❌ Upload failed: \(error.localizedDescription)")

            // Check if it's a network error (keep retrying) or other error
            let isNetworkError = isNetworkError(error)

            if isNetworkError {
                // Network error - reset to pending for retry
                photo.uploadStatus = .pending
                print("🔄 Network error, will retry later")
            } else {
                // Other error - increment retry count
                photo.retryCount += 1

                if photo.retryCount >= Config.maxRetryAttempts {
                    photo.uploadStatus = .failed
                    print("💀 Max retries reached, marking as failed")
                } else {
                    photo.uploadStatus = .pending
                    print("🔄 Retry \(photo.retryCount)/\(Config.maxRetryAttempts)")
                }
            }

            try? context.save()
        }

        currentPhotoId = nil
    }

    private func isNetworkError(_ error: Error) -> Bool {
        // Check if error is network-related
        if let apiError = error as? APIError {
            switch apiError {
            case .networkError(let underlyingError):
                // Check the underlying error
                if let urlError = underlyingError as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
                        return true
                    default:
                        return false
                    }
                }
                // If it's wrapped but not a URLError, treat as network error
                return true
            case .invalidURL, .serverError, .unauthorized, .authenticationFailed, .tokenExpired, .invalidCredentials, .decodingError, .invalidFile:
                return false
            }
        }

        // Check for URLError network issues directly
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
                return true
            default:
                return false
            }
        }

        return false
    }

    private func updateUserStats(context: ModelContext, newPoints: Int) async {
        // Fetch or create UserStats for current user
        guard let username = Config.currentUsername else { return }

        let descriptor = FetchDescriptor<UserStats>(
            predicate: #Predicate { $0.userId == username }
        )

        let stats: UserStats
        if let existing = try? context.fetch(descriptor).first {
            stats = existing
        } else {
            stats = UserStats(userId: username)
            context.insert(stats)
        }

        stats.totalPoints = newPoints
        stats.photosUploaded += 1
        stats.lastSyncedAt = Date()

        try? context.save()
    }
}
