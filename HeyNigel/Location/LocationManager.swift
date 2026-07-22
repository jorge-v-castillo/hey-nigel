import Foundation
import CoreLocation
import HeyNigelCore

/// Thin CoreLocation wrapper. Best accuracy and a ~12m distance filter are
/// enough for green-scale hole detection without draining the battery over a
/// ~4 hour round; background updates keep hole tracking correct with the
/// phone locked or pocketed, which is why the `location` UIBackgroundMode is
/// declared in project.yml's Info.plist.
@MainActor
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var onLocationUpdate: ((Coordinate) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 12
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = false
        manager.allowsBackgroundLocationUpdates = true
    }

    func startUpdating() {
        guard manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse else {
            return
        }
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    /// A single fresh fix for round-setup's "are we playing X today?" GPS
    /// match — temporarily takes over `onLocationUpdate` and restores
    /// whatever handler (e.g. `RoundSessionManager`'s) was set before it,
    /// so this is safe to call even while another owner holds the callback.
    /// Resolves nil on timeout (no fix, or location not authorized yet).
    func currentLocationOnce(timeout: TimeInterval = 5) async -> Coordinate? {
        let previousHandler = onLocationUpdate
        return await withCheckedContinuation { continuation in
            var resumed = false
            func finish(_ coordinate: Coordinate?) {
                guard !resumed else { return }
                resumed = true
                onLocationUpdate = previousHandler
                continuation.resume(returning: coordinate)
            }
            onLocationUpdate = { coordinate in
                finish(coordinate)
            }
            startUpdating()
            Task {
                try? await Task.sleep(for: .seconds(timeout))
                finish(nil)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        let coordinate = Coordinate(latitude: latest.coordinate.latitude, longitude: latest.coordinate.longitude)
        Task { @MainActor in
            self.onLocationUpdate?(coordinate)
        }
    }
}
