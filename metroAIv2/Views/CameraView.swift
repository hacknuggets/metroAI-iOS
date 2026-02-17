import SwiftUI
import CoreLocation

struct CameraView: View {
    @State private var viewModel = CameraViewModel()
    @State private var capturedImage: UIImage?
    @State private var buttonScale: CGFloat = 1.0
    @State private var ringRotation: Double = 0

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.06, green: 0.06, blue: 0.12), location: 0),
                    .init(color: Color(red: 0.10, green: 0.10, blue: 0.18), location: 0.5),
                    .init(color: Color(red: 0.06, green: 0.06, blue: 0.12), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Center content
                if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .white.opacity(0.05), radius: 20)
                        .padding(.horizontal, 24)
                        .transition(.opacity)
                } else {
                    VStack(spacing: 28) {
                        // Viewfinder icon
                        ZStack {
                            // Corners
                            ViewfinderShape()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                .frame(width: 120, height: 120)

                            Image(systemName: "camera")
                                .font(.system(size: 44, weight: .light))
                                .foregroundStyle(.white.opacity(0.6))
                        }

                        VStack(spacing: 8) {
                            Text("Сфотографируйте дефект")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)

                            Text("Нажмите кнопку внизу")
                                .font(.system(size: 15))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }

                Spacer()

                // Shutter button
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    viewModel.showCamera = true
                } label: {
                    ZStack {
                        // Animated outer ring
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [.white.opacity(0.6), .white.opacity(0.1), .white.opacity(0.6)],
                                    center: .center,
                                    startAngle: .degrees(ringRotation),
                                    endAngle: .degrees(ringRotation + 360)
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 84, height: 84)

                        // Inner white circle
                        Circle()
                            .fill(.white)
                            .frame(width: 68, height: 68)
                    }
                    .scaleEffect(buttonScale)
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            withAnimation(.easeInOut(duration: 0.1)) {
                                buttonScale = 0.9
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                buttonScale = 1.0
                            }
                        }
                )
                .padding(.bottom, 50)
            }
        }
        .navigationTitle("Камера")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fullScreenCover(isPresented: $viewModel.showCamera) {
            ImagePicker(selectedImage: $capturedImage)
        }
        .sheet(isPresented: $viewModel.showAnnotationForm) {
            AnnotationFormView(viewModel: viewModel)
        }
        .onChange(of: capturedImage) { _, newImage in
            if let image = newImage {
                viewModel.onPhotoCaptured(image: image)
                capturedImage = nil
            }
        }
        .onAppear {
            if LocationService.shared.authorizationStatus == .notDetermined {
                LocationService.shared.requestPermission()
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
        }
    }
}

// MARK: - Viewfinder Shape

/// Draws the four corner brackets of a viewfinder
private struct ViewfinderShape: Shape {
    func path(in rect: CGRect) -> Path {
        let length: CGFloat = 24
        let cornerRadius: CGFloat = 4
        var path = Path()

        // Top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY),
                          control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))

        // Top-right
        path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius),
                          control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))

        // Bottom-right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY),
                          control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - length, y: rect.maxY))

        // Bottom-left
        path.move(to: CGPoint(x: rect.minX + length, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius),
                          control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - length))

        return path
    }
}

#Preview {
    NavigationStack {
        CameraView()
    }
}
