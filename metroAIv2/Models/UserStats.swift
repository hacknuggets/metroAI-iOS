import Foundation
import SwiftData

/// SwiftData model for tracking user statistics and gamification
@Model
final class UserStats {
    /// User identifier
    var userId: String
    
    /// Total number of photos successfully uploaded
    var photosUploaded: Int
    
    /// Total points earned
    var totalPoints: Int
    
    /// Last time stats were synced with server
    var lastSyncedAt: Date?
    
    /// Current rank on leaderboard (0 if not ranked)
    var currentRank: Int
    
    init(
        userId: String,
        photosUploaded: Int = 0,
        totalPoints: Int = 0,
        lastSyncedAt: Date? = nil,
        currentRank: Int = 0
    ) {
        self.userId = userId
        self.photosUploaded = photosUploaded
        self.totalPoints = totalPoints
        self.lastSyncedAt = lastSyncedAt
        self.currentRank = currentRank
    }
}
