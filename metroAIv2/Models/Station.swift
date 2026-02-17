import Foundation
import CoreLocation

/// Metro station model
struct Station: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let lineId: String
    let lineName: String
    let latitude: Double?
    let longitude: Double?
    let isClosed: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case lineId = "line_id"
        case lineName = "line_name"
        case latitude = "geo_lat"
        case longitude = "geo_lon"
        case isClosed = "is_closed"
    }

    init(id: String, name: String, lineId: String, lineName: String, latitude: Double? = nil, longitude: Double? = nil, isClosed: Bool = false) {
        self.id = id
        self.name = name
        self.lineId = lineId
        self.lineName = lineName
        self.latitude = latitude
        self.longitude = longitude
        self.isClosed = isClosed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        lineId = try container.decode(String.self, forKey: .lineId)
        lineName = try container.decode(String.self, forKey: .lineName)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        isClosed = try container.decodeIfPresent(Bool.self, forKey: .isClosed) ?? false
    }

    /// Calculate distance from a location
    /// - Parameter location: CLLocation to measure from
    /// - Returns: Distance in meters, or nil if station has no coordinates
    func distance(from location: CLLocation) -> CLLocationDistance? {
        guard let latitude, let longitude else { return nil }
        let stationLocation = CLLocation(latitude: latitude, longitude: longitude)
        return location.distance(from: stationLocation)
    }

    /// Formatted distance string
    /// - Parameter location: CLLocation to measure from
    /// - Returns: Human-readable distance (e.g. "250m" or "1.2km"), or nil if no coordinates
    func formattedDistance(from location: CLLocation) -> String? {
        guard let meters = distance(from: location) else { return nil }
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            return String(format: "%.1fkm", meters / 1000)
        }
    }
}

/// Result of station resolution
enum StationResolution {
    /// Single station found nearby
    case single(Station)

    /// Multiple stations found (user must choose)
    case ambiguous([Station])

    /// No stations found nearby
    case none
}
