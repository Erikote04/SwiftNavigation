import Foundation
import Observation

@MainActor
@Observable
final class LocationsListViewModel {
    private let service: RickMortyService
    private weak var router: (any ExploreRouting)?

    private(set) var locations: [LocationRouteData] = []
    private(set) var isLoading = false
    var errorMessage: String?

    init(service: RickMortyService, router: any ExploreRouting) {
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

@MainActor
@Observable
final class LocationDetailViewModel {
    let route: LocationRouteData

    private let service: RickMortyService
    private weak var router: (any ExploreRouting)?

    private(set) var location: APILocation?
    private(set) var isLoading = false
    var errorMessage: String?

    init(route: LocationRouteData, service: RickMortyService, router: any ExploreRouting) {
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
