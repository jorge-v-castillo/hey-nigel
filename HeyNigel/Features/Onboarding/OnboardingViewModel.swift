import Foundation
import SwiftData
import HeyNigelCore

@MainActor
@Observable
final class OnboardingViewModel {
    var step: OnboardingStep = .welcome

    let permissions: PermissionsManager
    let guidedPrompt: GuidedVoicePromptCoordinator

    private(set) var fullName: String = ""
    private(set) var nickname: String?
    private(set) var clubDrafts: [ClubYardage] = []
    private(set) var currentClubIndex = 0
    private(set) var currentClubName: String = ""

    private let declineWords: Set<String> = ["no", "nope", "none", "nah", "no thanks", "not really"]

    init(guidedPrompt: GuidedVoicePromptCoordinator, permissions: PermissionsManager = PermissionsManager()) {
        self.guidedPrompt = guidedPrompt
        self.permissions = permissions
    }

    var totalClubCount: Int { PlayerClubProfile.requiredOnboardingClubs.count }

    func advance() {
        guard let next = step.next else { return }
        step = next
    }

    func runNameStep() async {
        let answer = await guidedPrompt.ask("What's your full name?", expecting: .freeText(minWords: 1))
        if case .text(let name) = answer {
            fullName = name
        }
        advance()
    }

    func runNicknameStep() async {
        let answer = await guidedPrompt.ask(
            "Do you have a nickname you'd like me to use instead? If not, just say no.",
            expecting: .freeText(minWords: 1)
        )
        if case .text(let text) = answer, !declineWords.contains(text.lowercased()) {
            nickname = text
        }
        advance()
    }

    /// Walks the 9 required clubs in order, each individually skippable.
    /// Skipped/unrecognized clubs are simply left out of `clubDrafts` —
    /// `ClubBagInterpolator` fills the gap later from whichever anchors the
    /// player did provide.
    func runClubLoop() async {
        for (index, clubName) in PlayerClubProfile.requiredOnboardingClubs.enumerated() {
            currentClubIndex = index
            currentClubName = clubName
            let answer = await guidedPrompt.ask(
                "About how far do you hit your \(clubName)? Say the yardage, or say skip if you don't carry one.",
                expecting: .number(range: 20...400)
            )
            if case .number(let yards) = answer {
                clubDrafts.append(ClubYardage(name: clubName, averageCarryYards: yards, order: index))
            }
        }
        advance()
    }

    func skipCurrentClub() {
        guidedPrompt.skip()
    }

    var canFinishOnboarding: Bool { !clubDrafts.isEmpty }

    func complete(modelContext: ModelContext) {
        let record = UserPreferencesStore.fetchOrCreate(in: modelContext)
        record.fullName = fullName
        record.nickname = nickname
        record.replaceClubProfile(PlayerClubProfile(clubs: clubDrafts), in: modelContext)
        record.onboardingCompleted = true
        try? modelContext.save()
    }
}
