import Foundation
import CoreLocation

/// Manages bootstrap data (defects, stations, lines)
@Observable
@MainActor
final class BootstrapService {
    static let shared = BootstrapService()
    
    // Reference data
    var defectTypes: DefectTypesData?
    var stations: [Station] = []
    var lines: [Line] = []
    
    // State
    var isLoading = false
    var error: Error?
    var lastFetchedAt: Date?
    
    private init() {
        loadCachedData()
    }
    
    // MARK: - Fetch from API
    
    func fetchBootstrapData() async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        let url = URL(string: "\(Config.apiBaseURL)/api/bootstrap")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let response = try JSONDecoder().decode(BootstrapResponse.self, from: data)
        
        // Update state
        self.defectTypes = response.defectTypes
        self.stations = response.stations
        self.lines = response.lines
        self.lastFetchedAt = Date()
        
        // Cache for offline
        cacheData(response)
        
        print("✅ Bootstrap loaded: \(stations.count) stations, \(defectTypes?.allDefects.count ?? 0) defects, \(lines.count) lines")
    }
    
    // MARK: - Caching
    
    private func cacheData(_ response: BootstrapResponse) {
        if let encoded = try? JSONEncoder().encode(response) {
            UserDefaults.standard.set(encoded, forKey: "bootstrapData")
            UserDefaults.standard.set(Date(), forKey: "bootstrapCachedAt")
        }
    }
    
    private func loadCachedData() {
        guard let data = UserDefaults.standard.data(forKey: "bootstrapData"),
              let cached = try? JSONDecoder().decode(BootstrapResponse.self, from: data) else {
            return
        }
        
        self.defectTypes = cached.defectTypes
        self.stations = cached.stations
        self.lines = cached.lines
        self.lastFetchedAt = UserDefaults.standard.object(forKey: "bootstrapCachedAt") as? Date
        
        print("📦 Loaded cached bootstrap data")
    }
    
    // MARK: - Helpers
    
    /// Find station by ID
    func station(byId id: String) -> Station? {
        stations.first { $0.id == id }
    }
    
    /// Find line by ID
    func line(byId id: String) -> Line? {
        lines.first { $0.id == id }
    }
    
    /// Find defect by UUID
    func defect(byId id: String) -> Defect? {
        defectTypes?.defect(byId: id)
    }
    
    /// Find nearby stations (open stations only, within radius)
    func nearbyStations(location: CLLocation, radius: Double = 500) -> [Station] {
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
    
    /// Check if data needs refresh (> 24 hours old)
    var needsRefresh: Bool {
        guard let lastFetch = lastFetchedAt else { return true }
        return Date().timeIntervalSince(lastFetch) > 86400
    }
}