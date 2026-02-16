import Foundation
import Observation
import SwiftNavigation

@MainActor
protocol CharactersRouting: AnyObject {
    func showCharacterDetail(_ character: CharacterRouteData)
    func showEpisodeDetail(_ episode: EpisodeRouteData)
    func showCharacterActions(_ character: CharacterRouteData)
    func popCurrent()
    func popToRoot()
}

@MainActor
protocol ExploreRouting: AnyObject {
    func showLocationDetail(_ location: LocationRouteData)
    func showSettings()
    func showAbout()
}

@MainActor
final class CharactersCoordinator: CoordinatorLifecycle, CharactersRouting {
    let coordinatorID: UUID = UUID()
    private let router: NavigationRouterProxy<AppRoute, AppModalRoute>

    init(router: NavigationRouterProxy<AppRoute, AppModalRoute>) {
        self.router = router
    }

    var isFlowFinished: Bool {
        false
    }

    func showCharacterDetail(_ character: CharacterRouteData) {
        router.push(.characterDetail(character))
    }

    func showEpisodeDetail(_ episode: EpisodeRouteData) {
        router.push(.episodeDetail(episode))
    }

    func showCharacterActions(_ character: CharacterRouteData) {
        router.present(.characterActions(character), style: .sheet)
    }

    func popCurrent() {
        _ = router.pop()
    }

    func popToRoot() {
        router.popToRoot()
    }
}

@MainActor
final class ExploreCoordinator: CoordinatorLifecycle, ExploreRouting {
    let coordinatorID: UUID = UUID()
    private let router: NavigationRouterProxy<AppRoute, AppModalRoute>

    init(router: NavigationRouterProxy<AppRoute, AppModalRoute>) {
        self.router = router
    }

    var isFlowFinished: Bool {
        false
    }

    func showLocationDetail(_ location: LocationRouteData) {
        router.push(.locationDetail(location))
    }

    func showSettings() {
        router.present(.settings, style: .fullScreen)
    }

    func showAbout() {
        router.present(.about, style: .sheet)
    }
}

@available(iOS 17, *)
@MainActor
@Observable
final class AppCoordinator {
    let navigationCoordinator: NavigationCoordinator<AppRoute, AppModalRoute>
    let service: RickMortyService

    let charactersCoordinator: CharactersCoordinator
    let exploreCoordinator: ExploreCoordinator

    let charactersViewModel: CharactersListViewModel
    let locationsViewModel: LocationsListViewModel

    init() {
        let navigationCoordinator = NavigationCoordinator<AppRoute, AppModalRoute>(scope: .application)
        let sharedRouter = NavigationRouterProxy(coordinator: navigationCoordinator)

        let charactersCoordinator = CharactersCoordinator(router: sharedRouter)
        let exploreCoordinator = ExploreCoordinator(router: sharedRouter)

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
