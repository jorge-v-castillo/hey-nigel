import SwiftUI

struct RoundDetailView: View {
    let round: RoundRecord

    private var sortedHoles: [HoleRecord] {
        round.holes.sorted { $0.holeNumber < $1.holeNumber }
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Course", value: round.courseName)
                LabeledContent("Tees", value: round.teeName)
                LabeledContent("Holes", value: "\(round.holeCount)")
                LabeledContent("Started", value: round.startedAt.formatted(date: .abbreviated, time: .shortened))
            }

            Section("Holes") {
                ForEach(sortedHoles) { hole in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Hole \(hole.holeNumber)").font(.headline)
                            if !hole.transitionWasConfirmedByVoice {
                                Text("corrected")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.orange.opacity(0.2), in: Capsule())
                            }
                        }
                        if let distance = hole.distanceAskedYards, let club = hole.recommendedClub {
                            Text("\(Int(distance)) yds \u{2014} \(club)\(hole.wasInterpolatedClubPick ? " (est.)" : "")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(round.courseName)
    }
}
