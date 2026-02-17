import SwiftUI
import SwiftData

/// Root view that handles authentication routing
struct RootView: View {
    @State private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environment(authViewModel)
                    .task {
                        // Fetch bootstrap data if needed (once per 24h)
                        if BootstrapService.shared.needsRefresh {
                            try? await BootstrapService.shared.fetchBootstrapData()
                        }
                    }
            } else {
                OnboardingView(authViewModel: authViewModel)
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Photo.self, UserStats.self], inMemory: true)
}
