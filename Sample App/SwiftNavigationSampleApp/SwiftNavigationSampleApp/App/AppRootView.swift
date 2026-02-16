import SwiftUI
import SwiftNavigation

private enum RootTab: Hashable {
    case characters
    case explore
}

@MainActor
struct AppRootView: View {
    let appCoordinator: AppCoordinator

    @State private var selectedTab: RootTab = .characters

    var body: some View {
        RoutingView(
            coordinator: appCoordinator.navigationCoordinator,
            root: {
                TabView(selection: $selectedTab) {
                    Tab("Characters", systemImage: "person.3.fill", value: .characters) {
                        NavigationStack {
                            CharactersListView(viewModel: appCoordinator.charactersViewModel)
                        }
                    }

                    Tab("Locations", systemImage: "globe", value: .explore) {
                        NavigationStack {
                            LocationsListView(viewModel: appCoordinator.locationsViewModel)
                        }
                    }
                }
            },
            destination: { route in
                switch route {
                case .characterDetail(let character):
                    CharacterDetailView(
                        route: character,
                        service: appCoordinator.service,
                        router: appCoordinator.charactersCoordinator
                    )

                case .episodeDetail(let episode):
                    EpisodeDetailView(route: episode, service: appCoordinator.service)

                case .locationDetail(let location):
                    LocationDetailView(
                        route: location,
                        service: appCoordinator.service,
                        router: appCoordinator.exploreCoordinator
                    )
                }
            },
            modalDestination: { route in
                switch route {
                case .characterActions(let character):
                    CharacterActionsModalView(character: character)

                case .characterEpisodes(let character):
                    CharacterEpisodesModalView(character: character, service: appCoordinator.service)

                case .characterEpisodeDetail(let episode):
                    ModalEpisodeDetailView(route: episode)

                case .favoritesPlanner(let character):
                    FavoritesPlannerModalView(character: character)

                case .plannerConfirmation(let character):
                    PlannerConfirmationModalView(character: character)

                case .settings:
                    SettingsModalView()

                case .about:
                    AboutModalView()
                }
            }
        )
        .navigationCoordinator(appCoordinator.navigationCoordinator)
    }
}
