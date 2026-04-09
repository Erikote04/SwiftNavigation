import Foundation
import Observation
import SwiftNavigation

@available(iOS 17, *)
@MainActor
@Observable
final class AppCoordinator {
    private static let navigationStateStorageKey = "swiftNavigationSample.navigationState.v2"
    private static let selectedRootTabStorageKey = "swiftNavigationSample.selectedRootTab"

    let navigationCoordinator: NavigationCoordinator<AppRoute, AppModalRoute, AppAlertRoute>
    let service: RickMortyService
    let sessionStore: SessionStore

    let charactersCoordinator: CharactersCoordinator
    let exploreCoordinator: LocationsCoordinator
    let showcaseCoordinator: ShowcaseCoordinator

    let charactersViewModel: CharactersListViewModel
    let locationsViewModel: LocationsListViewModel
    let showcaseViewModel: ShowcaseDashboardViewModel

    @ObservationIgnored
    private var sendMoneyFlowViewModels: [UUID: SendMoneyFlowViewModel] = [:]

    init() {
        let navigationCoordinator = NavigationCoordinator<AppRoute, AppModalRoute, AppAlertRoute>(scope: .application)
        let sharedRouter = NavigationRouterProxy(coordinator: navigationCoordinator)

        let charactersCoordinator = CharactersCoordinator(router: sharedRouter)
        let exploreCoordinator = LocationsCoordinator(router: sharedRouter)
        let showcaseCoordinator = ShowcaseCoordinator(router: sharedRouter)

        let service = RickMortyService()
        let sessionStore = SessionStore()

        self.navigationCoordinator = navigationCoordinator
        self.charactersCoordinator = charactersCoordinator
        self.exploreCoordinator = exploreCoordinator
        self.showcaseCoordinator = showcaseCoordinator
        self.service = service
        self.sessionStore = sessionStore

        self.charactersViewModel = CharactersListViewModel(service: service, router: charactersCoordinator)
        self.locationsViewModel = LocationsListViewModel(service: service, router: exploreCoordinator)
        self.showcaseViewModel = ShowcaseDashboardViewModel(router: showcaseCoordinator, sessionStore: sessionStore)

        navigationCoordinator.attachChild(charactersCoordinator)
        navigationCoordinator.attachChild(exploreCoordinator)
        navigationCoordinator.attachChild(showcaseCoordinator)

        restorePersistedNavigationStateIfAvailable()
    }

    func persistNavigationState() {
        do {
            let snapshot = navigationCoordinator.exportState()
            let data = try JSONEncoder().encode(snapshot)
            UserDefaults.standard.set(data, forKey: Self.navigationStateStorageKey)
        } catch {
            assertionFailure("Failed to encode navigation state: \(error)")
        }
    }

    func handleDeepLinkURL(_ url: URL) async {
        let resolver = AppURLDeepLinkResolver()

        do {
            let preferredRootTab = try AppURLDeepLinkResolver.preferredRootTab(for: url)
            try await navigationCoordinator.applyURLDeepLink(
                url,
                resolver: resolver,
                interceptor: deepLinkInterceptor(for:)
            )
            applyPreferredRootTab(preferredRootTab)
        } catch {
            _ = navigationCoordinator.presentAlert(.deepLinkError(error.localizedDescription))
        }
    }

    func handleNotificationDeepLink(userInfo: [AnyHashable: Any]) async {
        let resolver = AppNotificationDeepLinkResolver()

        do {
            let preferredRootTab = try AppNotificationDeepLinkResolver.preferredRootTab(for: userInfo)
            try await navigationCoordinator.applyNotificationDeepLink(
                userInfo: userInfo,
                resolver: resolver,
                interceptor: deepLinkInterceptor(for:)
            )
            applyPreferredRootTab(preferredRootTab)
        } catch {
            _ = navigationCoordinator.presentAlert(.deepLinkError(error.localizedDescription))
        }
    }

    func completeLogin() {
        sessionStore.signInDemoUser()
        if navigationCoordinator.resumePendingNavigation() == nil {
            _ = navigationCoordinator.dismissTopModal()
        }
    }

    func discardSendMoneyFlow(_ flowID: UUID) {
        sendMoneyFlowViewModels[flowID] = nil
        navigationCoordinator.popToRoot()
    }

    func sendMoneyFlowViewModel(for route: SendMoneyRecipientRouteData) -> SendMoneyFlowViewModel {
        let viewModel = sendMoneyFlowViewModel(
            flowID: route.flowID,
            selectedRecipient: route.selectedRecipient,
            availableRecipients: route.availableRecipients,
            primaryAmount: 35,
            duplicateAmount: 48
        )
        viewModel.sync(with: route)
        return viewModel
    }

    func sendMoneyFlowViewModel(for route: SendMoneyAmountRouteData) -> SendMoneyFlowViewModel {
        let viewModel = sendMoneyFlowViewModel(
            flowID: route.flowID,
            selectedRecipient: route.selectedRecipient,
            availableRecipients: ["Sonia", "Alex", "Maya", "Taylor"],
            primaryAmount: route.editorKind == .primary ? route.amount : 35,
            duplicateAmount: route.editorKind == .duplicate ? route.amount : 48
        )
        viewModel.sync(with: route)
        return viewModel
    }

    func sendMoneyFlowViewModel(for route: SendMoneyReviewRouteData) -> SendMoneyFlowViewModel {
        let viewModel = sendMoneyFlowViewModel(
            flowID: route.flowID,
            selectedRecipient: route.selectedRecipient,
            availableRecipients: ["Sonia", "Alex", "Maya", "Taylor"],
            primaryAmount: route.primaryAmount,
            duplicateAmount: route.duplicateAmount
        )
        viewModel.sync(with: route)
        return viewModel
    }

    private func applyPreferredRootTab(_ preferredRootTab: AppDeepLinkPreferredRootTab?) {
        guard let preferredRootTab else {
            return
        }

        UserDefaults.standard.set(
            preferredRootTab.rawValue,
            forKey: Self.selectedRootTabStorageKey
        )
    }

    private func restorePersistedNavigationStateIfAvailable() {
        guard let data = UserDefaults.standard.data(forKey: Self.navigationStateStorageKey) else {
            return
        }

        do {
            let snapshot = try JSONDecoder().decode(
                NavigationState<AppRoute, AppModalRoute, AppAlertRoute>.self,
                from: data
            )
            navigationCoordinator.restore(from: snapshot)
        } catch {
            UserDefaults.standard.removeObject(forKey: Self.navigationStateStorageKey)
            assertionFailure("Failed to restore navigation state: \(error)")
        }
    }

    private func sendMoneyFlowViewModel(
        flowID: UUID,
        selectedRecipient: String,
        availableRecipients: [String],
        primaryAmount: Double,
        duplicateAmount: Double
    ) -> SendMoneyFlowViewModel {
        if let existingViewModel = sendMoneyFlowViewModels[flowID] {
            return existingViewModel
        }

        let viewModel = SendMoneyFlowViewModel(
            flowID: flowID,
            router: showcaseCoordinator,
            selectedRecipient: selectedRecipient,
            availableRecipients: availableRecipients,
            primaryAmount: primaryAmount,
            duplicateAmount: duplicateAmount
        )
        sendMoneyFlowViewModels[flowID] = viewModel
        return viewModel
    }

    private func deepLinkInterceptor(
        for state: NavigationState<AppRoute, AppModalRoute, AppAlertRoute>
    ) async -> NavigationInterceptionDecision<AppRoute, AppModalRoute, AppAlertRoute> {
        guard requiresAuthentication(for: state), !sessionStore.isAuthenticated else {
            return .proceed
        }

        let loginState = NavigationState<AppRoute, AppModalRoute, AppAlertRoute>(
            stackEntries: [],
            modalStack: [
                ModalPresentation(
                    style: .sheet,
                    root: .login(
                        LoginRouteData(
                            title: "Session expired",
                            message: "Sign in first, then SwiftNavigation resumes the original deep link automatically.",
                            source: "Deep link interceptor",
                            isDismissDisabled: true
                        )
                    ),
                    sheetPresentation: SheetPresentationOptions(
                        detents: [.medium, .large],
                        background: .thinMaterial,
                        backgroundInteraction: .enabledThrough(.medium),
                        interactiveDismissDisabled: true
                    ),
                    pathEntries: []
                )
            ]
        )

        return .redirect(loginState: loginState, pendingState: state)
    }

    private func requiresAuthentication(
        for state: NavigationState<AppRoute, AppModalRoute, AppAlertRoute>
    ) -> Bool {
        state.stack.contains { route in
            switch route {
            case .protectedReceipt, .protectedProfile:
                true
            default:
                false
            }
        }
    }
}
