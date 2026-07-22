import Foundation
import HeyNigelCore

/// Captures a spoken question via the shared `SpeechCaptureEngine`, parses it
/// with `UtteranceParser`, and speaks the answer via `SpeechSynthesizerService`.
/// Triggered either by the in-app "Hold to Talk" button or by
/// `AirPodsRemoteController`'s stem-press callback — both just call
/// `startListening()`, so there's one capture pipeline behind two triggers.
@MainActor
@Observable
final class VoiceInputCoordinator {
    enum State: Equatable {
        case idle
        case listening
        case processing
        case speaking
    }

    private(set) var state: State = .idle
    private(set) var lastTranscript: String?
    private(set) var lastQuery: CaddyQuery?

    private let captureEngine: SpeechCaptureEngine
    private let parser = UtteranceParser()
    private let synthesizer: SpeechSynthesizerService
    /// Runs the parsed question through the active round's CaddyBrain and
    /// returns the sentence to speak, or nil if there's no active round to
    /// answer from. Async because answering needs a wind lookup.
    private let onQuery: (CaddyQuery) async -> String?

    init(captureEngine: SpeechCaptureEngine, synthesizer: SpeechSynthesizerService, onQuery: @escaping (CaddyQuery) async -> String?) {
        self.captureEngine = captureEngine
        self.synthesizer = synthesizer
        self.onQuery = onQuery
    }

    func startListening() {
        guard state == .idle else { return }

        state = .listening
        lastTranscript = nil
        synthesizer.speak("Yes?")

        captureEngine.onPartialTranscript = { [weak self] transcript in
            self?.lastTranscript = transcript
        }
        captureEngine.onFinalTranscript = { [weak self] transcript in
            self?.finishListening(transcript: transcript)
        }
        captureEngine.onError = { [weak self] in
            self?.state = .idle
        }
        captureEngine.start(silenceTimeout: 2.5, maxDuration: 8)
    }

    func cancelListening() {
        captureEngine.stop()
        state = .idle
    }

    private func finishListening(transcript: String?) {
        guard state == .listening else { return }
        state = .processing

        guard let transcript, !transcript.isEmpty else {
            state = .idle
            return
        }

        let query = parser.parse(transcript)
        lastQuery = query

        Task {
            let response = await onQuery(query) ?? "I don't have an active round going to answer that from."
            state = .speaking
            synthesizer.speak(response) { [weak self] in
                self?.state = .idle
            }
        }
    }
}
