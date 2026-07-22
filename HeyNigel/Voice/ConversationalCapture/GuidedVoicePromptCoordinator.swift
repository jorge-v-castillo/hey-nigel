import Foundation
import HeyNigelCore

/// Drives a single conversational Q&A step: Nigel speaks a question, the
/// user answers by mic tap or the always-visible manual fallback, and the
/// answer is parsed against an `ExpectedAnswer`. Built on the same shared
/// `SpeechCaptureEngine` instance used by `VoiceInputCoordinator` — callers
/// are responsible for not calling `ask` while that coordinator is mid-listen,
/// and vice versa.
///
/// `ask(_:expecting:)` reads as a linear script, so onboarding's name/nickname/
/// club loop, round-setup's course/holes/nine/tees, and hole-transition
/// confirmations can each just `await` a sequence of questions instead of
/// hand-rolling a state machine per screen.
@MainActor
@Observable
final class GuidedVoicePromptCoordinator {
    enum Phase: Equatable {
        case idle
        case asking
        case waitingForAnswer
        case listening
        case reviewing
    }

    private(set) var phase: Phase = .idle
    private(set) var currentQuestion: String = ""
    private(set) var currentExpectation: ExpectedAnswer = .yesNo
    private(set) var liveTranscript: String = ""
    private(set) var reviewError: String?
    var reviewText: String = ""

    private let captureEngine: SpeechCaptureEngine
    private let synthesizer: SpeechSynthesizerService
    private let answerParser = ConversationalAnswerParser()
    private var continuation: CheckedContinuation<ParsedAnswer, Never>?

    init(captureEngine: SpeechCaptureEngine, synthesizer: SpeechSynthesizerService) {
        self.captureEngine = captureEngine
        self.synthesizer = synthesizer
    }

    func ask(_ question: String, expecting: ExpectedAnswer) async -> ParsedAnswer {
        currentQuestion = question
        currentExpectation = expecting
        liveTranscript = ""
        reviewText = ""
        reviewError = nil
        phase = .asking

        synthesizer.speak(question) { [weak self] in
            self?.phase = .waitingForAnswer
        }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    /// Speaks a plain statement (no answer expected) — e.g. "Very good,
    /// let's begin your round" — and returns once Nigel's done talking.
    func say(_ text: String) async {
        await withCheckedContinuation { continuation in
            synthesizer.speak(text) {
                continuation.resume()
            }
        }
    }

    func startListening() {
        guard phase == .waitingForAnswer else { return }
        phase = .listening
        liveTranscript = ""

        captureEngine.onPartialTranscript = { [weak self] transcript in
            self?.liveTranscript = transcript
        }
        captureEngine.onFinalTranscript = { [weak self] transcript in
            guard let self else { return }
            guard let transcript, !transcript.isEmpty else {
                self.phase = .waitingForAnswer
                return
            }
            self.handleCapturedText(transcript)
        }
        captureEngine.onError = { [weak self] in
            self?.phase = .waitingForAnswer
        }
        captureEngine.start(silenceTimeout: 2.5, maxDuration: 8)
    }

    /// Called by the manual fallback control: typed text for `.freeText`/
    /// `.number`, or a spoken transcript that reached here via voice too.
    func submitManualAnswer(_ text: String) {
        handleCapturedText(text)
    }

    /// Yes/No and choice-list answers resolve immediately on tap — a button
    /// press is already unambiguous, unlike free text or a spoken number.
    func resolveDirectly(_ answer: ParsedAnswer) {
        resume(with: answer)
    }

    /// Explicit "Skip" affordance a caller can render for optional questions
    /// (e.g. a club yardage during onboarding) — resolves immediately, same
    /// as saying "skip" out loud.
    func skip() {
        resume(with: .skipped)
    }

    func confirmReview() {
        let parsed = answerParser.parse(reviewText, expecting: currentExpectation)
        if case .unrecognized = parsed {
            reviewError = "Didn't quite catch that — try again."
            return
        }
        resume(with: parsed)
    }

    func cancelReviewAndRetry() {
        reviewText = ""
        reviewError = nil
        phase = .waitingForAnswer
    }

    private func handleCapturedText(_ text: String) {
        let parsed = answerParser.parse(text, expecting: currentExpectation)
        if case .skipped = parsed {
            resume(with: .skipped)
            return
        }

        switch currentExpectation {
        case .yesNo, .choice:
            if case .unrecognized = parsed {
                phase = .waitingForAnswer
            } else {
                resume(with: parsed)
            }
        case .freeText, .number:
            reviewText = text
            reviewError = nil
            phase = .reviewing
        }
    }

    private func resume(with answer: ParsedAnswer) {
        phase = .idle
        continuation?.resume(returning: answer)
        continuation = nil
    }
}
