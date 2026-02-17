import CoreLocation

/// Convenience wrapper around BootstrapService for station resolution
@Observable
@MainActor
final class StationService {
    static let shared = StationService()

    private init() {}

    /// All stations from bootstrap data
    private var stations: [Station] {
        BootstrapService.shared.stations
    }

    // MARK: - Station Resolution

    func resolveStation(location: CLLocation) -> StationResolution {
        let nearby = findNearbyStations(location: location, radius: 500)

        switch nearby.count {
        case 0: return .none
        case 1: return .single(nearby[0])
        default: return .ambiguous(nearby)
        }
    }

    func findNearbyStations(location: CLLocation, radius: Double) -> [Station] {
        stations
            .filter { station in
                guard !station.isClosed,
                      let distance = station.distance(from: location) else {
                    return false
                }
                return distance <= radius
            }
            .sorted { s1, s2 in
                let d1 = s1.distance(from: location) ?? Double.infinity
                let d2 = s2.distance(from: location) ?? Double.infinity
                return d1 < d2
            }
    }
}
