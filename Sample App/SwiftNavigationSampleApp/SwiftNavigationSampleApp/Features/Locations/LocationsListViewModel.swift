import Foundation
import Observation

@MainActor
@Observable
final class LocationsListViewModel {
    // MARK: - 2.5 ViewModel del feature: usa `LocationsRouting` para aislar SwiftNavigation de la UI

    private let service: RickMortyService
    private weak var router: (any LocationsRouting)?

    private(set) var locations: [LocationRouteData] = []
    private(set) var isLoading = false
    var errorMessage: String?

    // MARK: - 2.5.1 Inyección del coordinator del feature como router

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

    // MARK: - 2.5.2 Ejemplo de navegación modal disparada desde la lista

    func didTapSettings() {
        router?.showSettings()
    }
}


