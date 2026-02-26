import Foundation
import Observation
import SwiftNavigation

@available(iOS 17, *)
@MainActor
@Observable
final class AppCoordinator {
    private static let navigationStateStorageKey = "swiftNavigationSample.navigationState.v1"
    private static let selectedRootTabStorageKey = "swiftNavigationSample.selectedRootTab"

    let navigationCoordinator: NavigationCoordinator<AppRoute, AppModalRoute>
    let service: RickMortyService

    let charactersCoordinator: CharactersCoordinator
    let exploreCoordinator: LocationsCoordinator

    let charactersViewModel: CharactersListViewModel
    let locationsViewModel: LocationsListViewModel
    var deepLinkErrorMessage: String?

    init() {
        let navigationCoordinator = NavigationCoordinator<AppRoute, AppModalRoute>(scope: .application)
        let sharedRouter = NavigationRouterProxy(coordinator: navigationCoordinator)

        let charactersCoordinator = CharactersCoordinator(router: sharedRouter)
        let exploreCoordinator = LocationsCoordinator(router: sharedRouter)

        let service = RickMortyService()

        self.navigationCoordinator = navigationCoordinator
        self.charactersCoordinator = charactersCoordinator
        self.exploreCoordinator = exploreCoordinator
        self.service = service

        self.charactersViewModel = CharactersListViewModel(service: service, router: charactersCoordinator)
        self.locationsViewModel = LocationsListViewModel(service: service, router: exploreCoordinator)

        navigationCoordinator.attachChild(charactersCoordinator)
        navigationCoordinator.attachChild(exploreCoordinator)

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

    func handleDeepLinkURL(_ url: URL) {
        let resolver = AppURLDeepLinkResolver()

        do {
            let preferredRootTab = try AppURLDeepLinkResolver.preferredRootTab(for: url)
            try navigationCoordinator.applyURLDeepLink(url, resolver: resolver)
            applyPreferredRootTab(preferredRootTab)
            deepLinkErrorMessage = nil
        } catch {
            deepLinkErrorMessage = error.localizedDescription
        }
    }

    func handleNotificationDeepLink(userInfo: [AnyHashable: Any]) {
        let resolver = AppNotificationDeepLinkResolver()

        do {
            let preferredRootTab = try AppNotificationDeepLinkResolver.preferredRootTab(for: userInfo)
            try navigationCoordinator.applyNotificationDeepLink(userInfo: userInfo, resolver: resolver)
            applyPreferredRootTab(preferredRootTab)
            deepLinkErrorMessage = nil
        } catch {
            deepLinkErrorMessage = error.localizedDescription
        }
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
                NavigationState<AppRoute, AppModalRoute>.self,
                from: data
            )
            navigationCoordinator.restore(from: snapshot)
        } catch {
            UserDefaults.standard.removeObject(forKey: Self.navigationStateStorageKey)
            assertionFailure("Failed to restore navigation state: \(error)")
        }
    }
}
