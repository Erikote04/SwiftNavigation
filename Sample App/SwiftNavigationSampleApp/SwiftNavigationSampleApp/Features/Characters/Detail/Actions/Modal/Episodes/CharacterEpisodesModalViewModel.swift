import Foundation
import Observation

@MainActor
@Observable
final class CharacterEpisodesModalViewModel {
    let character: CharacterRouteData

    private let service: RickMortyService

    private(set) var episodes: [EpisodeRouteData] = []
    private(set) var isLoading = false
    var errorMessage: String?

    init(character: CharacterRouteData, service: RickMortyService) {
        self.character = character
        self.service = service
    }

    func loadIfNeeded() async {
        guard episodes.isEmpty, !isLoading else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedEpisodes = try await service.fetchEpisodes(ids: Array(character.episodeIDs.prefix(20)))
            episodes = fetchedEpisodes.map(\.routeData)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
