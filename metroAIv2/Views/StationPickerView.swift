import SwiftUI
import CoreLocation

struct StationPickerView: View {
    @Binding var selectedStation: Station?
    let nearbyStations: [Station]
    let allStations: [Station]
    let currentLocation: CLLocation?

    @State private var searchText = ""

    var body: some View {
        List {
            // Nearby Stations Section
            if !nearbyStations.isEmpty {
                Section("Рядом") {
                    ForEach(nearbyStations) { station in
                        StationRow(
                            station: station,
                            isSelected: selectedStation?.id == station.id,
                            currentLocation: currentLocation
                        ) {
                            selectedStation = station
                        }
                    }
                }
            }

            // All Stations Section (searchable)
            Section("Все станции") {
                ForEach(filteredStations) { station in
                    StationRow(
                        station: station,
                        isSelected: selectedStation?.id == station.id,
                        currentLocation: currentLocation
                    ) {
                        selectedStation = station
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Поиск станции")
    }

    private var filteredStations: [Station] {
        if searchText.isEmpty {
            return allStations
        }
        return allStations.filter { station in
            station.name.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Station Row

private struct StationRow: View {
    let station: Station
    let isSelected: Bool
    let currentLocation: CLLocation?
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(station.name)
                        .foregroundColor(.primary)
                        .fontWeight(isSelected ? .semibold : .regular)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(lineColor)
                            .frame(width: 8, height: 8)

                        Text(station.lineName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    if let location = currentLocation, let distance = station.formattedDistance(from: location) {
                        Text(distance)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }

    private var lineColor: Color {
        // Simple color mapping based on line name
        // This is a placeholder - ideally line colors would come from the Line model
        switch station.lineId {
        case "1": return .red
        case "2": return .green
        case "3": return .blue
        case "4": return .cyan
        case "5": return .brown
        case "6": return .orange
        case "7": return .purple
        case "8": return .yellow
        case "9": return .gray
        default: return .gray
        }
    }
}

#Preview {
    StationPickerView(
        selectedStation: .constant(nil),
        nearbyStations: [
            Station(
                id: "1",
                name: "Парк Культуры",
                lineId: "1",
                lineName: "Сокольническая",
                latitude: 55.7352,
                longitude: 37.5931,
                isClosed: false
            )
        ],
        allStations: [
            Station(
                id: "1",
                name: "Парк Культуры",
                lineId: "1",
                lineName: "Сокольническая",
                latitude: 55.7352,
                longitude: 37.5931,
                isClosed: false
            ),
            Station(
                id: "2",
                name: "Октябрьская",
                lineId: "2",
                lineName: "Замоскворецкая",
                latitude: 55.7299,
                longitude: 37.6118,
                isClosed: false
            )
        ],
        currentLocation: nil
    )
}
