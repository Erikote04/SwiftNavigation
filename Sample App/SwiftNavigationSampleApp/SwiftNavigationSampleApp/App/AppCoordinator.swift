import Foundation
import Observation
import SwiftNavigation

@available(iOS 17, *)
@MainActor
@Observable
final class AppCoordinator {
    private static let navigationStateStorageKey = "swiftNavigationSample.navigationState.v1"

    let navigationCoordinator: NavigationCoordinator<AppRoute, AppModalRoute>
    let service: RickMortyService

    let charactersCoordinator: CharactersCoordinator
    let exploreCoordinator: LocationsCoordinator

    let charactersViewModel: CharactersListViewModel
    let locationsViewModel: LocationsListViewModel

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
