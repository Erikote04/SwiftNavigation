import Foundation
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
@MainActor
private final class ChildCoordinatorMock: CoordinatorLifecycle {
    let coordinatorID: UUID = UUID()
    var isFlowFinished: Bool

    init(isFlowFinished: Bool = false) {
        self.isFlowFinished = isFlowFinished
    }
}

@available(iOS 17, macOS 14, *)
private struct URLResolverMock: URLDeeplinkResolving {
    func navigationState(for url: URL) throws -> NavigationState<TestStackRoute, TestModalRoute> {
        let isSettings = url.absoluteString.contains("settings")
        return NavigationState(
            stack: isSettings ? [.dashboard, .settings] : [.dashboard],
            modalStack: []
        )
    }
}

@available(iOS 17, macOS 14, *)
private struct NotificationResolverMock: NotificationDeeplinkResolving {
    func navigationState(for userInfo: [AnyHashable: Any]) throws -> NavigationState<TestStackRoute, TestModalRoute> {
        let shouldOpenModal = (userInfo["showLogin"] as? Bool) == true
        return NavigationState(
            stack: [.dashboard],
            modalStack: shouldOpenModal ? [ModalPresentation(style: .sheet, root: .login)] : []
        )
    }
}

@available(iOS 17, macOS 14, *)
@Test @MainActor func stackOperations_areTypeSafeAndPredictable() {
    let coordinator = NavigationCoordinator<TestStackRoute, TestModalRoute>(scope: .feature("test"))

    coordinator.push(.dashboard)
    coordinator.push(.details)
    coordinator.push(.settings)

    #expect(coordinator.stack == [.dashboard, .details, .settings])

    let popped = coordinator.pop()
    #expect(popped == .settings)
    #expect(coordinator.stack == [.dashboard, .details])

    let destination = coordinator.popToView { $0 == .dashboard }
    #expect(destination == .dashboard)
    #expect(coordinator.stack == [.dashboard])

    coordinator.popToRoot()
    #expect(coordinator.stack.isEmpty)
}

@available(iOS 17, macOS 14, *)
@Test @MainActor func modalStack_supportsNestedFlowsAndDismissFromDepth() {
    let coordinator = NavigationCoordinator<TestStackRoute, TestModalRoute>(scope: .feature("auth"))

    coordinator.present(.login, style: .sheet)
    coordinator.pushModalRoute(.otp, at: 0)
    coordinator.present(.terms, style: .fullScreen, path: [.help])

    #expect(coordinator.modalStack.count == 2)
    #expect(coordinator.modalStack[0].style == .sheet)
    #expect(coordinator.modalStack[0].path == [.otp])
    #expect(coordinator.modalStack[1].style == .fullScreen)
    #expect(coordinator.modalStack[1].path == [.help])

    coordinator.dismissModals(from: 1)
    #expect(coordinator.modalStack.count == 1)
    #expect(coordinator.modalStack[0].root == .login)
}

@available(iOS 17, macOS 14, *)
@Test @MainActor func stateRestoration_roundTripsThroughCodableSnapshot() throws {
    let coordinator = NavigationCoordinator<TestStackRoute, TestModalRoute>(scope: .feature("checkout"))
    coordinator.push(.dashboard)
    coordinator.push(.summary)
    coordinator.present(.login, style: .sheet, path: [.otp])

    let snapshot = coordinator.exportState()
    let data = try JSONEncoder().encode(snapshot)
    let decoded = try JSONDecoder().decode(NavigationState<TestStackRoute, TestModalRoute>.self, from: data)

    let restored = NavigationCoordinator<TestStackRoute, TestModalRoute>(scope: .feature("checkout"))
    restored.restore(from: decoded)

    #expect(restored.stack == [.dashboard, .summary])
    #expect(restored.modalStack.count == 1)
    #expect(restored.modalStack[0].root == .login)
    #expect(restored.modalStack[0].path == [.otp])
}

@available(iOS 17, macOS 14, *)
@Test @MainActor func deeplinkResolvers_canRebuildComplexState() throws {
    let coordinator = NavigationCoordinator<TestStackRoute, TestModalRoute>(scope: .application)

    try coordinator.applyURLDeeplink(URL(string: "myapp://settings")!, resolver: URLResolverMock())
    #expect(coordinator.stack == [.dashboard, .settings])

    try coordinator.applyNotificationDeeplink(userInfo: ["showLogin": true], resolver: NotificationResolverMock())
    #expect(coordinator.stack == [.dashboard])
    #expect(coordinator.modalStack.count == 1)
    #expect(coordinator.modalStack[0].root == .login)
}

@available(iOS 17, macOS 14, *)
@Test @MainActor func childCoordinatorLifecycle_cleanupReleasesFinishedFlows() {
    let coordinator = NavigationCoordinator<TestStackRoute, TestModalRoute>(scope: .application)
    let child = ChildCoordinatorMock()

    coordinator.attachChild(child)
    #expect(coordinator.activeChildCoordinatorIDs.count == 1)

    child.isFlowFinished = true
    coordinator.cleanupChildCoordinators()
    #expect(coordinator.activeChildCoordinatorIDs.isEmpty)
}

@available(iOS 17, macOS 14, *)
@Test func coordinatorOperations_workInAsyncMainActorContexts() async {
    let coordinator = await MainActor.run {
        NavigationCoordinator<TestStackRoute, TestModalRoute>(scope: .application)
    }

    await MainActor.run {
        coordinator.push(.dashboard)
        coordinator.present(.login, style: .sheet)
    }

    let snapshot = await MainActor.run {
        coordinator.exportState()
    }

    #expect(snapshot.stack == [.dashboard])
    #expect(snapshot.modalStack.count == 1)
}
