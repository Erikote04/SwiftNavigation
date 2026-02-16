import SwiftUI
import SwiftNavigation

struct CharacterActionsModalView: View {
    let character: CharacterRouteData

    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationCoordinator<AppRoute, AppModalRoute>.self) private var coordinator

    var body: some View {
        List {
            Section("Character") {
                Text(character.name)
                Text("\(character.species) • \(character.status)")
                    .foregroundStyle(.secondary)
            }

            Section("Navigation inside this modal") {
                NavigationLink(value: AppModalRoute.characterEpisodes(character)) {
                    Label("Browse episodes", systemImage: "list.bullet.rectangle")
                }
            }

            Section("Nested modal demo") {
                Button {
                    coordinator.present(.favoritesPlanner(character), style: .fullScreen)
                } label: {
                    Label("Open Favorites Planner (full screen)", systemImage: "rectangle.inset.filled.and.person.filled")
                }
            }

            Section {
                Button("Dismiss", role: .cancel) {
                    dismiss()
                }
            }
        }
        .navigationTitle("Character Actions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CharacterEpisodesModalView: View {
    @State private var viewModel: CharacterEpisodesModalViewModel

    init(character: CharacterRouteData, service: RickMortyService) {
        _viewModel = State(initialValue: CharacterEpisodesModalViewModel(character: character, service: service))
    }

    var body: some View {
        List(viewModel.episodes) { episode in
            NavigationLink(value: AppModalRoute.characterEpisodeDetail(episode)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(episode.name)
                    Text(episode.code)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading episodes...")
            }
        }
        .navigationTitle("Episodes")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadIfNeeded()
        }
        .alert(
            "Request Failed",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { newValue in
                    if !newValue {
                        viewModel.errorMessage = nil
                    }
                }
            )
        ) {
            Button("Dismiss", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }
}

struct ModalEpisodeDetailView: View {
    let route: EpisodeRouteData

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Text(route.name)
                .font(.headline)
            Label(route.code, systemImage: "tv")
            Label(route.airDate, systemImage: "calendar")

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Episode")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FavoritesPlannerModalView: View {
    let character: CharacterRouteData

    @State private var includeEpisodes = true
    @State private var includeLocation = true

    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationCoordinator<AppRoute, AppModalRoute>.self) private var coordinator

    var body: some View {
        NavigationStack {
            Form {
                Section("Plan") {
                    Toggle("Include episodes", isOn: $includeEpisodes)
                    Toggle("Include location", isOn: $includeLocation)
                }

                Section("Flow demo") {
                    Button("Open confirmation (sheet over full screen)") {
                        coordinator.present(.plannerConfirmation(character), style: .sheet)
                    }
                }

                Section {
                    Button("Dismiss planner", role: .cancel) {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Favorites Planner")
        }
    }
}

struct PlannerConfirmationModalView: View {
    let character: CharacterRouteData

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)
            Text("Plan created for \(character.name)")
                .font(.headline)
            Text("This is a nested sheet presented on top of a full-screen modal.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }
}

struct SettingsModalView: View {
    @State private var notificationsEnabled = true

    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationCoordinator<AppRoute, AppModalRoute>.self) private var coordinator

    var body: some View {
        List {
            Section("Preferences") {
                Toggle("Enable notifications", isOn: $notificationsEnabled)
            }

            Section("Navigation in modal") {
                NavigationLink(value: AppModalRoute.about) {
                    Label("About (push)", systemImage: "info.circle")
                }

                Button {
                    coordinator.present(.about, style: .sheet)
                } label: {
                    Label("About (sheet)", systemImage: "doc.text.magnifyingglass")
                }
            }

            Section {
                Button("Close settings", role: .cancel) {
                    dismiss()
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutModalView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SwiftNavigation Demo")
                .font(.title3.bold())

            Text("This sample app demonstrates tab navigation, push/pop, popToRoot, modal flows, internal modal navigation, and nested modals.")
                .foregroundStyle(.secondary)

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding(24)
        .navigationTitle("About")
    }
}
