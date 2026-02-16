import Foundation
import SwiftNavigation

@MainActor
protocol LocationsRouting: AnyObject {
    func showLocationDetail(_ location: LocationRouteData)
    func showSettings()
    func showAbout()
}

@MainActor
final class LocationsCoordinator: CoordinatorLifecycle, LocationsRouting {
    let coordinatorID: UUID = UUID()
    private let router: NavigationRouterProxy<AppRoute, AppModalRoute>

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
