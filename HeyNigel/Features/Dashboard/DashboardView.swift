import SwiftUI
import SwiftData
import HeyNigelCore
import HeyNigelCourseData

/// The post-onboarding home screen. A large "Begin Round" button when idle
/// triggers the voice-driven `RoundSetupCoordinator` conversation; once a
/// round starts, this same screen hosts the in-round `ActiveRoundView`
/// content. Bottom nav ("Previous Games" / "Settings") only shows when idle
/// — Begin Round is the clear focal point, not an equal tab alongside them.
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferencesRecord]

    @State private var roundSession: RoundSessionManager
    @State private var voiceCoordinator: VoiceInputCoordinator
    @State private var guidedPrompt: GuidedVoicePromptCoordinator
    @State private var airPodsController = AirPodsRemoteController()
    @State private var isSettingUpRound = false

    private let courseDataProvider: HeyNigelCourseData.CourseDataProvider
    private let locationManager: LocationManager

    init(courseDataProvider: HeyNigelCourseData.CourseDataProvider) {
        self.courseDataProvider = courseDataProvider
        let deps = AppDependencies.shared
        let location = LocationManager()
        self.locationManager = location

        let session = RoundSessionManager(
            caddyBrain: deps.caddyBrain,
            weatherProvider: deps.weatherProvider,
            responsePhraser: deps.responsePhraser,
            locationManager: location
        )
        _roundSession = State(initialValue: session)

        // One shared mic session for both the free-form in-round Q&A and the
        // guided round-setup/hole-transition prompts — never two competing
        // AVAudioEngines.
        let sharedCaptureEngine = SpeechCaptureEngine()
        let sharedSynthesizer = SpeechSynthesizerService()
        _voiceCoordinator = State(initialValue: VoiceInputCoordinator(
            captureEngine: sharedCaptureEngine,
            synthesizer: sharedSynthesizer,
            onQuery: { query in await session.answerQuery(query) }
        ))
        _guidedPrompt = State(initialValue: GuidedVoicePromptCoordinator(
            captureEngine: sharedCaptureEngine,
            synthesizer: sharedSynthesizer
        ))
    }

    private var prefs: UserPreferencesRecord? { preferences.first }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isSettingUpRound {
                    GuidedVoicePromptView(coordinator: guidedPrompt)
                } else if roundSession.activeRound != nil {
                    ActiveRoundView(
                        roundSession: roundSession,
                        voiceCoordinator: voiceCoordinator,
                        guidedPrompt: guidedPrompt,
                        onEndRound: endRound
                    )
                } else {
                    idleContent
                }
            }
            .padding()
            .navigationTitle("Hey Nigel")
            .onAppear {
                let historyStore = RoundHistoryStore(modelContext: modelContext)
                roundSession.onRoundEvent = { event in
                    historyStore.handle(event)
                }
            }
        }
    }

    @ViewBuilder
    private var idleContent: some View {
        Spacer()
        Button {
            Task { await beginRound() }
        } label: {
            Text("Begin\nRound")
                .multilineTextAlignment(.center)
                .font(.title2.bold())
                .frame(width: 180, height: 180)
                .background(Circle().fill(Color.accentColor))
                .foregroundStyle(.white)
                .accessibilityLabel("Begin Round")
        }
        Spacer()
        HStack(spacing: 40) {
            NavigationLink("Previous Games") { HistoryListView() }
            NavigationLink("Settings") { SettingsView() }
        }
        .font(.subheadline)
    }

    private func beginRound() async {
        isSettingUpRound = true
        defer { isSettingUpRound = false }

        let setup = RoundSetupCoordinator(
            guidedPrompt: guidedPrompt,
            courseDataProvider: courseDataProvider,
            locationManager: locationManager
        )
        guard let result = await setup.run(displayName: prefs?.displayName) else { return }

        roundSession.startRound(
            course: result.course,
            tee: result.tee,
            holeCount: result.holeCount,
            startingNine: result.startingNine,
            clubProfile: prefs?.clubProfile ?? PlayerClubProfile(clubs: [])
        )
        let coordinator = voiceCoordinator
        airPodsController.start { coordinator.startListening() }
    }

    private func endRound() {
        voiceCoordinator.cancelListening()
        airPodsController.stop()
        roundSession.endRound()
    }
}
