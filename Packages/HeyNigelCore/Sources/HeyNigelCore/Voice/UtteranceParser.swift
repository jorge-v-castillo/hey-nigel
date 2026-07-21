import Foundation

/// Parses a free-form spoken transcript into a `CaddyQuery`. Unlike Siri's
/// template-based App Intents grammar (fixed phrases with parameter slots),
/// this path supports arbitrary phrasing — "I'm on hole 7, what's my distance
/// and club" — because the app owns its own speech-to-text and can just
/// keyword-match the result.
public struct UtteranceParser: Sendable {
    public init() {}

    public func parse(_ transcript: String) -> CaddyQuery {
        let text = transcript.lowercased()
        return CaddyQuery(
            holeOverride: Self.extractHoleNumber(from: text),
            queryType: Self.extractQueryType(from: text),
            target: Self.extractTarget(from: text)
        )
    }

    private static func extractHoleNumber(from text: String) -> Int? {
        guard let range = text.range(of: #"hole\s+(\d+)"#, options: .regularExpression) else {
            return nil
        }
        let digits = text[range].filter(\.isNumber)
        return Int(digits)
    }

    private static func extractTarget(from text: String) -> GreenTarget {
        if text.contains("front") { return .front }
        if text.contains("back") { return .back }
        return .center
    }

    private static func extractQueryType(from text: String) -> CaddyQueryType {
        let mentionsClub = text.contains("club") || text.contains("recommend") || text.contains("hit")
        let mentionsDistance = text.contains("distance") || text.contains("yards") || text.contains("far")

        switch (mentionsDistance, mentionsClub) {
        case (true, false): return .distance
        case (false, true): return .club
        default: return .both
        }
    }
}
