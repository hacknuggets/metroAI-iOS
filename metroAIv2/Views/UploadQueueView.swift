import SwiftUI
import SwiftData

struct UploadQueueView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Photo.capturedAt, order: .reverse) private var photos: [Photo]

    @State private var viewModel = QueueViewModel()

    var body: some View {
        Group {
            if photos.isEmpty {
                ContentUnavailableView(
                    "Пока нет фотографий",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("Перейдите на вкладку Камера, чтобы сфотографировать дефект")
                )
            } else {
                List {
                    ForEach(photos) { photo in
                        PhotoRow(photo: photo, viewModel: viewModel)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deletePhoto(photos[index], context: modelContext)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Очередь загрузки")
        .toolbar {
            if hasFailedPhotos {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.retryAll(context: modelContext)
                    } label: {
                        if viewModel.isProcessing {
                            ProgressView()
                        } else {
                            Label("Повторить все", systemImage: "arrow.clockwise")
                        }
                    }
                    .disabled(viewModel.isProcessing)
                }
            }
        }
        .onAppear {
            if hasPendingPhotos {
                viewModel.processQueue(context: modelContext)
            }
        }
    }

    private var hasFailedPhotos: Bool {
        photos.contains { $0.uploadStatus == .failed }
    }

    private var hasPendingPhotos: Bool {
        photos.contains { $0.uploadStatus == .pending }
    }
}

// MARK: - Photo Row

private struct PhotoRow: View {
    let photo: Photo
    let viewModel: QueueViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 12) {
            if let thumbnailPath = photo.thumbnailPath,
               let thumbnail = ImageService.shared.loadThumbnail(from: thumbnailPath) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                if let defect = BootstrapService.shared.defect(byId: photo.defectTypeId) {
                    Text(defect.name)
                        .font(.headline)
                } else {
                    Text("Дефект #\(photo.defectTypeId.prefix(8))")
                        .font(.headline)
                }

                if let stationId = photo.stationId,
                   let station = BootstrapService.shared.station(byId: stationId) {
                    Text(station.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Text(photo.capturedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            StatusBadge(status: photo.uploadStatus)

            if photo.uploadStatus == .failed {
                Button {
                    viewModel.retryPhoto(photo, context: modelContext)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: UploadStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption)

            Text(statusText)
                .font(.caption2)
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.15))
        .clipShape(Capsule())
    }

    private var iconName: String {
        switch status {
        case .pending:
            return "clock"
        case .uploading:
            return "arrow.up.circle"
        case .uploaded:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    private var statusText: String {
        switch status {
        case .pending:
            return "Ожидание"
        case .uploading:
            return "Загрузка"
        case .uploaded:
            return "Загружено"
        case .failed:
            return "Ошибка"
        }
    }

    private var statusColor: Color {
        switch status {
        case .pending:
            return .gray
        case .uploading:
            return .blue
        case .uploaded:
            return .green
        case .failed:
            return .red
        }
    }
}

#Preview {
    NavigationStack {
        UploadQueueView()
            .modelContainer(for: Photo.self, inMemory: true)
    }
}
