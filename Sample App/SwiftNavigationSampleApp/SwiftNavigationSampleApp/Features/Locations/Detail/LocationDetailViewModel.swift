import Foundation
import Observation

@MainActor
@Observable
final class LocationDetailViewModel {
    // MARK: - 2.6 ViewModel de detalle (Locations): misma integración de routing por protocolo

    let route: LocationRouteData

    private let service: RickMortyService
    private weak var router: (any LocationsRouting)?

    private(set) var location: APILocation?
    private(set) var isLoading = false
    var errorMessage: String?

    init(route: LocationRouteData, service: RickMortyService, router: any LocationsRouting) {
        self.route = route
        self.service = service
        self.router = router
    }

    func loadIfNeeded() async {
        guard location == nil, !isLoading else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            location = try await service.fetchLocation(id: route.id)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func didTapAbout() {
        router?.showAbout()
    }
}
