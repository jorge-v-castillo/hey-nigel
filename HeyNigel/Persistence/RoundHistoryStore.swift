import Foundation
import SwiftData
import HeyNigelCore

/// Translates `RoundEvent`s emitted by `RoundSessionManager` into persisted
/// `RoundRecord`/`HoleRecord` rows, keeping `RoundSessionManager` itself free
/// of a SwiftData import.
@MainActor
final class RoundHistoryStore {
    private let modelContext: ModelContext
    private var activeRecord: RoundRecord?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func handle(_ event: RoundEvent) {
        switch event {
        case .roundStarted(let course, let tee, let holeCount, let startingNine):
            let record = RoundRecord(
                courseName: course.name,
                courseID: course.id,
                teeName: tee,
                holeCount: holeCount,
                startingNineRaw: startingNine.rawValue,
                startedAt: Date()
            )
            modelContext.insert(record)
            activeRecord = record

        case .holeRecorded(let snapshot):
            // Upsert by hole number — a hole's recommendation refreshes
            // repeatedly while the player stays on it, and only the latest
            // should be kept, per "one row per hole" (not a full log).
            guard let activeRecord else { return }
            if let existing = activeRecord.holes.first(where: { $0.holeNumber == snapshot.holeNumber }) {
                existing.transitionWasConfirmedByVoice = snapshot.transitionWasConfirmedByVoice
                existing.distanceAskedYards = snapshot.distanceAskedYards
                existing.recommendedClub = snapshot.recommendedClub
                existing.windDescription = snapshot.windDescription
                existing.wasInterpolatedClubPick = snapshot.wasInterpolatedClubPick
            } else {
                let holeRecord = HoleRecord(
                    holeNumber: snapshot.holeNumber,
                    enteredAt: snapshot.enteredAt,
                    transitionWasConfirmedByVoice: snapshot.transitionWasConfirmedByVoice,
                    distanceAskedYards: snapshot.distanceAskedYards,
                    recommendedClub: snapshot.recommendedClub,
                    windDescription: snapshot.windDescription,
                    wasInterpolatedClubPick: snapshot.wasInterpolatedClubPick
                )
                activeRecord.holes.append(holeRecord)
            }

        case .roundEnded(let endedAt):
            activeRecord?.endedAt = endedAt
            activeRecord = nil
        }
        try? modelContext.save()
    }
}
