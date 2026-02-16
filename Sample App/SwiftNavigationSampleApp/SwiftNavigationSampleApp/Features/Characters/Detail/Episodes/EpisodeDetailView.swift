import SwiftUI

struct EpisodeDetailView: View {
    @State private var viewModel: EpisodeDetailViewModel

    init(route: EpisodeRouteData, service: RickMortyService) {
        _viewModel = State(initialValue: EpisodeDetailViewModel(route: route, service: service))
    }

    var body: some View {
        List {
            Text(viewModel.route.name)
                .font(.headline)

            Label(viewModel.route.code, systemImage: "tv")
            Label(viewModel.route.airDate, systemImage: "calendar")

            if let episode = viewModel.episode {
                Label("\(episode.characters.count) characters", systemImage: "person.2")
            }
        }
        .navigationTitle("Episode")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading episode...")
            }
        }
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
