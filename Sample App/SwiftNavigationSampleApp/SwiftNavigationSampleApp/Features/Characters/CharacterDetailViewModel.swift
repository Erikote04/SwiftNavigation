import Foundation
import Observation

@MainActor
@Observable
final class CharacterDetailViewModel {
    let route: CharacterRouteData

    private let service: RickMortyService
    private weak var router: (any CharactersRouting)?

    private(set) var character: APICharacter?
    private(set) var featuredEpisodes: [EpisodeRouteData] = []
    private(set) var isLoading = false
    var errorMessage: String?

    init(
        route: CharacterRouteData,
        service: RickMortyService,
        router: any CharactersRouting
    ) {
        self.route = route
        self.service = service
        self.router = router
    }

    func loadIfNeeded() async {
        guard character == nil, !isLoading else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            async let characterRequest = service.fetchCharacter(id: route.id)
            async let episodesRequest = service.fetchEpisodes(ids: Array(route.episodeIDs.prefix(6)))

            let fetchedCharacter = try await characterRequest
            let fetchedEpisodes = try await episodesRequest

            character = fetchedCharacter
            featuredEpisodes = fetchedEpisodes.map(\.routeData)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func didTapEpisode(_ episode: EpisodeRouteData) {
        router?.showEpisodeDetail(episode)
    }

    func didTapActions() {
        router?.showCharacterActions(route)
    }

    func didTapPop() {
        router?.popCurrent()
    }

    func didTapPopToRoot() {
        router?.popToRoot()
    }
}
