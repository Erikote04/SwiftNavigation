import Foundation
import SwiftNavigation

// MARK: - 2. Navegación por feature (Characters): definir una API de routing desacoplada del ViewModel

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
    // MARK: - 2.1 Coordinator del feature: traduce acciones semánticas a push/present/pop de SwiftNavigation

    let coordinatorID: UUID = UUID()
    private let router: NavigationRouterProxy<AppRoute, AppModalRoute>

    // MARK: - 2.1.1 Recibe el router compartido del coordinador de aplicación

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
