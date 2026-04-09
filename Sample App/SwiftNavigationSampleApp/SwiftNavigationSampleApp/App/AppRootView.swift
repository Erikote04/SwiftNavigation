import SwiftUI
import SwiftNavigation

private enum RootTab: Hashable {
    case characters
    case explore
    case showcase
    
    init?(storageValue: String) {
        switch storageValue {
        case "characters": self = .characters
        case "explore": self = .explore
        case "showcase": self = .showcase
        default: return nil
        }
    }

    var storageValue: String {
        switch self {
        case .characters: "characters"
        case .explore: "explore"
        case .showcase: "showcase"
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

                    Tab("Showcase", systemImage: "sparkles.rectangle.stack", value: .showcase) {
                        ShowcaseDashboardView(
                            viewModel: appCoordinator.showcaseViewModel,
                            sessionStore: appCoordinator.sessionStore
                        )
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

                case .sendMoneyRecipient(let route):
                    SendMoneyRecipientView(
                        route: route,
                        viewModel: appCoordinator.sendMoneyFlowViewModel(for: route)
                    )

                case .sendMoneyAmount(let route):
                    SendMoneyAmountView(
                        route: route,
                        viewModel: appCoordinator.sendMoneyFlowViewModel(for: route)
                    )

                case .sendMoneyReview(let route):
                    SendMoneyReviewView(
                        route: route,
                        viewModel: appCoordinator.sendMoneyFlowViewModel(for: route)
                    )

                case .protectedReceipt(let route):
                    ProtectedReceiptView(route: route)

                case .protectedProfile(let route):
                    ProtectedProfileView(route: route)
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

                case .login(let route):
                    LoginModalView(
                        route: route,
                        sessionStore: appCoordinator.sessionStore,
                        onComplete: appCoordinator.completeLogin
                    )

                case .sheetShowcase(let route):
                    SheetShowcaseModalView(route: route)

                case .alertShowcase:
                    AlertShowcaseModalView(
                        onShowErrorAlert: {
                            appCoordinator.showcaseCoordinator.showErrorAlert(
                                "Modal-triggered alerts still flow through the root coordinator."
                            )
                        },
                        onShowDiscardAlert: {
                            appCoordinator.showcaseCoordinator.showDiscardDraftConfirmation(flowID: UUID())
                        }
                    )
                }
            },
            alertDestination: { route in
                switch route {
                case .deepLinkError(let message):
                    AlertDescriptor(
                        title: "Deep Link Error",
                        message: message,
                        actions: [.dismiss("Dismiss")]
                    )

                case .showcaseError(let message):
                    AlertDescriptor(
                        title: "Showcase Alert",
                        message: message,
                        actions: [.dismiss("OK")]
                    )

                case .discardDraft(let flowID):
                    AlertDescriptor(
                        title: "Discard Draft?",
                        message: "This clears the current Send Money flow and returns to the showcase root.",
                        actions: [
                            AlertAction(
                                title: "Discard",
                                role: .destructive,
                                handler: {
                                    appCoordinator.discardSendMoneyFlow(flowID)
                                }
                            ),
                            .dismiss("Keep Editing", role: .cancel)
                        ]
                    )
                }
            }
        )
        .navigationCoordinator(appCoordinator.navigationCoordinator)
        .onOpenURL { url in
            handleIncomingURL(url)
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
            handleIncomingURL(userActivity.webpageURL)
        }
        .onReceive(NotificationCenter.default.publisher(for: .sampleAppNotificationDeepLinkReceived)) { notification in
            guard let userInfo = notification.userInfo else {
                return
            }

            Task {
                await appCoordinator.handleNotificationDeepLink(userInfo: userInfo)
            }
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

        case .showcase:
            ToolbarItem(placement: .topBarTrailing) {
                Button(
                    appCoordinator.sessionStore.isAuthenticated ? "Expire Session" : "Sign In",
                    systemImage: appCoordinator.sessionStore.isAuthenticated ? "lock.slash" : "person.badge.key"
                ) {
                    appCoordinator.showcaseViewModel.toggleSession()
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
        case .showcase:
            "Showcase"
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

    private func handleIncomingURL(_ url: URL?) {
        guard let url else {
            return
        }

        Task {
            await appCoordinator.handleDeepLinkURL(url)
        }
    }
}
