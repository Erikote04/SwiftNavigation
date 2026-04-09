import Foundation
import SwiftUI
import Testing
@testable import SwiftNavigation

@available(iOS 17, macOS 14, *)
private enum TestStackRoute: String, NavigationRoute {
    case dashboard
    case details
    case settings
    case summary
}

@available(iOS 17, macOS 14, *)
private enum TestModalRoute: String, NavigationRoute {
    case login
    case otp
    case terms
    case help
}

@available(iOS 17, macOS 14, *)
private enum TestAlertRoute: String, NavigationRoute {
    case destructiveConfirmation
    case sessionExpired
    case genericError
}

@available(iOS 17, macOS 14, *)
private typealias TestCoordinator = NavigationCoordinator<TestStackRoute, TestModalRoute, TestAlertRoute>

@available(iOS 17, macOS 14, *)
private typealias TestNavigationState = NavigationState<TestStackRoute, TestModalRoute, TestAlertRoute>

@available(iOS 17, macOS 14, *)
private typealias TestResolvedState = NavigationState<TestStackRoute, TestModalRoute, Never>

@available(iOS 17, macOS 14, *)
@MainActor
private final class ChildCoordinatorMock: CoordinatorLifecycle {
    let coordinatorID: UUID = UUID()
    var isFlowFinished: Bool

    init(isFlowFinished: Bool = false) {
        self.isFlowFinished = isFlowFinished
    }
}

@available(iOS 17, macOS 14, *)
private struct URLResolverMock: URLDeepLinkResolving {
    func navigationState(for url: URL) throws -> TestResolvedState {
        let isSettings = url.absoluteString.contains("settings")
        return TestResolvedState(
            stack: isSettings ? [TestStackRoute.dashboard, .settings] : [TestStackRoute.dashboard],
            modalStack: []
        )
    }
}

@available(iOS 17, macOS 14, *)
private struct NotificationResolverMock: NotificationDeepLinkResolving {
    func navigationState(for userInfo: [AnyHashable: Any]) throws -> TestResolvedState {
        let shouldOpenModal = (userInfo["showLogin"] as? Bool) == true
        return TestResolvedState(
            stack: [TestStackRoute.dashboard],
            modalStack: shouldOpenModal ? [ModalPresentation<TestModalRoute>(style: .sheet, root: .login)] : []
        )
    }
}

@available(iOS 17, macOS 14, *)
@Test
@MainActor
func stackOperations_useUniqueEntriesAndSupportPopToEntry() {
    let coordinator = TestCoordinator(scope: .feature(name: "test"))

    let firstDashboard = coordinator.push(TestStackRoute.dashboard)
    let details = coordinator.push(TestStackRoute.details)
    let secondDashboard = coordinator.push(TestStackRoute.dashboard)

    #expect(firstDashboard != secondDashboard)
    #expect(details != secondDashboard)
    #expect(coordinator.stack == [TestStackRoute.dashboard, .details, .dashboard])
    #expect(coordinator.containsEntry(firstDashboard))
    #expect(coordinator.containsEntry(secondDashboard))

    let poppedEntry = coordinator.popToEntry(details)
    #expect(poppedEntry?.route == .details)
    #expect(poppedEntry?.id == details)
    #expect(coordinator.stack == [TestStackRoute.dashboard, .details])

    let routePopped = coordinator.popToRoute { $0 == TestStackRoute.dashboard }
    #expect(routePopped == TestStackRoute.dashboard)
    #expect(coordinator.stack == [TestStackRoute.dashboard])
    #expect(coordinator.containsEntry(firstDashboard))
}

@available(iOS 17, macOS 14, *)
@Test
@MainActor
func modalPaths_useUniqueEntriesAndSupportPopToEntry() {
    let coordinator = TestCoordinator(scope: .feature(name: "auth"))

    _ = coordinator.present(
        TestModalRoute.login,
        style: .sheet,
        sheetPresentation: SheetPresentationOptions(
            detents: [.medium, .large],
            background: .thinMaterial,
            backgroundInteraction: .enabledThrough(.medium),
            interactiveDismissDisabled: true
        )
    )

    let firstOTP = coordinator.pushModalRoute(TestModalRoute.otp, at: 0)
    let secondOTP = coordinator.pushModalRoute(TestModalRoute.otp, at: 0)

    #expect(firstOTP != secondOTP)
    #expect(coordinator.modalStack[0].path == [TestModalRoute.otp, .otp])
    #expect(coordinator.containsModalEntry(firstOTP!, at: 0))
    #expect(coordinator.containsModalEntry(secondOTP!, at: 0))

    let poppedEntry = coordinator.popModalToEntry(firstOTP!, at: 0)
    #expect(poppedEntry?.route == .otp)
    #expect(poppedEntry?.id == firstOTP)
    #expect(coordinator.modalStack[0].path == [TestModalRoute.otp])
    #expect(coordinator.modalStack[0].sheetPresentation?.interactiveDismissDisabled == true)
}

@available(iOS 17, macOS 14, *)
@Test
@MainActor
func stateRestoration_roundTripsEntriesSheetsAndAlerts() throws {
    let coordinator = TestCoordinator(scope: .feature(name: "checkout"))
    let dashboardID = coordinator.push(TestStackRoute.dashboard)
    let summaryID = coordinator.push(TestStackRoute.summary)
    _ = coordinator.present(
        TestModalRoute.login,
        style: .sheet,
        sheetPresentation: SheetPresentationOptions(
            detents: [.fraction(0.45), .large],
            background: .regularMaterial,
            backgroundInteraction: .enabled,
            interactiveDismissDisabled: false
        ),
        path: [TestModalRoute.otp]
    )
    _ = coordinator.presentAlert(TestAlertRoute.sessionExpired)

    let snapshot = coordinator.exportState()
    let data = try JSONEncoder().encode(snapshot)
    let decoded = try JSONDecoder().decode(
        TestNavigationState.self,
        from: data
    )

    #expect(decoded.stack == [TestStackRoute.dashboard, .summary])
    #expect(decoded.stackEntries.map { $0.id } == [dashboardID, summaryID])
    #expect(decoded.modalStack[0].path == [TestModalRoute.otp])
    #expect(decoded.modalStack[0].sheetPresentation?.background == .regularMaterial)
    #expect(decoded.alertPresentation?.route == TestAlertRoute.sessionExpired)
}

@available(iOS 17, macOS 14, *)
@Test
func legacySnapshots_decodeIntoEntryBackedState() throws {
    let modalID = UUID()
    let legacyJSON = """
    {
      "stack": ["dashboard", "details", "dashboard"],
      "modalStack": [
        {
          "id": "\(modalID.uuidString)",
          "style": "sheet",
          "root": "login",
          "path": ["otp", "otp"]
        }
      ]
    }
    """

    let decoded = try JSONDecoder().decode(TestNavigationState.self, from: Data(legacyJSON.utf8))

    #expect(decoded.stack == [TestStackRoute.dashboard, .details, .dashboard])
    #expect(decoded.stackEntries.count == 3)
    #expect(Set(decoded.stackEntries.map(\.id)).count == 3)
    #expect(decoded.modalStack[0].id == modalID)
    #expect(decoded.modalStack[0].path == [.otp, .otp])
    #expect(Set(decoded.modalStack[0].pathEntries.map(\.id)).count == 2)
}

@available(iOS 17, macOS 14, *)
@Test
@MainActor
func deepLinkInterception_canProceedRedirectCancelAndReplacePendingState() async throws {
    let coordinator = TestCoordinator(scope: .application)

    try await coordinator.applyURLDeepLink(
        URL(string: "https://example.com/settings")!,
        resolver: URLResolverMock(),
        interceptor: { _ in
            NavigationInterceptionDecision<TestStackRoute, TestModalRoute, TestAlertRoute>.proceed
        }
    )
    #expect(coordinator.stack == [TestStackRoute.dashboard, .settings])
    #expect(coordinator.pendingNavigationState == nil)

    try await coordinator.applyNotificationDeepLink(
        userInfo: ["showLogin": true],
        resolver: NotificationResolverMock(),
        interceptor: { state in
            NavigationInterceptionDecision<TestStackRoute, TestModalRoute, TestAlertRoute>.redirect(
                loginState: TestNavigationState(
                    modalStack: [ModalPresentation<TestModalRoute>(style: .sheet, root: .login)],
                    alertPresentation: AlertPresentation(route: TestAlertRoute.sessionExpired)
                ),
                pendingState: state
            )
        }
    )
    #expect(coordinator.modalStack.first?.root == TestModalRoute.login)
    #expect(coordinator.alertPresentation?.route == TestAlertRoute.sessionExpired)
    #expect(coordinator.pendingNavigationState?.stack == Optional([TestStackRoute.dashboard]))

    try await coordinator.applyURLDeepLink(
        URL(string: "myapp://settings")!,
        resolver: URLResolverMock(),
        interceptor: { state in
            NavigationInterceptionDecision<TestStackRoute, TestModalRoute, TestAlertRoute>.redirect(
                loginState: TestNavigationState(
                    modalStack: [ModalPresentation<TestModalRoute>(style: .sheet, root: .login)]
                ),
                pendingState: state
            )
        }
    )
    #expect(coordinator.pendingNavigationState?.stack == Optional([TestStackRoute.dashboard, .settings]))

    let resumedState = coordinator.resumePendingNavigation()
    #expect(resumedState?.stack == Optional([TestStackRoute.dashboard, .settings]))
    #expect(coordinator.stack == [TestStackRoute.dashboard, .settings])
    #expect(coordinator.pendingNavigationState == nil)

    try await coordinator.applyURLDeepLink(
        URL(string: "myapp://cancel")!,
        resolver: URLResolverMock(),
        interceptor: { _ in
            NavigationInterceptionDecision<TestStackRoute, TestModalRoute, TestAlertRoute>.cancel
        }
    )
    #expect(coordinator.stack == [TestStackRoute.dashboard, .settings])
    #expect(coordinator.pendingNavigationState == nil)
}

@available(iOS 17, macOS 14, *)
@Test
@MainActor
func alertLifecycle_isCoordinatorDriven() {
    let coordinator = TestCoordinator(scope: .application)

    let alertID = coordinator.presentAlert(TestAlertRoute.destructiveConfirmation)
    #expect(coordinator.alertPresentation?.id == alertID)
    #expect(coordinator.alertPresentation?.route == TestAlertRoute.destructiveConfirmation)

    let dismissed = coordinator.dismissAlert()
    #expect(dismissed?.id == alertID)
    #expect(coordinator.alertPresentation == nil)
}

@available(iOS 17, macOS 14, *)
@Test
func codableHelpers_roundTripEntriesAndSheetPresentation() throws {
    let entry = NavigationEntry<TestStackRoute>(route: .dashboard)
    let options = SheetPresentationOptions(
        detents: [.medium, .height(320)],
        background: .thickMaterial,
        backgroundInteraction: .enabledThrough(.height(320)),
        interactiveDismissDisabled: true
    )

    let entryData = try JSONEncoder().encode(entry)
    let optionsData = try JSONEncoder().encode(options)

    let decodedEntry = try JSONDecoder().decode(NavigationEntry<TestStackRoute>.self, from: entryData)
    let decodedOptions = try JSONDecoder().decode(SheetPresentationOptions.self, from: optionsData)

    #expect(decodedEntry == entry)
    #expect(decodedOptions == options)
}

@available(iOS 17, macOS 14, *)
@Test
@MainActor
func childCoordinatorLifecycle_cleanupReleasesFinishedFlows() {
    let coordinator = TestCoordinator(scope: .application)
    let child = ChildCoordinatorMock()

    coordinator.attachChild(child)
    #expect(coordinator.activeChildCoordinatorIDs.count == 1)

    child.isFlowFinished = true
    coordinator.cleanupChildCoordinators()
    #expect(coordinator.activeChildCoordinatorIDs.isEmpty)
}

@available(iOS 17, macOS 14, *)
@Test
func coordinatorOperations_workInAsyncMainActorContexts() async {
    let coordinator = await MainActor.run {
        TestCoordinator(scope: .application)
    }

    let dashboardID = await MainActor.run {
        coordinator.push(TestStackRoute.dashboard)
    }

    let snapshot = await MainActor.run {
        _ = coordinator.presentAlert(TestAlertRoute.genericError)
        return coordinator.exportState()
    }

    #expect(snapshot.stack == [TestStackRoute.dashboard])
    #expect(snapshot.stackEntries.first?.id == dashboardID)
    #expect(snapshot.alertPresentation?.route == TestAlertRoute.genericError)
}

@available(iOS 17, macOS 14, *)
@Test
@MainActor
func routingView_acceptsAlertAndSheetDrivenCoordinatorState() {
    let coordinator = TestCoordinator(scope: .application)
    _ = coordinator.present(
        TestModalRoute.login,
        style: .sheet,
        sheetPresentation: SheetPresentationOptions(detents: [.medium, .large])
    )
    _ = coordinator.presentAlert(TestAlertRoute.genericError)

    let view = RoutingView(
        coordinator: coordinator,
        root: { Text("Root") },
        stackDestination: { (_: TestStackRoute) in Text("Stack") },
        modalDestination: { (_: TestModalRoute) in Text("Modal") },
        alertDestination: { (route: TestAlertRoute) in
            AlertDescriptor(title: route.rawValue, actions: [.dismiss()])
        }
    )

    _ = view.body
    #expect(coordinator.modalStack.first?.sheetPresentation?.detents == Optional([SheetDetent.medium, .large]))
    #expect(coordinator.alertPresentation?.route == TestAlertRoute.genericError)
}

@Test
func coordinatorScope_decodesLegacyAssociatedValueKeys() throws {
    let legacyFeatureData = Data(#"{"feature":{"_0":"checkout"}}"#.utf8)
    let legacyTabData = Data(#"{"tab":{"_0":"home"}}"#.utf8)

    let featureScope = try JSONDecoder().decode(CoordinatorScope.self, from: legacyFeatureData)
    let tabScope = try JSONDecoder().decode(CoordinatorScope.self, from: legacyTabData)

    #expect(featureScope == .feature(name: "checkout"))
    #expect(tabScope == .tab(name: "home"))
}

@Test
func coordinatorScope_encodesBothLegacyAndNamedKeys() throws {
    let scope = CoordinatorScope.feature(name: "checkout")
    let data = try JSONEncoder().encode(scope)
    let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let featurePayload = payload?["feature"] as? [String: String]

    #expect(featurePayload?["name"] == "checkout")
    #expect(featurePayload?["_0"] == "checkout")
}
