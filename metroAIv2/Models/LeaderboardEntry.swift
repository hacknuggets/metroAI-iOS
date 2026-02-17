import Foundation

/// Leaderboard entry from GET /api/leaderboard
struct LeaderboardEntry: Codable, Identifiable {
    let userId: String
    let username: String
    let points: Int
    let rank: Int

    var id: String { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case points
        case rank
    }
}
