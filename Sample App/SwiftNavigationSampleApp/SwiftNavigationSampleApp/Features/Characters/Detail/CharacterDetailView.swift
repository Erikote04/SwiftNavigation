import SwiftUI

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
