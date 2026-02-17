import SwiftUI

struct StatsView: View {
    @State private var viewModel = StatsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading && viewModel.userStats == nil {
                    ProgressView("Загрузка...")
                        .padding()
                } else {
                    if let stats = viewModel.userStats {
                        UserStatsCard(stats: stats)
                            .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Таблица лидеров")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)

                        if viewModel.leaderboard.isEmpty {
                            Text("Таблица лидеров пуста")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(viewModel.leaderboard) { entry in
                                LeaderboardRow(
                                    entry: entry,
                                    isCurrentUser: entry.username == Config.currentUsername
                                )
                                .padding(.horizontal)
                            }
                        }
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Статистика")
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.refresh()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        try? AuthService.shared.logout()
                    }
                } label: {
                    Label("Выход", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
    }
}

// MARK: - User Stats Card

private struct UserStatsCard: View {
    let stats: UserStatsResponse

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("\(stats.points)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.blue)

                Text("Баллов")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            Divider()

            HStack {
                Image(systemName: "photo.fill")
                    .foregroundColor(.blue)
                Text("Фото загружено:")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(stats.photosUploaded)")
                    .font(.headline)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Leaderboard Row

private struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 40, height: 40)

                Text("\(entry.rank)")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.username)
                    .font(.headline)
                    .foregroundColor(isCurrentUser ? .blue : .primary)

                if isCurrentUser {
                    Text("Вы")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            Text("\(entry.points)")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(isCurrentUser ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1:
            return .yellow
        case 2:
            return .gray
        case 3:
            return .orange
        default:
            return .blue
        }
    }
}

#Preview {
    NavigationStack {
        StatsView()
    }
}
