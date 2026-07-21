import Foundation
import Speech
import AVFoundation
import HeyNigelCore

/// Captures a spoken question via `SFSpeechRecognizer`, parses it with
/// `UtteranceParser`, and speaks the answer via `SpeechSynthesizerService`.
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

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var silenceTimer: Timer?
    private var maxDurationTimer: Timer?

    private let parser = UtteranceParser()
    private let synthesizer: SpeechSynthesizerService
    /// Runs the parsed question through the active round's CaddyBrain and
    /// returns the sentence to speak, or nil if there's no active round to
    /// answer from. Async because answering needs a wind lookup.
    private let onQuery: (CaddyQuery) async -> String?

    init(synthesizer: SpeechSynthesizerService, onQuery: @escaping (CaddyQuery) async -> String?) {
        self.synthesizer = synthesizer
        self.onQuery = onQuery
    }

    func startListening() {
        guard state == .idle else { return }
        guard let speechRecognizer, speechRecognizer.isAvailable else { return }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if speechRecognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        // Captures `request` directly rather than reading `self.recognitionRequest`
        // inside the closure — the tap fires on an internal audio thread, and
        // SFSpeechAudioBufferRecognitionRequest.append is safe to call from
        // there, but hopping back through a MainActor-isolated property would not be.
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            recognitionRequest = nil
            return
        }

        state = .listening
        lastTranscript = nil
        synthesizer.speak("Yes?")

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                self?.handleRecognitionResult(result, error: error)
            }
        }

        resetSilenceTimer()
        maxDurationTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.finishListening() }
        }
    }

    func cancelListening() {
        stopCapture()
        state = .idle
    }

    private func stopCapture() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        silenceTimer?.invalidate()
        silenceTimer = nil
        maxDurationTimer?.invalidate()
        maxDurationTimer = nil
    }

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.finishListening() }
        }
    }

    private func handleRecognitionResult(_ result: SFSpeechRecognitionResult?, error: Error?) {
        guard state == .listening else { return }
        if let result {
            lastTranscript = result.bestTranscription.formattedString
            resetSilenceTimer()
            if result.isFinal {
                finishListening()
            }
        }
        if error != nil {
            finishListening()
        }
    }

    private func finishListening() {
        guard state == .listening else { return }
        let transcript = lastTranscript
        stopCapture()
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
