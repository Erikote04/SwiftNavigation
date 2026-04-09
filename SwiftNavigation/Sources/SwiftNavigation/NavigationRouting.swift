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
    /// Route type used by global alerts.
    associatedtype AlertRoute: NavigationRoute

    /// Current root stack entries.
    var stackEntries: [NavigationEntry<StackRoute>] { get }
    /// Current root stack path.
    var stack: [StackRoute] { get }
    /// Current modal presentation stack.
    var modalStack: [ModalPresentation<ModalRoute>] { get }
    /// Current active alert presentation.
    var alertPresentation: AlertPresentation<AlertRoute>? { get }
    /// Pending intercepted navigation waiting to resume.
    var pendingNavigationState: NavigationState<StackRoute, ModalRoute, AlertRoute>? { get }

    /// Pushes a route onto the root navigation stack.
    ///
    /// - Parameter route: Route appended to the top of the stack.
    /// - Returns: Identifier assigned to the pushed entry.
    func push(_ route: StackRoute) -> NavigationEntryID

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
    func popToRoute(where predicate: (StackRoute) -> Bool) -> StackRoute?

    /// Pops stack entries until the matching entry becomes top-most.
    ///
    /// - Parameter id: Identifier used to find the target entry.
    /// - Returns: The resulting top entry after trimming, or `nil` if no match exists.
    @discardableResult
    func popToEntry(_ id: NavigationEntryID) -> NavigationEntry<StackRoute>?

    /// Indicates whether the stack contains a matching entry identifier.
    ///
    /// - Parameter id: Identifier to search for.
    /// - Returns: `true` when a matching entry exists in the stack.
    func containsEntry(_ id: NavigationEntryID) -> Bool

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
    ///   - sheetPresentation: Optional sheet-specific presentation options.
    /// - Returns: Identifier assigned to the modal presentation instance.
    func present(
        _ route: ModalRoute,
        style: ModalPresentationStyle,
        sheetPresentation: SheetPresentationOptions?
    ) -> UUID

    /// Presents a modal flow on top of the current UI stack with a preloaded modal path.
    ///
    /// - Parameters:
    ///   - route: Root route for the modal flow.
    ///   - style: Modal presentation style.
    ///   - sheetPresentation: Optional sheet-specific presentation options.
    ///   - path: Internal modal path to preload.
    /// - Returns: Identifier assigned to the modal presentation instance.
    func present(
        _ route: ModalRoute,
        style: ModalPresentationStyle,
        sheetPresentation: SheetPresentationOptions?,
        path: [ModalRoute]
    ) -> UUID

    /// Dismisses the top-most modal flow.
    ///
    /// - Returns: The removed modal snapshot, or `nil` if no modal is active.
    @discardableResult
    func dismissTopModal() -> ModalPresentation<ModalRoute>?

    /// Dismisses all modals from the provided depth to the top of the modal stack.
    ///
    /// - Parameter depth: First modal index to remove.
    func dismissModals(from depth: Int)

    /// Presents a global alert.
    ///
    /// - Parameter route: Alert route to render.
    /// - Returns: Identifier assigned to the alert instance.
    func presentAlert(_ route: AlertRoute) -> UUID

    /// Dismisses the active alert.
    ///
    /// - Returns: The removed alert presentation, or `nil` if no alert is active.
    @discardableResult
    func dismissAlert() -> AlertPresentation<AlertRoute>?

    /// Exports the complete navigation snapshot.
    ///
    /// - Returns: Serializable state containing stack and modal information.
    func exportState() -> NavigationState<StackRoute, ModalRoute, AlertRoute>

    /// Restores the coordinator from a previously captured snapshot.
    ///
    /// - Parameter state: Snapshot to apply as current navigation state.
    func restore(from state: NavigationState<StackRoute, ModalRoute, AlertRoute>)

    /// Resumes a pending intercepted navigation request if available.
    ///
    /// - Returns: The resumed state, or `nil` when no pending state exists.
    @discardableResult
    func resumePendingNavigation() -> NavigationState<StackRoute, ModalRoute, AlertRoute>?

    /// Clears any pending intercepted navigation request.
    ///
    /// - Returns: The removed pending state, or `nil` when no pending state exists.
    @discardableResult
    func clearPendingNavigation() -> NavigationState<StackRoute, ModalRoute, AlertRoute>?
}

public extension NavigationRouting {
    /// Pops stack entries until the last route matching a predicate becomes top-most.
    ///
    /// - Parameter predicate: Predicate used to find the target route.
    /// - Returns: The resulting top route after trimming, or `nil` if no route matched.
    @discardableResult
    func popToRoute(where predicate: (StackRoute) -> Bool) -> StackRoute? {
        popToView(where: predicate)
    }
}

/// URL-based deep-link reconstruction contract.
@available(iOS 17, macOS 14, *)
public protocol URLDeepLinkResolving {
    /// Route type used by the root navigation stack.
    associatedtype StackRoute: NavigationRoute
    /// Route type used by modal flows.
    associatedtype ModalRoute: NavigationRoute

    /// Maps a URL into a full navigation snapshot.
    ///
    /// - Parameter url: Incoming deep-link URL.
    /// - Returns: Navigation state reconstructed from the URL.
    /// - Throws: Resolver-specific parsing errors.
    func navigationState(for url: URL) throws -> NavigationState<StackRoute, ModalRoute, Never>
}

/// Notification payload-based deep-link reconstruction contract.
@available(iOS 17, macOS 14, *)
public protocol NotificationDeepLinkResolving {
    /// Route type used by the root navigation stack.
    associatedtype StackRoute: NavigationRoute
    /// Route type used by modal flows.
    associatedtype ModalRoute: NavigationRoute

    /// Maps a notification payload into a full navigation snapshot.
    ///
    /// - Parameter userInfo: Notification payload dictionary.
    /// - Returns: Navigation state reconstructed from the payload.
    /// - Throws: Resolver-specific decoding or validation errors.
    func navigationState(for userInfo: [AnyHashable: Any]) throws -> NavigationState<StackRoute, ModalRoute, Never>
}

@available(iOS 17, macOS 14, *)
@available(*, deprecated, renamed: "URLDeepLinkResolving")
public typealias URLDeeplinkResolving = URLDeepLinkResolving

@available(iOS 17, macOS 14, *)
@available(*, deprecated, renamed: "NotificationDeepLinkResolving")
public typealias NotificationDeeplinkResolving = NotificationDeepLinkResolving
