import SwiftUI
import HeyNigelCore

struct TeeSelectionView: View {
    var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Which tees are you playing?")
                .font(.title2.bold())

            if let course = viewModel.selectedCourse {
                List(course.teeSets, id: \.name) { tee in
                    Button {
                        viewModel.selectedTeeName = tee.name
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(tee.name).font(.headline)
                                if let yardage = tee.totalYardage {
                                    Text("\(yardage) yards total").font(.subheadline).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if viewModel.selectedTeeName == tee.name {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
                .listStyle(.plain)
            } else {
                Text("No course selected yet.").foregroundStyle(.secondary)
            }

            Button("Continue") { viewModel.advance() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.canAdvanceFromTeeSelection)
        }
        .padding()
    }
}
