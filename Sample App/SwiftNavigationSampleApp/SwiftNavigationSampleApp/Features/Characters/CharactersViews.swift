import SwiftUI

struct CharactersTabView: View {
    let viewModel: CharactersListViewModel

    var body: some View {
        List(viewModel.characters) { character in
            Button {
                viewModel.didTapCharacter(character)
            } label: {
                CharacterRowView(character: character)
            }
            .buttonStyle(.plain)
            .task {
                await viewModel.loadMoreIfNeeded(currentID: character.id)
            }

            if viewModel.isLoadingNextPage, character.id == viewModel.characters.last?.id {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .overlay {
            if viewModel.isInitialLoading {
                ProgressView("Loading characters...")
            }
        }
        .navigationTitle("Characters")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reload") {
                    Task {
                        await viewModel.refresh()
                    }
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadInitialIfNeeded()
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
            Button("Retry") {
                Task {
                    await viewModel.refresh()
                }
            }
            Button("Dismiss", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }
}

private struct CharacterRowView: View {
    let character: CharacterRouteData

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: character.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    Color.secondary.opacity(0.15)
                }
            }
            .frame(width: 58, height: 58)
            .clipShape(.rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(character.name)
                    .font(.headline)
                Text("\(character.species) • \(character.status)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct CharacterDetailView: View {
    @State private var viewModel: CharacterDetailViewModel

    init(route: CharacterRouteData, service: RickMortyService, router: any CharactersRouting) {
        _viewModel = State(initialValue: CharacterDetailViewModel(route: route, service: service, router: router))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: URL(string: viewModel.route.imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Color.secondary.opacity(0.1)
                    }
                }
                .frame(height: 240)
                .frame(maxWidth: .infinity)
                .clipShape(.rect(cornerRadius: 16))

                Group {
                    Text(viewModel.route.name)
                        .font(.title2.bold())
                    Text("\(viewModel.route.species) • \(viewModel.route.status)")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Featured Episodes")
                        .font(.headline)

                    if viewModel.isLoading {
                        ProgressView()
                    } else if viewModel.featuredEpisodes.isEmpty {
                        Text("No episodes available.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.featuredEpisodes) { episode in
                            Button {
                                viewModel.didTapEpisode(episode)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(episode.name)
                                        Text(episode.code)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(spacing: 10) {
                    Button("Open Character Actions") {
                        viewModel.didTapActions()
                    }
                    .buttonStyle(.borderedProminent)

                    HStack {
                        Button("Pop") {
                            viewModel.didTapPop()
                        }
                        .buttonStyle(.bordered)

                        Button("Pop to Root") {
                            viewModel.didTapPopToRoot()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Character")
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
