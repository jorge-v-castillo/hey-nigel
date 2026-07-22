import Foundation

/// What kind of answer a `GuidedVoicePromptCoordinator` question expects —
/// drives both how `ConversationalAnswerParser` interprets the transcript and
/// which manual-fallback control `GuidedVoicePromptView` shows alongside the
/// mic button.
public enum ExpectedAnswer: Sendable {
    case freeText(minWords: Int)
    case yesNo
    case number(range: ClosedRange<Double>?)
    case choice(options: [String])
}

/// The result of parsing a transcript against an `ExpectedAnswer`.
/// `.unrecognized` lets the caller re-prompt or fall back to manual entry
/// instead of guessing.
public enum ParsedAnswer: Sendable, Equatable {
    case text(String)
    case yesNo(Bool)
    case number(Double)
    case choice(index: Int, matched: String)
    /// The player declined to answer (e.g. "I don't carry that club") —
    /// recognized regardless of the expected type, since skipping is always
    /// a valid response to an optional question.
    case skipped
    case unrecognized(rawTranscript: String)
}
