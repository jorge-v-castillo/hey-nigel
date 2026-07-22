import SwiftUI
import SwiftData

struct HistoryListView: View {
    @Query(sort: \RoundRecord.startedAt, order: .reverse) private var rounds: [RoundRecord]

    var body: some View {
        List(rounds) { round in
            NavigationLink {
                RoundDetailView(round: round)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(round.courseName).font(.headline)
                    Text("\(round.teeName) tees \u{2022} \(round.holeCount) holes \u{2022} \(round.startedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Previous Games")
        .overlay {
            if rounds.isEmpty {
                ContentUnavailableView("No rounds yet", systemImage: "figure.golf")
            }
        }
    }
}
