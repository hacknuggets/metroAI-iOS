import Foundation
import Observation

@MainActor
@Observable
final class StatsViewModel {
    // MARK: - State
    private(set) var leaderboard: [LeaderboardEntry] = []
    private(set) var userStats: UserStatsResponse?
    private(set) var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Public Methods

    func fetchStats() async {
        isLoading = true
        errorMessage = nil

        do {
            userStats = try await APIService.shared.fetchUserStats()
        } catch {
            errorMessage = "Ошибка загрузки статистики: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func fetchLeaderboard() async {
        isLoading = true
        errorMessage = nil

        do {
            leaderboard = try await APIService.shared.fetchLeaderboard(limit: 50)
        } catch {
            errorMessage = "Ошибка загрузки таблицы лидеров: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func refresh() async {
        await fetchStats()
        await fetchLeaderboard()
    }
}
