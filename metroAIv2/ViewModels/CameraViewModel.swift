import Foundation
import SwiftUI
import SwiftData
import CoreLocation
import Observation

@MainActor
@Observable
final class CameraViewModel {
    // MARK: - State
    var capturedImage: UIImage?
    var selectedDefect: Defect?
    var selectedStation: Station?
    var notes: String = ""
    var nearbyStations: [Station] = []

    var showCamera: Bool = false
    var showAnnotationForm: Bool = false
    var isSubmitting: Bool = false
    var isFetchingLocation: Bool = false
    var errorMessage: String?

    private var currentLocation: CLLocation?

    // MARK: - Computed Properties

    var canSubmit: Bool {
        capturedImage != nil && selectedDefect != nil
    }

    var defectCategories: [String: DefectCategory] {
        BootstrapService.shared.defectTypes?.categories ?? [:]
    }

    var allStations: [Station] {
        BootstrapService.shared.stations
    }

    // MARK: - Public Methods

    func onPhotoCaptured(image: UIImage) {
        capturedImage = image
        showCamera = false
        fetchNearbyStations()
        showAnnotationForm = true
    }

    func fetchNearbyStations() {
        Task {
            isFetchingLocation = true
            errorMessage = nil

            do {
                // Request permission if needed
                if !LocationService.shared.isAuthorized {
                    LocationService.shared.requestPermission()
                    // Wait a bit for permission dialog
                    try await Task.sleep(for: .seconds(0.5))

                    // Check again
                    if !LocationService.shared.isAuthorized {
                        errorMessage = "Разрешите доступ к геолокации в настройках"
                        isFetchingLocation = false
                        return
                    }
                }

                let location = try await LocationService.shared.requestLocation()
                currentLocation = location

                // Find nearby stations within 500m radius
                nearbyStations = BootstrapService.shared.nearbyStations(location: location, radius: 500)

                print("📍 Found \(nearbyStations.count) nearby stations")
            } catch {
                print("❌ Location error: \(error)")
                errorMessage = "Не удалось получить местоположение: \(error.localizedDescription)"
                nearbyStations = []
            }

            isFetchingLocation = false
        }
    }

    func submit(modelContext: ModelContext) {
        guard canSubmit, let image = capturedImage, let defect = selectedDefect else {
            return
        }

        Task {
            isSubmitting = true
            errorMessage = nil

            do {
                // Save image to disk
                let (localPath, thumbnailPath) = try ImageService.shared.savePhoto(image: image)

                // Create Photo record
                let photo = Photo(
                    localPath: localPath,
                    defectTypeId: defect.id,
                    notes: notes.isEmpty ? nil : notes,
                    uploadStatus: .pending,
                    capturedAt: Date(),
                    thumbnailPath: thumbnailPath,
                    latitude: currentLocation?.coordinate.latitude,
                    longitude: currentLocation?.coordinate.longitude,
                    locationAccuracy: currentLocation?.horizontalAccuracy,
                    stationId: selectedStation?.id
                )

                modelContext.insert(photo)
                try modelContext.save()

                // Trigger background upload
                await UploadService.shared.processQueue(context: modelContext)

                // Reset form
                reset()
                showAnnotationForm = false
            } catch {
                errorMessage = "Ошибка сохранения фото: \(error.localizedDescription)"
            }

            isSubmitting = false
        }
    }

    func reset() {
        capturedImage = nil
        selectedDefect = nil
        selectedStation = nil
        notes = ""
        nearbyStations = []
        currentLocation = nil
        errorMessage = nil
    }
}
