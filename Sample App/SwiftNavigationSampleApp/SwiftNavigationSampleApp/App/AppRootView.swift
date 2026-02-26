import Combine
import SwiftUI
import SwiftNavigation

private enum RootTab: Hashable {
    case characters
    case explore
    
    init?(storageValue: String) {
        switch storageValue {
        case "characters": self = .characters
        case "explore": self = .explore
        default: return nil
        }
    }

    var storageValue: String {
        switch self {
        case .characters: "characters"
        case .explore: "explore"
        }
    }
}

@MainActor
struct AppRootView: View {
    let appCoordinator: AppCoordinator

    @AppStorage("swiftNavigationSample.selectedRootTab")
    private var selectedTabStorage: String = "characters"

    var body: some View {
        RoutingView(
            coordinator: appCoordinator.navigationCoordinator,
            root: {
                TabView(selection: selectedTabBinding) {
                    Tab("Characters", systemImage: "person.3.fill", value: .characters) {
                        CharactersListView(viewModel: appCoordinator.charactersViewModel)
                    }

                    Tab("Locations", systemImage: "globe", value: .explore) {
                        LocationsListView(viewModel: appCoordinator.locationsViewModel)
                    }
                }
                .navigationTitle(rootNavigationTitle)
                .toolbar {
                    if appCoordinator.navigationCoordinator.stack.isEmpty {
                        rootToolbarContent
                    }
                }
            },
            stackDestination: { route in
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
        .onOpenURL { url in
            appCoordinator.handleDeepLinkURL(url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .sampleAppNotificationDeepLinkReceived)) { notification in
            guard let userInfo = notification.userInfo else {
                return
            }

            appCoordinator.handleNotificationDeepLink(userInfo: userInfo)
        }
        .alert(
            "Deep Link Error",
            isPresented: Binding(
                get: { appCoordinator.deepLinkErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        appCoordinator.deepLinkErrorMessage = nil
                    }
                }
            )
        ) {
            Button("Dismiss", role: .cancel) {}
        } message: {
            Text(appCoordinator.deepLinkErrorMessage ?? "Unknown deeplink error")
        }
    }

    @ToolbarContentBuilder
    private var rootToolbarContent: some ToolbarContent {
        switch selectedTab {
        case .characters:
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reload") {
                    Task {
                        await appCoordinator.charactersViewModel.refresh()
                    }
                }
            }

        case .explore:
            ToolbarItem(placement: .topBarTrailing) {
                Button("Settings") {
                    appCoordinator.locationsViewModel.didTapSettings()
                }
            }
        }
    }

    private var rootNavigationTitle: String {
        switch selectedTab {
        case .characters:
            "Characters"
        case .explore:
            "Locations"
        }
    }

    private var selectedTabBinding: Binding<RootTab> {
        Binding(
            get: { selectedTab },
            set: { selectedTabStorage = $0.storageValue }
        )
    }

    private var selectedTab: RootTab {
        RootTab(storageValue: selectedTabStorage) ?? .characters
    }
}
