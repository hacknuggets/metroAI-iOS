import SwiftUI
import SwiftData

/// Main tab view container for the app
struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                CameraView()
            }
            .tabItem {
                Label("Камера", systemImage: "camera.fill")
            }

            NavigationStack {
                UploadQueueView()
            }
            .tabItem {
                Label("Очередь", systemImage: "list.bullet")
            }

            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("Статистика", systemImage: "chart.bar.fill")
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Photo.self, UserStats.self], inMemory: true)
}
