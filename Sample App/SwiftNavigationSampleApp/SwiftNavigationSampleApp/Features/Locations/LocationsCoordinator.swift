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
    private let router: NavigationRouterProxy<AppRoute, AppModalRoute, AppAlertRoute>

    init(router: NavigationRouterProxy<AppRoute, AppModalRoute, AppAlertRoute>) {
        self.router = router
    }

    var isFlowFinished: Bool {
        false
    }

    func showLocationDetail(_ location: LocationRouteData) {
        _ = router.push(.locationDetail(location))
    }

    func showSettings() {
        _ = router.present(.settings, style: .fullScreen)
    }

    func showAbout() {
        _ = router.present(.about, style: .sheet)
    }
}
