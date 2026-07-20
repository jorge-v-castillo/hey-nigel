import SwiftUI
import HeyNigelCore
import HeyNigelCourseData

struct CourseSearchView: View {
    var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Which course are you playing?")
                .font(.title2.bold())

            TextField("Search courses", text: Binding(
                get: { viewModel.searchQuery },
                set: { viewModel.searchQuery = $0 }
            ))
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal)
            .onSubmit { Task { await viewModel.search() } }

            if viewModel.isSearching {
                ProgressView()
            } else if let error = viewModel.searchError {
                Text(error).foregroundStyle(.red)
            }

            List(viewModel.searchResults, id: \.id) { summary in
                Button {
                    Task { await viewModel.selectCourse(summary) }
                } label: {
                    VStack(alignment: .leading) {
                        Text(summary.name).font(.headline)
                        Text(summary.location).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .listRowBackground(
                    viewModel.selectedCourse?.id == summary.id ? Color.accentColor.opacity(0.15) : Color.clear
                )
            }
            .listStyle(.plain)

            Button("Continue") { viewModel.advance() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.canAdvanceFromCourseSearch)
        }
        .padding()
        .task {
            if viewModel.searchResults.isEmpty {
                await viewModel.search()
            }
        }
    }
}
