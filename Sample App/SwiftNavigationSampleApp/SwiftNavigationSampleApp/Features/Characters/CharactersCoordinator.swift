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
    private let router: NavigationRouterProxy<AppRoute, AppModalRoute, AppAlertRoute>

    init(router: NavigationRouterProxy<AppRoute, AppModalRoute, AppAlertRoute>) {
        self.router = router
    }

    var isFlowFinished: Bool {
        false
    }

    func showCharacterDetail(_ character: CharacterRouteData) {
        _ = router.push(.characterDetail(character))
    }

    func showEpisodeDetail(_ episode: EpisodeRouteData) {
        _ = router.push(.episodeDetail(episode))
    }

    func showCharacterActions(_ character: CharacterRouteData) {
        _ = router.present(.characterActions(character), style: .sheet)
    }

    func popCurrent() {
        _ = router.pop()
    }

    func popToRoot() {
        router.popToRoot()
    }
}
