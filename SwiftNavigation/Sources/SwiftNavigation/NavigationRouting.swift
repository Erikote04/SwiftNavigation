import Foundation

/// Lightweight lifecycle contract used to clean up finished child coordinators.
@MainActor
public protocol CoordinatorLifecycle: AnyObject {
    /// Stable identifier for the coordinator instance.
    var coordinatorID: UUID { get }
    /// Indicates whether the coordinator's flow has no active stack or modal state.
    var isFlowFinished: Bool { get }
}

/// Protocol abstraction intended for ViewModel-level decoupling.
@MainActor
public protocol NavigationRouting: AnyObject {
    /// Route type used by the root navigation stack.
    associatedtype StackRoute: NavigationRoute
    /// Route type used by modal flows.
    associatedtype ModalRoute: NavigationRoute

    /// Current root stack path.
    var stack: [StackRoute] { get }
    /// Current modal presentation stack.
    var modalStack: [ModalPresentation<ModalRoute>] { get }

    /// Pushes a route onto the root navigation stack.
    ///
    /// - Parameter route: Route appended to the top of the stack.
    func push(_ route: StackRoute)

    /// Pops the last route from the root navigation stack.
    ///
    /// - Returns: The removed route, or `nil` when the stack is empty.
    @discardableResult
    func pop() -> StackRoute?

    /// Clears the root navigation stack.
    func popToRoot()

    /// Pops stack entries until the last route matching a predicate becomes top-most.
    ///
    /// - Parameter predicate: Predicate used to find the target route.
    /// - Returns: The resulting top route after trimming, or `nil` if no route matched.
    @discardableResult
    func popToView(where predicate: (StackRoute) -> Bool) -> StackRoute?

    /// Presents a modal flow on top of the current UI stack.
    ///
    /// - Parameters:
    ///   - route: Root route for the modal flow.
    ///   - style: Modal presentation style.
    func present(_ route: ModalRoute, style: ModalPresentationStyle)

    /// Dismisses the top-most modal flow.
    ///
    /// - Returns: The removed modal snapshot, or `nil` if no modal is active.
    @discardableResult
    func dismissTopModal() -> ModalPresentation<ModalRoute>?

    /// Dismisses all modals from the provided depth to the top of the modal stack.
    ///
    /// - Parameter depth: First modal index to remove.
    func dismissModals(from depth: Int)

    /// Exports the complete navigation snapshot.
    ///
    /// - Returns: Serializable state containing stack and modal information.
    func exportState() -> NavigationState<StackRoute, ModalRoute>

    /// Restores the coordinator from a previously captured snapshot.
    ///
    /// - Parameter state: Snapshot to apply as current navigation state.
    func restore(from state: NavigationState<StackRoute, ModalRoute>)
}

/// URL-based deep-link reconstruction contract.
public protocol URLDeeplinkResolving {
    /// Route type used by the root navigation stack.
    associatedtype StackRoute: NavigationRoute
    /// Route type used by modal flows.
    associatedtype ModalRoute: NavigationRoute

    /// Maps a URL into a full navigation snapshot.
    ///
    /// - Parameter url: Incoming deep-link URL.
    /// - Returns: Navigation state reconstructed from the URL.
    /// - Throws: Resolver-specific parsing errors.
    func navigationState(for url: URL) throws -> NavigationState<StackRoute, ModalRoute>
}

/// Notification payload-based deep-link reconstruction contract.
public protocol NotificationDeeplinkResolving {
    /// Route type used by the root navigation stack.
    associatedtype StackRoute: NavigationRoute
    /// Route type used by modal flows.
    associatedtype ModalRoute: NavigationRoute

    /// Maps a notification payload into a full navigation snapshot.
    ///
    /// - Parameter userInfo: Notification payload dictionary.
    /// - Returns: Navigation state reconstructed from the payload.
    /// - Throws: Resolver-specific decoding or validation errors.
    func navigationState(for userInfo: [AnyHashable: Any]) throws -> NavigationState<StackRoute, ModalRoute>
}
