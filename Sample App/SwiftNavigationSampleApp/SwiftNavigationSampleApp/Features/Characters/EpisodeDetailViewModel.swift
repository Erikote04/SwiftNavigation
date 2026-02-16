import Foundation
import Observation

@MainActor
@Observable
final class EpisodeDetailViewModel {
    let route: EpisodeRouteData

    private let service: RickMortyService
    private(set) var episode: APIEpisode?
    private(set) var isLoading = false
    var errorMessage: String?

    init(route: EpisodeRouteData, service: RickMortyService) {
        self.route = route
        self.service = service
    }

    func loadIfNeeded() async {
        guard episode == nil, !isLoading else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            episode = try await service.fetchEpisode(id: route.id)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
