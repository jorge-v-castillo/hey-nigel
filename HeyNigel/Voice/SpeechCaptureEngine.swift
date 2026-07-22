import Foundation
import Speech
import AVFoundation

/// Raw speech-capture plumbing (`AVAudioEngine` + `SFSpeechRecognizer` +
/// silence/max-duration cutoffs), extracted out of `VoiceInputCoordinator` so
/// it can be shared with `GuidedVoicePromptCoordinator` too — one mic session
/// owner at a time, never two competing `AVAudioEngine`s. Callers gate their
/// own exclusivity (only call `start()` when nothing else is capturing).
@MainActor
final class SpeechCaptureEngine {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var silenceTimer: Timer?
    private var maxDurationTimer: Timer?
    private var silenceTimeout: TimeInterval = 2.5

    private(set) var isCapturing = false
    private var lastTranscript: String?

    var onPartialTranscript: ((String) -> Void)?
    /// nil transcript means nothing was captured before the cutoff.
    var onFinalTranscript: ((String?) -> Void)?
    var onError: (() -> Void)?

    func start(silenceTimeout: TimeInterval = 2.5, maxDuration: TimeInterval = 8) {
        guard !isCapturing else { return }
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            onError?()
            return
        }
        self.silenceTimeout = silenceTimeout

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            onError?()
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
            onError?()
            return
        }

        isCapturing = true
        lastTranscript = nil

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                self?.handleRecognitionResult(result, error: error)
            }
        }

        resetSilenceTimer()
        maxDurationTimer = Timer.scheduledTimer(withTimeInterval: maxDuration, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.finish() }
        }
    }

    func stop() {
        guard isCapturing else { return }
        stopCapture()
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
        isCapturing = false
    }

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.finish() }
        }
    }

    private func handleRecognitionResult(_ result: SFSpeechRecognitionResult?, error: Error?) {
        guard isCapturing else { return }
        if let result {
            let transcript = result.bestTranscription.formattedString
            lastTranscript = transcript
            onPartialTranscript?(transcript)
            resetSilenceTimer()
            if result.isFinal {
                finish()
            }
        }
        if error != nil {
            finish()
        }
    }

    private func finish() {
        guard isCapturing else { return }
        let transcript = lastTranscript
        stopCapture()
        onFinalTranscript?(transcript)
    }
}
