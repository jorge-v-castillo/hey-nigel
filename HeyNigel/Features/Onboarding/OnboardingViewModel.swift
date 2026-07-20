import Foundation
import SwiftData
import HeyNigelCore
import HeyNigelCourseData

@MainActor
@Observable
final class OnboardingViewModel {
    var step: OnboardingStep = .welcome

    var searchQuery: String = ""
    var searchResults: [CourseSummary] = []
    var isSearching: Bool = false
    var searchError: String?
    var selectedCourse: Course?

    var selectedTeeName: String?

    var holeCount: Int = 18
    var startingNine: Nine = .front

    var driverYardageText: String = ""
    var sevenIronYardageText: String = ""
    var wedgeYardageText: String = ""

    let permissions: PermissionsManager

    private let courseDataProvider: CourseDataProvider

    init(courseDataProvider: CourseDataProvider, permissions: PermissionsManager = PermissionsManager()) {
        self.courseDataProvider = courseDataProvider
        self.permissions = permissions
    }

    var canAdvanceFromCourseSearch: Bool { selectedCourse != nil }
    var canAdvanceFromTeeSelection: Bool { selectedTeeName != nil }
    var canAdvanceFromClubYardages: Bool { parsedClubProfile != nil }

    var parsedClubProfile: PlayerClubProfile? {
        guard
            let driver = Double(driverYardageText), driver > 0,
            let sevenIron = Double(sevenIronYardageText), sevenIron > 0,
            let wedge = Double(wedgeYardageText), wedge > 0
        else { return nil }
        return PlayerClubProfile(clubs: [
            ClubYardage(name: "Driver", averageCarryYards: driver, order: 0),
            ClubYardage(name: "7 Iron", averageCarryYards: sevenIron, order: 7),
            ClubYardage(name: "Wedge", averageCarryYards: wedge, order: 10),
        ])
    }

    func search() async {
        isSearching = true
        searchError = nil
        defer { isSearching = false }
        do {
            searchResults = try await courseDataProvider.searchCourses(query: searchQuery)
        } catch {
            searchResults = []
            searchError = "Couldn't search courses right now."
        }
    }

    func selectCourse(_ summary: CourseSummary) async {
        do {
            let course = try await courseDataProvider.fetchCourseDetail(id: summary.id)
            selectedCourse = course
            selectedTeeName = course.teeSets.first?.name
        } catch {
            searchError = "Couldn't load that course's details."
        }
    }

    func advance() {
        guard let next = step.next else { return }
        step = next
    }

    func back() {
        guard let previous = step.previous else { return }
        step = previous
    }

    /// Persists onboarding choices and marks setup complete. Called once from
    /// the Ready screen; the app's root view then routes to Home based on
    /// `UserPreferencesRecord.onboardingCompleted`.
    func complete(modelContext: ModelContext) {
        guard let course = selectedCourse, let tee = selectedTeeName, let profile = parsedClubProfile else { return }
        let record = UserPreferencesStore.fetchOrCreate(in: modelContext)
        record.selectedCourseID = course.id
        record.selectedCourseName = course.name
        record.selectedTeeName = tee
        record.holeCount = holeCount
        record.startingNine = startingNine
        record.replaceClubProfile(profile, in: modelContext)
        record.onboardingCompleted = true
        try? modelContext.save()
    }
}
