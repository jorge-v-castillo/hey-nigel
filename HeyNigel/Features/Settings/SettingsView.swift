import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        Form {
            Section("Profile") {
                TextField("Full name", text: $viewModel.fullName)
                TextField("Nickname", text: $viewModel.nickname)
                TextField("Email", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            ClubYardageEditorView(clubs: $viewModel.clubs)
        }
        .navigationTitle("Settings")
        .onAppear { viewModel.load(from: modelContext) }
        .onDisappear { viewModel.save(in: modelContext) }
    }
}
