import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class LocationService: NSObject {
    static let shared = LocationService()

    // MARK: - Published State
    private(set) var currentLocation: CLLocation?
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // MARK: - Private
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Public Methods

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestLocation() async throws -> CLLocation {
        guard isAuthorized else {
            print("❌ Location not authorized: \(authorizationStatus.rawValue)")
            throw LocationError.notAuthorized
        }

        print("📍 Requesting location...")
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            print("✅ Location received: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            currentLocation = location
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("❌ Location error: \(error.localizedDescription)")
            locationContinuation?.resume(throwing: error)
            locationContinuation = nil
        }
    }
}

// MARK: - LocationError

enum LocationError: LocalizedError {
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Location access not authorized"
        }
    }
}
