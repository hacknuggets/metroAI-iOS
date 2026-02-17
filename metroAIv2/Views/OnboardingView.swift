import SwiftUI

/// Welcome screen shown to new users on first launch
struct OnboardingView: View {
    @Bindable var authViewModel: AuthViewModel
    @State private var showLogin = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [.blue.opacity(0.6), .blue],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // App Icon
                    Image(systemName: "camera.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundStyle(.white)
                        .shadow(radius: 10)
                    
                    VStack(spacing: 16) {
                        // Welcome Message
                        Text("Welcome to MetroAI")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        // Tagline
                        Text("Help improve metro systems\nby capturing defects")
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    // Get Started Button
                    Button {
                        showLogin = true
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
            }
            .navigationDestination(isPresented: $showLogin) {
                LoginView(authViewModel: authViewModel)
            }
        }
    }
}

#Preview {
    OnboardingView(authViewModel: AuthViewModel())
}
