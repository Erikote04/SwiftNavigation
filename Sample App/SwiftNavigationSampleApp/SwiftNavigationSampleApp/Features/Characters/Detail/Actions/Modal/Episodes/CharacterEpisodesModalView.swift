import SwiftUI

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
