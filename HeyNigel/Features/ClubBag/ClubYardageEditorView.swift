import SwiftUI
import HeyNigelCore

/// Plain multi-row numeric editor for the club bag — used by Settings.
/// Editing yardages later is a quick tweak, not worth re-running a full
/// voice dialog for.
struct ClubYardageEditorView: View {
    @Binding var clubs: [ClubYardage]
    @State private var newClubName: String = ""
    @State private var newClubYardage: String = ""

    var body: some View {
        Section("Clubs") {
            ForEach(clubs.indices, id: \.self) { index in
                HStack {
                    Text(clubs[index].name)
                    Spacer()
                    TextField("Yards", value: Binding(
                        get: { clubs[index].averageCarryYards },
                        set: { clubs[index].averageCarryYards = $0 }
                    ), format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                }
            }
            .onDelete { indexSet in
                clubs.remove(atOffsets: indexSet)
            }

            HStack {
                TextField("Add a club", text: $newClubName)
                TextField("Yards", text: $newClubYardage)
                    .keyboardType(.numberPad)
                    .frame(width: 70)
                Button("Add") {
                    addCustomClub()
                }
                .disabled(newClubName.trimmingCharacters(in: .whitespaces).isEmpty || Double(newClubYardage) == nil)
            }
        }
    }

    private func addCustomClub() {
        guard !newClubName.trimmingCharacters(in: .whitespaces).isEmpty, let yardage = Double(newClubYardage) else { return }
        clubs.append(ClubYardage(
            name: newClubName,
            averageCarryYards: yardage,
            order: PlayerClubProfile.nextCustomClubOrder(existingCount: clubs.count)
        ))
        newClubName = ""
        newClubYardage = ""
    }
}
