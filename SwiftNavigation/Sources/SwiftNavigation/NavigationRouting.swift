import Foundation

/// Lightweight lifecycle contract used to clean up finished child coordinators.
@MainActor
public protocol CoordinatorLifecycle: AnyObject {
    var coordinatorID: UUID { get }
    var isFlowFinished: Bool { get }
}

/// Protocol abstraction intended for ViewModel-level decoupling.
@MainActor
public protocol NavigationRouting: AnyObject {
    associatedtype StackRoute: NavigationRoute
    associatedtype ModalRoute: NavigationRoute

    var stack: [StackRoute] { get }
    var modalStack: [ModalPresentation<ModalRoute>] { get }

    func push(_ route: StackRoute)
    @discardableResult
    func pop() -> StackRoute?
    func popToRoot()
    @discardableResult
    func popToView(where predicate: (StackRoute) -> Bool) -> StackRoute?

    func present(_ route: ModalRoute, style: ModalPresentationStyle)
    @discardableResult
    func dismissTopModal() -> ModalPresentation<ModalRoute>?
    func dismissModals(from depth: Int)

    func exportState() -> NavigationState<StackRoute, ModalRoute>
    func restore(from state: NavigationState<StackRoute, ModalRoute>)
}

/// URL-based deep-link reconstruction contract.
public protocol URLDeeplinkResolving {
    associatedtype StackRoute: NavigationRoute
    associatedtype ModalRoute: NavigationRoute

    func navigationState(for url: URL) throws -> NavigationState<StackRoute, ModalRoute>
}

/// Notification payload-based deep-link reconstruction contract.
public protocol NotificationDeeplinkResolving {
    associatedtype StackRoute: NavigationRoute
    associatedtype ModalRoute: NavigationRoute

    func navigationState(for userInfo: [AnyHashable: Any]) throws -> NavigationState<StackRoute, ModalRoute>
}
