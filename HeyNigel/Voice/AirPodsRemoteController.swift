import Foundation
import MediaPlayer
import AVFoundation

/// The AirPods long-press that invokes Siri is OS-reserved and can't be
/// intercepted by any third-party API. Nigel instead uses a single stem
/// press/tap, which the system delivers as a play/pause remote-command event
/// — but only while this app is the active "Now Playing" owner, which
/// requires an active `AVAudioSession` and populated now-playing info. This
/// is the riskiest, most device-iteration-heavy part of the whole app; the
/// in-app "Hold to Talk" button (wired to the same `onTrigger` closure) is
/// the guaranteed fallback regardless of how reliably this routes.
@MainActor
final class AirPodsRemoteController {
    private let commandCenter = MPRemoteCommandCenter.shared()
    private var onTrigger: (() -> Void)?
    private var routeChangeObserver: NSObjectProtocol?

    func start(onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Non-fatal: without this, stem-press routing may not reach this
            // app, but the in-app Hold-to-Talk button still works.
        }
        configureNowPlayingInfo()

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.onTrigger?()
            return .success
        }
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.onTrigger?()
            return .success
        }
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.onTrigger?()
            return .success
        }

        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.configureNowPlayingInfo() }
        }
    }

    func stop() {
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        if let routeChangeObserver {
            NotificationCenter.default.removeObserver(routeChangeObserver)
        }
        routeChangeObserver = nil
        onTrigger = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    /// Populating now-playing info (even with placeholder text, no real
    /// audio) is what makes the system route AirPods stem-press events to
    /// this app's remote command targets instead of another app's.
    private func configureNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: "Hey Nigel — Caddy Active",
            MPNowPlayingInfoPropertyPlaybackRate: 1.0,
        ]
    }
}
