import SwiftUI
import SwiftData

/// Main tab view container for the app
struct MainTabView: View {
    var body: some View {
        TabView {
            CameraView()
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                }
            
            UploadQueueView()
                .tabItem {
                    Label("Queue", systemImage: "list.bullet")
                }
            
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Photo.self, UserStats.self], inMemory: true)
}
