import Foundation

/// Parses a spoken transcript against an `ExpectedAnswer`. Unlike
/// `UtteranceParser` (which extracts a loose `CaddyQuery` from an open-ended
/// question), this expects one specific answer shape and returns
/// `.unrecognized` rather than guessing when the transcript doesn't fit —
/// callers re-prompt or drop to the manual fallback control instead of
/// silently accepting a bad parse.
public struct ConversationalAnswerParser: Sendable {
    public init() {}

    public func parse(_ transcript: String, expecting: ExpectedAnswer) -> ParsedAnswer {
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return .unrecognized(rawTranscript: transcript) }

        if isSkipPhrase(text) { return .skipped }

        switch expecting {
        case .freeText(let minWords):
            let wordCount = text.split(separator: " ").count
            return wordCount >= minWords ? .text(text) : .unrecognized(rawTranscript: transcript)

        case .yesNo:
            return parseYesNo(text) ?? .unrecognized(rawTranscript: transcript)

        case .number(let range):
            guard let value = Self.parseNumber(text) else { return .unrecognized(rawTranscript: transcript) }
            if let range, !range.contains(value) { return .unrecognized(rawTranscript: transcript) }
            return .number(value)

        case .choice(let options):
            return matchChoice(text, options: options) ?? .unrecognized(rawTranscript: transcript)
        }
    }

    private func isSkipPhrase(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let skipPhrases = ["skip", "i don't have one", "i don't have that", "don't carry", "none", "pass", "n/a", "not applicable"]
        return skipPhrases.contains(where: { lowered.contains($0) })
    }

    private func parseYesNo(_ text: String) -> ParsedAnswer? {
        let lowered = text.lowercased()
        let yesPhrases = ["yes", "yeah", "yep", "yup", "correct", "that's right", "that is right", "affirmative", "sure", "right"]
        let noPhrases = ["no", "nope", "nah", "incorrect", "that's wrong", "negative", "not right", "wrong"]
        if yesPhrases.contains(where: { lowered.contains($0) }) { return .yesNo(true) }
        if noPhrases.contains(where: { lowered.contains($0) }) { return .yesNo(false) }
        return nil
    }

    private func matchChoice(_ text: String, options: [String]) -> ParsedAnswer? {
        let lowered = text.lowercased()
        for (index, option) in options.enumerated() {
            if lowered.contains(option.lowercased()) {
                return .choice(index: index, matched: option)
            }
        }
        return nil
    }

    /// Digits first ("230", "230 yards", "about 230") since Apple's speech
    /// recognizer typically transcribes yardage-like utterances as digits
    /// already. Spelled-out numbers ("eighteen", "two hundred thirty") are a
    /// secondary fallback — note it doesn't handle colloquial shorthand like
    /// "one fifty" meaning 150 rather than 1 + 50; that ambiguity is left
    /// unresolved in favor of not guessing wrong.
    static func parseNumber(_ text: String) -> Double? {
        let lowered = text.lowercased()
        if let digitRange = lowered.range(of: #"\d+(\.\d+)?"#, options: .regularExpression) {
            return Double(lowered[digitRange])
        }
        return parseSpelledOutNumber(lowered)
    }

    private static let units: [String: Int] = [
        "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
        "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
        "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15,
        "sixteen": 16, "seventeen": 17, "eighteen": 18, "nineteen": 19,
    ]
    private static let tens: [String: Int] = [
        "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50,
        "sixty": 60, "seventy": 70, "eighty": 80, "ninety": 90,
    ]

    private static func parseSpelledOutNumber(_ text: String) -> Double? {
        let words = text.split(separator: " ").map(String.init).filter { $0 != "and" }
        guard !words.isEmpty else { return nil }

        var total = 0
        var current = 0
        var matchedAny = false

        for word in words {
            if let unit = units[word] {
                current += unit
                matchedAny = true
            } else if let ten = tens[word] {
                current += ten
                matchedAny = true
            } else if word == "hundred" {
                current = max(current, 1) * 100
                matchedAny = true
            }
        }
        total += current
        return matchedAny ? Double(total) : nil
    }
}
