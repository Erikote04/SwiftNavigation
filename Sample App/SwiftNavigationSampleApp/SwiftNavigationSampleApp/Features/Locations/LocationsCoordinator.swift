import Foundation
import SwiftNavigation

// MARK: - 2.2 Navegación por feature (Locations): mismo patrón de contrato + coordinator

@MainActor
protocol LocationsRouting: AnyObject {
    func showLocationDetail(_ location: LocationRouteData)
    func showSettings()
    func showAbout()
}

@MainActor
final class LocationsCoordinator: CoordinatorLifecycle, LocationsRouting {
    // MARK: - 2.2.1 Convierte acciones del feature en rutas globales de SwiftNavigation

    let coordinatorID: UUID = UUID()
    private let router: NavigationRouterProxy<AppRoute, AppModalRoute>

    // MARK: - 2.2.2 Inyección del router compartido

    init(router: NavigationRouterProxy<AppRoute, AppModalRoute>) {
        self.router = router
    }

    var isFlowFinished: Bool {
        false
    }

    func showLocationDetail(_ location: LocationRouteData) {
        router.push(.locationDetail(location))
    }

    func showSettings() {
        router.present(.settings, style: .fullScreen)
    }

    func showAbout() {
        router.present(.about, style: .sheet)
    }
}
