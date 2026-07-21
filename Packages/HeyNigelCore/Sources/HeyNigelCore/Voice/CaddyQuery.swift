import Foundation

public enum CaddyQueryType: String, Codable, Sendable {
    case distance, club, both
}

/// The parsed shape of a spoken question. Produced by `UtteranceParser` for
/// the AirPods path (free-form phrasing) and, later, by the Siri App Intent's
/// parameters (template phrasing) — one shared shape so `CaddyBrain` and
/// `ResponsePhraser` never need to know which activation path asked.
public struct CaddyQuery: Codable, Hashable, Sendable {
    public var holeOverride: Int?
    public var queryType: CaddyQueryType
    public var target: GreenTarget

    public init(holeOverride: Int? = nil, queryType: CaddyQueryType = .both, target: GreenTarget = .center) {
        self.holeOverride = holeOverride
        self.queryType = queryType
        self.target = target
    }
}
