import Foundation

/// Router adapter that forwards navigation calls to a coordinator.
@available(iOS 17, macOS 14, *)
@MainActor
public final class NavigationRouterProxy<
    StackRoute: NavigationRoute,
    ModalRoute: NavigationRoute,
    AlertRoute: NavigationRoute
>: NavigationRouting {
    private weak var coordinator: NavigationCoordinator<StackRoute, ModalRoute, AlertRoute>?

    /// Creates a router proxy bound to a coordinator.
    ///
    /// - Parameter coordinator: Coordinator that will receive forwarded routing calls.
    public init(coordinator: NavigationCoordinator<StackRoute, ModalRoute, AlertRoute>) {
        self.coordinator = coordinator
    }

    /// Current root navigation stack entries.
    public var stackEntries: [NavigationEntry<StackRoute>] {
        coordinator?.stackEntries ?? []
    }

    /// Current root navigation stack.
    public var stack: [StackRoute] {
        coordinator?.stack ?? []
    }

    /// Current modal navigation stack.
    public var modalStack: [ModalPresentation<ModalRoute>] {
        coordinator?.modalStack ?? []
    }

    /// Current active alert presentation.
    public var alertPresentation: AlertPresentation<AlertRoute>? {
        coordinator?.alertPresentation
    }

    /// Current pending intercepted navigation state.
    public var pendingNavigationState: NavigationState<StackRoute, ModalRoute, AlertRoute>? {
        coordinator?.pendingNavigationState
    }

    /// Pushes a route onto the root stack.
    ///
    /// - Parameter route: Route to append.
    public func push(_ route: StackRoute) -> NavigationEntryID {
        coordinator?.push(route) ?? NavigationEntryID()
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
    public func popToRoute(where predicate: (StackRoute) -> Bool) -> StackRoute? {
        coordinator?.popToRoute(where: predicate)
    }

    /// Pops stack entries until the matching entry becomes top-most.
    ///
    /// - Parameter id: Entry identifier to locate.
    /// - Returns: The matching top entry after trimming, or `nil` if not found.
    @discardableResult
    public func popToEntry(_ id: NavigationEntryID) -> NavigationEntry<StackRoute>? {
        coordinator?.popToEntry(id)
    }

    /// Indicates whether the stack contains a matching entry identifier.
    ///
    /// - Parameter id: Entry identifier to search for.
    /// - Returns: `true` when the identifier exists in the root stack.
    public func containsEntry(_ id: NavigationEntryID) -> Bool {
        coordinator?.containsEntry(id) ?? false
    }

    /// Pops stack entries until the last route matching a predicate becomes top-most.
    ///
    /// - Parameter predicate: Predicate used to find the destination route.
    /// - Returns: Top route after trimming, or `nil` if no route matched.
    @available(*, deprecated, renamed: "popToRoute(where:)")
    @discardableResult
    public func popToView(where predicate: (StackRoute) -> Bool) -> StackRoute? {
        popToRoute(where: predicate)
    }

    /// Presents a modal flow.
    ///
    /// - Parameters:
    ///   - route: Modal root route.
    ///   - style: Modal presentation style.
    ///   - sheetPresentation: Optional sheet presentation options.
    public func present(
        _ route: ModalRoute,
        style: ModalPresentationStyle,
        sheetPresentation: SheetPresentationOptions? = nil
    ) -> UUID {
        coordinator?.present(route, style: style, sheetPresentation: sheetPresentation) ?? UUID()
    }

    /// Presents a modal flow with a preloaded internal path.
    ///
    /// - Parameters:
    ///   - route: Modal root route.
    ///   - style: Modal presentation style.
    ///   - sheetPresentation: Optional sheet presentation options.
    ///   - path: Internal modal path to preload.
    public func present(
        _ route: ModalRoute,
        style: ModalPresentationStyle,
        sheetPresentation: SheetPresentationOptions? = nil,
        path: [ModalRoute]
    ) -> UUID {
        coordinator?.present(
            route,
            style: style,
            sheetPresentation: sheetPresentation,
            path: path
        ) ?? UUID()
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

    /// Presents a global alert.
    ///
    /// - Parameter route: Alert route to render.
    /// - Returns: Identifier assigned to the alert instance.
    public func presentAlert(_ route: AlertRoute) -> UUID {
        coordinator?.presentAlert(route) ?? UUID()
    }

    /// Dismisses the active alert.
    ///
    /// - Returns: The removed alert presentation, or `nil` if no alert is active.
    @discardableResult
    public func dismissAlert() -> AlertPresentation<AlertRoute>? {
        coordinator?.dismissAlert()
    }

    /// Exports the current navigation snapshot.
    ///
    /// - Returns: Current navigation state, or an empty state when coordinator is unavailable.
    public func exportState() -> NavigationState<StackRoute, ModalRoute, AlertRoute> {
        coordinator?.exportState()
            ?? NavigationState<StackRoute, ModalRoute, AlertRoute>(stackEntries: [])
    }

    /// Restores navigation from a snapshot.
    ///
    /// - Parameter state: Snapshot to apply.
    public func restore(from state: NavigationState<StackRoute, ModalRoute, AlertRoute>) {
        coordinator?.restore(from: state)
    }

    /// Resumes a pending intercepted navigation request.
    ///
    /// - Returns: The resumed state, or `nil` if no pending state exists.
    @discardableResult
    public func resumePendingNavigation() -> NavigationState<StackRoute, ModalRoute, AlertRoute>? {
        coordinator?.resumePendingNavigation()
    }

    /// Clears any pending intercepted navigation request.
    ///
    /// - Returns: The removed pending state, or `nil` if no pending state exists.
    @discardableResult
    public func clearPendingNavigation() -> NavigationState<StackRoute, ModalRoute, AlertRoute>? {
        coordinator?.clearPendingNavigation()
    }
}
