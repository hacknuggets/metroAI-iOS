import Foundation
import SwiftData

/// Upload status for photos
enum UploadStatus: String, Codable {
    case pending
    case uploading
    case uploaded
    case failed
}

/// Photo upload metadata matching API contract
struct PhotoUploadMetadata: Codable {
    var latitude: Double?
    var longitude: Double?
    var stationId: String?      // Station ID from bootstrap
    var capturedAt: Date?
    var defectId: String        // Defect UUID (REQUIRED)
    var notes: String?
    
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case stationId = "station_id"
        case capturedAt = "captured_at"
        case defectId = "defect_id"
        case notes
    }
}

/// SwiftData model for captured photos with defect metadata
@Model
final class Photo {
    /// Unique identifier
    var id: UUID
    
    /// Local file path to the saved image
    var localPath: String
    
    /// ID of the defect type (Seat Damage, Graffiti, etc.)
    var defectTypeId: String
    
    /// Optional user notes
    var notes: String?
    
    /// Current upload status
    var uploadStatus: UploadStatus
    
    /// Timestamp when photo was captured
    var capturedAt: Date
    
    /// Timestamp when photo was successfully uploaded
    var uploadedAt: Date?
    
    /// Number of times upload has been retried
    var retryCount: Int
    
    /// Local thumbnail path (300x300)
    var thumbnailPath: String?
    
    // MARK: - Location Metadata (API Contract)
    
    /// GPS latitude coordinate (-90 to 90)
    var latitude: Double?
    
    /// GPS longitude coordinate (-180 to 180)
    var longitude: Double?
    
    // MARK: - Additional Metadata (Local Only)
    
    /// Location accuracy in meters (not sent to API)
    var locationAccuracy: Double?
    
    /// ID of the station where the photo was taken
    var stationId: String?


    
    init(
        id: UUID = UUID(),
        localPath: String,
        defectTypeId: String,
        notes: String? = nil,
        uploadStatus: UploadStatus = .pending,
        capturedAt: Date = Date(),
        uploadedAt: Date? = nil,
        retryCount: Int = 0,
        thumbnailPath: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationAccuracy: Double? = nil,
        stationId: String? = nil
    ) {
        self.id = id
        self.localPath = localPath
        self.defectTypeId = defectTypeId
        self.notes = notes
        self.uploadStatus = uploadStatus
        self.capturedAt = capturedAt
        self.uploadedAt = uploadedAt
        self.retryCount = retryCount
        self.thumbnailPath = thumbnailPath
        self.latitude = latitude
        self.longitude = longitude
        self.locationAccuracy = locationAccuracy
        self.stationId = stationId
    }
    
    // MARK: - Computed Properties
    
    /// Whether this photo has valid GPS coordinates
    var hasLocation: Bool {
        latitude != nil && longitude != nil
    }
    
    /// Formatted location string for display
    var locationString: String? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return String(format: "%.6f, %.6f", lat, lon)
    }
    
    // MARK: - API Metadata
    
    /// Build metadata object for API upload
    func buildMetadata() -> PhotoUploadMetadata {
        PhotoUploadMetadata(
            latitude: latitude,
            longitude: longitude,
            stationId: stationId,
            capturedAt: capturedAt,
            defectId: defectTypeId,
            notes: notes
        )
    }
}
