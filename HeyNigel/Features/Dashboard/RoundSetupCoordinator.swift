import Foundation
import HeyNigelCore
import HeyNigelCourseData

/// Sequences the voice-driven "Begin Round" conversation: GPS course guess →
/// confirm (or free-text search + disambiguation) → holes → front/back nine
/// → tees → a closing confirmation line. Runs entirely on
/// `GuidedVoicePromptCoordinator.ask`, so it reads as a linear script instead
/// of a hand-rolled state machine.
@MainActor
struct RoundSetupCoordinator {
    struct Result {
        let course: Course
        let tee: String
        let holeCount: Int
        let startingNine: Nine
    }

    private let guidedPrompt: GuidedVoicePromptCoordinator
    private let courseDataProvider: CourseDataProvider
    private let locationManager: LocationManager

    init(guidedPrompt: GuidedVoicePromptCoordinator, courseDataProvider: CourseDataProvider, locationManager: LocationManager) {
        self.guidedPrompt = guidedPrompt
        self.courseDataProvider = courseDataProvider
        self.locationManager = locationManager
    }

    func run(displayName: String?) async -> Result? {
        guard let course = await resolveCourse() else { return nil }

        let holeCount = await askHoleCount()
        let startingNine = await askStartingNine()
        let tee = await askTee(for: course)

        let greeting = displayName.map { "Very good, \($0), let's begin your round." } ?? "Very good, let's begin your round."
        await guidedPrompt.say(greeting)

        return Result(course: course, tee: tee, holeCount: holeCount, startingNine: startingNine)
    }

    private func resolveCourse() async -> Course? {
        if let location = await locationManager.currentLocationOnce(),
           let nearestSummary = try? await courseDataProvider.nearestCourse(to: location) {
            let confirmed = await guidedPrompt.ask("Are we playing \(nearestSummary.name) today?", expecting: .yesNo)
            if case .yesNo(true) = confirmed {
                return try? await courseDataProvider.fetchCourseDetail(id: nearestSummary.id)
            }
        }
        return await searchForCourse()
    }

    private func searchForCourse(attemptsRemaining: Int = 3) async -> Course? {
        guard attemptsRemaining > 0 else { return nil }

        let nameAnswer = await guidedPrompt.ask("Which course are we playing today?", expecting: .freeText(minWords: 1))
        guard case .text(let courseName) = nameAnswer,
              let results = try? await courseDataProvider.searchCourses(query: courseName),
              !results.isEmpty else {
            return await searchForCourse(attemptsRemaining: attemptsRemaining - 1)
        }

        if results.count == 1 {
            return try? await courseDataProvider.fetchCourseDetail(id: results[0].id)
        }

        let choiceAnswer = await guidedPrompt.ask(
            "Which one — \(results.map(\.name).joined(separator: ", "))?",
            expecting: .choice(options: results.map(\.name))
        )
        guard case .choice(let index, _) = choiceAnswer else {
            return await searchForCourse(attemptsRemaining: attemptsRemaining - 1)
        }
        return try? await courseDataProvider.fetchCourseDetail(id: results[index].id)
    }

    private func askHoleCount() async -> Int {
        let answer = await guidedPrompt.ask("How many holes will you be playing today?", expecting: .number(range: 1...18))
        if case .number(let value) = answer, value < 13.5 {
            return 9
        }
        return 18
    }

    private func askStartingNine() async -> Nine {
        let answer = await guidedPrompt.ask("Will we be starting on the front or back nine?", expecting: .choice(options: ["Front", "Back"]))
        if case .choice(let index, _) = answer, index == 1 {
            return .back
        }
        return .front
    }

    private func askTee(for course: Course) async -> String {
        let teeOptions = course.teeSets.map(\.name)
        guard !teeOptions.isEmpty else { return "White" }
        let answer = await guidedPrompt.ask(
            "Which tees will you be hitting from — \(teeOptions.joined(separator: ", "))?",
            expecting: .choice(options: teeOptions)
        )
        if case .choice(_, let matched) = answer {
            return matched
        }
        return teeOptions[0]
    }
}
