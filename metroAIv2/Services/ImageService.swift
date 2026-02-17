import Foundation
import UIKit

@MainActor
final class ImageService {
    static let shared = ImageService()

    private let fileManager = FileManager.default
    private lazy var documentsDirectory: URL = {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }()

    private init() {}

    // MARK: - Public Methods

    /// Saves a photo with compression and generates a thumbnail
    /// - Parameter image: The UIImage to save
    /// - Returns: Tuple of (localPath, thumbnailPath)
    func savePhoto(image: UIImage) throws -> (localPath: String, thumbnailPath: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let uuid = UUID().uuidString
        let filename = "\(timestamp)_\(uuid).jpg"
        let thumbnailFilename = "\(timestamp)_\(uuid)_thumb.jpg"

        // Resize and compress main image
        guard let resizedImage = resize(image: image, maxWidth: Config.maxImageWidth, maxHeight: Config.maxImageHeight),
              let imageData = resizedImage.jpegData(compressionQuality: Config.imageCompressionQuality) else {
            throw ImageError.compressionFailed
        }

        let imagePath = documentsDirectory.appendingPathComponent(filename)
        try imageData.write(to: imagePath)

        // Generate thumbnail
        guard let thumbnail = resize(image: image, maxWidth: Config.thumbnailSize, maxHeight: Config.thumbnailSize),
              let thumbnailData = thumbnail.jpegData(compressionQuality: 0.8) else {
            // Clean up main image if thumbnail fails
            try? fileManager.removeItem(at: imagePath)
            throw ImageError.thumbnailGenerationFailed
        }

        let thumbnailPath = documentsDirectory.appendingPathComponent(thumbnailFilename)
        try thumbnailData.write(to: thumbnailPath)

        return (localPath: filename, thumbnailPath: thumbnailFilename)
    }

    /// Loads an image from the given local path
    /// - Parameter localPath: The filename (not full path)
    /// - Returns: UIImage if found, nil otherwise
    func loadImage(from localPath: String) -> UIImage? {
        let fullPath = documentsDirectory.appendingPathComponent(localPath)
        guard let data = try? Data(contentsOf: fullPath) else { return nil }
        return UIImage(data: data)
    }

    /// Loads a thumbnail from the given local path
    /// - Parameter thumbnailPath: The thumbnail filename (not full path)
    /// - Returns: UIImage if found, nil otherwise
    func loadThumbnail(from thumbnailPath: String) -> UIImage? {
        let fullPath = documentsDirectory.appendingPathComponent(thumbnailPath)
        guard let data = try? Data(contentsOf: fullPath) else { return nil }
        return UIImage(data: data)
    }

    /// Deletes photo and thumbnail files
    /// - Parameters:
    ///   - localPath: The photo filename
    ///   - thumbnailPath: The thumbnail filename (optional)
    func deletePhoto(localPath: String, thumbnailPath: String?) {
        let photoURL = documentsDirectory.appendingPathComponent(localPath)
        try? fileManager.removeItem(at: photoURL)

        if let thumbPath = thumbnailPath {
            let thumbURL = documentsDirectory.appendingPathComponent(thumbPath)
            try? fileManager.removeItem(at: thumbURL)
        }
    }

    /// Reads image data for upload
    /// - Parameter localPath: The filename
    /// - Returns: Data if found
    func readImageData(from localPath: String) throws -> Data {
        let fullPath = documentsDirectory.appendingPathComponent(localPath)
        return try Data(contentsOf: fullPath)
    }

    // MARK: - Private Helpers

    private func resize(image: UIImage, maxWidth: CGFloat, maxHeight: CGFloat) -> UIImage? {
        let size = image.size
        let widthRatio = maxWidth / size.width
        let heightRatio = maxHeight / size.height
        let ratio = min(widthRatio, heightRatio, 1.0) // Don't upscale

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - ImageError

enum ImageError: LocalizedError {
    case compressionFailed
    case thumbnailGenerationFailed

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .thumbnailGenerationFailed:
            return "Failed to generate thumbnail"
        }
    }
}
