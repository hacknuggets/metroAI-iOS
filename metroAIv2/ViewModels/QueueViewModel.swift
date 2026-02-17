import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class QueueViewModel {
    // MARK: - State
    private(set) var isProcessing: Bool = false

    // MARK: - Public Methods

    func processQueue(context: ModelContext) {
        Task {
            isProcessing = true
            await UploadService.shared.processQueue(context: context)
            isProcessing = false
        }
    }

    func retryPhoto(_ photo: Photo, context: ModelContext) {
        Task {
            isProcessing = true
            await UploadService.shared.retryPhoto(photo, context: context)
            isProcessing = false
        }
    }

    func retryAll(context: ModelContext) {
        Task {
            isProcessing = true
            await UploadService.shared.retryAllFailed(context: context)
            isProcessing = false
        }
    }

    func deletePhoto(_ photo: Photo, context: ModelContext) {
        // Delete image files from disk
        ImageService.shared.deletePhoto(localPath: photo.localPath, thumbnailPath: photo.thumbnailPath)

        // Remove from SwiftData
        context.delete(photo)
        try? context.save()
    }
}
