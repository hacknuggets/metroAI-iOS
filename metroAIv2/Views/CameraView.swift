import SwiftUI
import CoreLocation

struct CameraView: View {
    @State private var viewModel = CameraViewModel()
    @State private var capturedImage: UIImage?

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary)

                        Text("Нажмите, чтобы сфотографировать дефект")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }

                Spacer()

                Button {
                    viewModel.showCamera = true
                } label: {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 80, height: 80)
                        )
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Камера")
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
        }
    }
}

#Preview {
    NavigationStack {
        CameraView()
    }
}
