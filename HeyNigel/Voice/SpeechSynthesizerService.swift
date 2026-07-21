import Foundation
import AVFoundation

/// Wraps `AVSpeechSynthesizer` with a configured "Nigel" voice/rate/pitch,
/// speaking whatever sentence `ResponsePhraser` produced. Shared by the
/// AirPods path (the Siri path instead returns an `IntentDialog` that Siri's
/// own voice speaks, so this service is never used there).
@MainActor
final class SpeechSynthesizerService: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private(set) var isSpeaking = false
    private var completion: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, completion: (() -> Void)? = nil) {
        self.completion = completion
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: AVSpeechSynthesisVoiceIdentifierAlex)
            ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.02
        utterance.pitchMultiplier = 0.95
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.completion?()
            self.completion = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.completion = nil
        }
    }
}
