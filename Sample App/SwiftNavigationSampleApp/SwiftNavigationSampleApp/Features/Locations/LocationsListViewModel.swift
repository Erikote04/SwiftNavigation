import Foundation
import Observation

@MainActor
@Observable
final class LocationsListViewModel {

    private let service: RickMortyService
    private weak var router: (any LocationsRouting)?

    private(set) var locations: [LocationRouteData] = []
    private(set) var isLoading = false
    var errorMessage: String?

    init(service: RickMortyService, router: any LocationsRouting) {
        self.service = service
        self.router = router
    }

    func loadIfNeeded() async {
        guard locations.isEmpty, !isLoading else {
            return
        }

        await refresh()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await service.fetchLocations(page: 1)
            locations = response.results.map(\.routeData)
            errorMessage = nil
        } catch {
            locations = []
            errorMessage = error.localizedDescription
        }
    }

    func didTapLocation(_ location: LocationRouteData) {
        router?.showLocationDetail(location)
    }

    func didTapSettings() {
        router?.showSettings()
    }
}
