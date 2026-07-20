import Foundation
import CoreLocation
import Speech
import AVFoundation

/// Wraps the three permissions onboarding needs up front: Location, Microphone,
/// and Speech Recognition. (Siri needs no separate authorization step under
/// the modern App Intents/AppShortcutsProvider framework used in Phase 5 —
/// that's only required for the legacy SiriKit intents API.)
///
/// All of these must be granted during onboarding, not requested later,
/// because a permission sheet can't surface cleanly from a headless Siri
/// intent invocation or a backgrounded AirPods press-to-talk trigger.
@MainActor
@Observable
final class PermissionsManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    var locationStatus: CLAuthorizationStatus
    var microphoneGranted: Bool = false
    var speechStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    override init() {
        locationStatus = .notDetermined
        super.init()
        locationManager.delegate = self
        locationStatus = locationManager.authorizationStatus
    }

    func requestLocationWhenInUse() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Hole tracking needs to keep working with the phone locked or pocketed
    /// for a ~4 hour round. iOS only offers "Always" as a second prompt after
    /// "When In Use" has already been granted, so this is called after that.
    func requestLocationAlways() {
        locationManager.requestAlwaysAuthorization()
    }

    func requestMicrophone() async {
        microphoneGranted = await AVAudioApplication.requestRecordPermission()
    }

    func requestSpeechRecognition() async {
        speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.locationStatus = status
        }
    }
}
