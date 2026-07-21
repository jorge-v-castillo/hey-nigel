import SwiftUI
import SwiftData
import HeyNigelCore
import HeyNigelCourseData

struct ActiveRoundView: View {
    @Query private var preferences: [UserPreferencesRecord]
    @State private var roundSession: RoundSessionManager
    @State private var isStarting = false
    @State private var startError: String?

    private let courseDataProvider: HeyNigelCourseData.CourseDataProvider

    init(courseDataProvider: HeyNigelCourseData.CourseDataProvider) {
        self.courseDataProvider = courseDataProvider
        let deps = AppDependencies.shared
        _roundSession = State(initialValue: RoundSessionManager(
            caddyBrain: deps.caddyBrain,
            weatherProvider: deps.weatherProvider,
            responsePhraser: deps.responsePhraser,
            locationManager: LocationManager()
        ))
    }

    private var prefs: UserPreferencesRecord? { preferences.first }

    var body: some View {
        VStack(spacing: 20) {
            if let round = roundSession.activeRound {
                activeRoundContent(round: round)
            } else {
                startRoundContent
            }
        }
        .padding()
    }

    @ViewBuilder
    private var startRoundContent: some View {
        Spacer()
        Text("Ready to play \(prefs?.selectedCourseName ?? "your round")?")
            .font(.title2.bold())
            .multilineTextAlignment(.center)
        if let error = startError {
            Text(error).foregroundStyle(.red)
        }
        if isStarting {
            ProgressView()
        } else {
            Button("Start Round") {
                Task { await startRound() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        Spacer()
    }

    @ViewBuilder
    private func activeRoundContent(round: Round) -> some View {
        Text("Hole \(round.currentHoleNumber)")
            .font(.system(size: 48, weight: .bold, design: .rounded))

        if let phrase = roundSession.spokenPhrase {
            Text(phrase)
                .multilineTextAlignment(.center)
                .padding()
        } else if roundSession.isRefreshing {
            ProgressView()
        } else {
            Text("Waiting for a GPS fix\u{2026}")
                .foregroundStyle(.secondary)
        }

        Spacer()

        Button("End Round") {
            roundSession.endRound()
        }
        .buttonStyle(.bordered)
    }

    private func startRound() async {
        guard let prefs, let courseID = prefs.selectedCourseID, let tee = prefs.selectedTeeName else {
            startError = "Missing course setup — try onboarding again."
            return
        }
        isStarting = true
        startError = nil
        defer { isStarting = false }
        do {
            let course = try await courseDataProvider.fetchCourseDetail(id: courseID)
            roundSession.startRound(
                course: course,
                tee: tee,
                holeCount: prefs.holeCount,
                startingNine: prefs.startingNine ?? .front,
                clubProfile: prefs.clubProfile
            )
        } catch {
            startError = "Couldn't load that course. Try again."
        }
    }
}
