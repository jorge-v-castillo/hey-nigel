import SwiftUI
import HeyNigelCore
import HeyNigelCourseData
import HeyNigelWeather

/// Phase 0/1 smoke-test screen: exercises the full mock stack (course fixture
/// -> mock wind -> CaddyBrain -> ResponsePhraser) end to end inside a real
/// iOS app target, proving the SPM packages link and run correctly on device/
/// Simulator, not just under `swift test`. Replaced by real onboarding + the
/// active-round UI in later phases.
struct ContentView: View {
    @State private var phrase: String = "Loading Nigel's advice\u{2026}"

    var body: some View {
        VStack(spacing: 16) {
            Text("Hey Nigel")
                .font(.largeTitle.bold())
            Text(phrase)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .task {
            await loadSampleRecommendation()
        }
    }

    private func loadSampleRecommendation() async {
        do {
            let courseProvider = MockCourseDataProvider()
            let course = try await courseProvider.fetchCourseDetail(id: "fixture-sunridge")
            guard let hole = course.hole(number: 7) else {
                phrase = "Couldn't find hole 7 in the fixture course."
                return
            }
            let teeBox = hole.teeBoxes.first { $0.name == "White" } ?? hole.teeBoxes[0]

            let weatherProvider = MockWeatherProvider(
                observation: WindObservation(speedMph: 10, directionFromDegrees: 0)
            )
            let wind = try await weatherProvider.currentWind(at: teeBox.coordinate)

            let profile = PlayerClubProfile(clubs: [
                ClubYardage(name: "Driver", averageCarryYards: 230, order: 0),
                ClubYardage(name: "7 Iron", averageCarryYards: 150, order: 7),
                ClubYardage(name: "Sand Wedge", averageCarryYards: 80, order: 12),
            ])

            let brain = DefaultCaddyBrain()
            let recommendation = brain.recommendation(
                playerLocation: teeBox.coordinate,
                green: hole.green,
                target: .center,
                wind: wind,
                clubs: profile
            )

            phrase = ResponsePhraser().phrase(hole: hole.number, target: .center, recommendation: recommendation)
        } catch {
            phrase = "Something went wrong: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ContentView()
}
