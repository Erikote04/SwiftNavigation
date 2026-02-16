import Foundation
import Observation
import SwiftNavigation

@available(iOS 17, *)
@MainActor
@Observable
final class AppCoordinator {
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
    }
}
