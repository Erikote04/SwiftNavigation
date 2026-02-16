import Foundation
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
