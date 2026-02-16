import Foundation

/// Type-erased router adapter that forwards navigation calls to a coordinator.
@available(iOS 17, macOS 14, *)
@MainActor
public final class NavigationRouterProxy<StackRoute: NavigationRoute, ModalRoute: NavigationRoute>: NavigationRouting {
    private weak var coordinator: NavigationCoordinator<StackRoute, ModalRoute>?

    /// Creates a router proxy bound to a coordinator.
    ///
    /// - Parameter coordinator: Coordinator that will receive forwarded routing calls.
    public init(coordinator: NavigationCoordinator<StackRoute, ModalRoute>) {
        self.coordinator = coordinator
    }

    /// Current root navigation stack.
    public var stack: [StackRoute] {
        coordinator?.stack ?? []
    }

    /// Current modal navigation stack.
    public var modalStack: [ModalPresentation<ModalRoute>] {
        coordinator?.modalStack ?? []
    }

    /// Pushes a route onto the root stack.
    ///
    /// - Parameter route: Route to append.
    public func push(_ route: StackRoute) {
        coordinator?.push(route)
    }

    /// Pops the top route from the root stack.
    ///
    /// - Returns: Removed route, or `nil` when the stack is empty.
    @discardableResult
    public func pop() -> StackRoute? {
        coordinator?.pop()
    }

    /// Clears the root stack.
    public func popToRoot() {
        coordinator?.popToRoot()
    }

    /// Pops stack entries until the last route matching a predicate becomes top-most.
    ///
    /// - Parameter predicate: Predicate used to find the destination route.
    /// - Returns: Top route after trimming, or `nil` if no route matched.
    @discardableResult
    public func popToView(where predicate: (StackRoute) -> Bool) -> StackRoute? {
        coordinator?.popToView(where: predicate)
    }

    /// Presents a modal flow.
    ///
    /// - Parameters:
    ///   - route: Modal root route.
    ///   - style: Modal presentation style.
    public func present(_ route: ModalRoute, style: ModalPresentationStyle) {
        coordinator?.present(route, style: style)
    }

    /// Dismisses the top-most modal flow.
    ///
    /// - Returns: Removed modal snapshot, or `nil` if no modal is active.
    @discardableResult
    public func dismissTopModal() -> ModalPresentation<ModalRoute>? {
        coordinator?.dismissTopModal()
    }

    /// Dismisses all modals from a specific depth.
    ///
    /// - Parameter depth: First modal index to remove.
    public func dismissModals(from depth: Int) {
        coordinator?.dismissModals(from: depth)
    }

    /// Exports the current navigation snapshot.
    ///
    /// - Returns: Current navigation state, or an empty state when coordinator is unavailable.
    public func exportState() -> NavigationState<StackRoute, ModalRoute> {
        coordinator?.exportState() ?? NavigationState()
    }

    /// Restores navigation from a snapshot.
    ///
    /// - Parameter state: Snapshot to apply.
    public func restore(from state: NavigationState<StackRoute, ModalRoute>) {
        coordinator?.restore(from: state)
    }
}
