import Foundation
import Observation

/// Main navigation engine that owns root stack navigation, nested modal flows,
/// state restoration, alerts, and deep-link reconstruction.
@available(iOS 17, macOS 14, *)
@MainActor
@Observable
public final class NavigationCoordinator<
    StackRoute: NavigationRoute,
    ModalRoute: NavigationRoute,
    AlertRoute: NavigationRoute
>: NavigationRouting, CoordinatorLifecycle {
    /// Stable identifier for this coordinator instance.
    public let coordinatorID: UUID
    /// Scope describing where this coordinator is used in the app architecture.
    public let scope: CoordinatorScope

    /// Current root navigation stack entries.
    public var stackEntries: [NavigationEntry<StackRoute>]
    /// Current modal presentation stack.
    public var modalStack: [ModalPresentation<ModalRoute>]
    /// Current active alert presentation.
    public var alertPresentation: AlertPresentation<AlertRoute>?
    /// Pending navigation state stored after interception redirects.
    public private(set) var pendingNavigationState: NavigationState<StackRoute, ModalRoute, AlertRoute>?

    @ObservationIgnored
    private var childCoordinatorRefs: [UUID: AnyWeakChildCoordinator] = [:]

    /// Current root navigation stack routes.
    public var stack: [StackRoute] {
        stackEntries.map(\.route)
    }

    /// Creates a coordinator with an optional preloaded navigation state.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the coordinator instance.
    ///   - scope: Logical scope where this coordinator operates.
    ///   - stack: Initial root stack state.
    ///   - modalStack: Initial modal stack state.
    ///   - alertPresentation: Optional active alert presentation.
    ///   - pendingNavigationState: Optional pending intercepted navigation state.
    public convenience init(
        id: UUID = UUID(),
        scope: CoordinatorScope,
        stack: [StackRoute] = [],
        modalStack: [ModalPresentation<ModalRoute>] = [],
        alertPresentation: AlertPresentation<AlertRoute>? = nil,
        pendingNavigationState: NavigationState<StackRoute, ModalRoute, AlertRoute>? = nil
    ) {
        self.init(
            id: id,
            scope: scope,
            stackEntries: stack.map { NavigationEntry(route: $0) },
            modalStack: modalStack,
            alertPresentation: alertPresentation,
            pendingNavigationState: pendingNavigationState
        )
    }

    /// Creates a coordinator using prebuilt stack entries.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the coordinator instance.
    ///   - scope: Logical scope where this coordinator operates.
    ///   - stackEntries: Initial entry-backed root stack state.
    ///   - modalStack: Initial modal stack state.
    ///   - alertPresentation: Optional active alert presentation.
    ///   - pendingNavigationState: Optional pending intercepted navigation state.
    public init(
        id: UUID = UUID(),
        scope: CoordinatorScope,
        stackEntries: [NavigationEntry<StackRoute>],
        modalStack: [ModalPresentation<ModalRoute>] = [],
        alertPresentation: AlertPresentation<AlertRoute>? = nil,
        pendingNavigationState: NavigationState<StackRoute, ModalRoute, AlertRoute>? = nil
    ) {
        self.coordinatorID = id
        self.scope = scope
        self.stackEntries = stackEntries
        self.modalStack = modalStack
        self.alertPresentation = alertPresentation
        self.pendingNavigationState = pendingNavigationState
    }

    /// Indicates whether stack, modal, and alert state are all empty.
    public var isFlowFinished: Bool {
        stackEntries.isEmpty && modalStack.isEmpty && alertPresentation == nil
    }

    /// Child coordinator IDs for currently active (non-finished) child flows.
    public var activeChildCoordinatorIDs: [UUID] {
        childCoordinatorRefs.values.compactMap { ref in
            guard let coordinator = ref.coordinator, !coordinator.isFlowFinished else {
                return nil
            }
            return coordinator.coordinatorID
        }
    }

    /// Attaches a child coordinator using weak ownership for lifecycle tracking.
    ///
    /// - Parameter child: Child coordinator to track.
    public func attachChild<Child: CoordinatorLifecycle>(_ child: Child) {
        childCoordinatorRefs[child.coordinatorID] = WeakChildCoordinatorRef(child)
        cleanupChildCoordinators()
    }

    /// Detaches a child coordinator by identifier.
    ///
    /// - Parameter id: Identifier of the child coordinator to remove.
    public func detachChild(id: UUID) {
        childCoordinatorRefs[id] = nil
    }

    /// Removes child references that are deallocated or have finished their flows.
    public func cleanupChildCoordinators() {
        childCoordinatorRefs = childCoordinatorRefs.filter { _, ref in
            guard let coordinator = ref.coordinator else {
                return false
            }
            return !coordinator.isFlowFinished
        }
    }

    /// Pushes a route onto the root navigation stack.
    ///
    /// - Parameter route: Route appended at the top of the root stack.
    /// - Returns: Identifier assigned to the pushed entry.
    @discardableResult
    public func push(_ route: StackRoute) -> NavigationEntryID {
        let entry = NavigationEntry(route: route)
        stackEntries.append(entry)
        return entry.id
    }

    /// Pops the top-most route from the root stack.
    ///
    /// - Returns: The removed route, or `nil` if the stack is empty.
    @discardableResult
    public func pop() -> StackRoute? {
        stackEntries.popLast()?.route
    }

    /// Clears the root stack, returning navigation to its root view.
    public func popToRoot() {
        stackEntries.removeAll()
    }

    /// Pops routes until the last route that matches a predicate becomes top-most.
    ///
    /// - Parameter predicate: Predicate used to find the destination route.
    /// - Returns: The top route after trimming, or `nil` when no match exists.
    @discardableResult
    public func popToRoute(where predicate: (StackRoute) -> Bool) -> StackRoute? {
        guard let targetIndex = stackEntries.lastIndex(where: { predicate($0.route) }) else {
            return nil
        }

        let trailingIndex = stackEntries.index(after: targetIndex)
        if trailingIndex < stackEntries.endIndex {
            stackEntries.removeSubrange(trailingIndex...)
        }

        return stackEntries.last?.route
    }

    /// Pops routes until the matching entry becomes top-most.
    ///
    /// - Parameter id: Entry identifier used to find the destination route.
    /// - Returns: The top entry after trimming, or `nil` when no match exists.
    @discardableResult
    public func popToEntry(_ id: NavigationEntryID) -> NavigationEntry<StackRoute>? {
        guard let targetIndex = stackEntries.lastIndex(where: { $0.id == id }) else {
            return nil
        }

        let trailingIndex = stackEntries.index(after: targetIndex)
        if trailingIndex < stackEntries.endIndex {
            stackEntries.removeSubrange(trailingIndex...)
        }

        return stackEntries.last
    }

    /// Indicates whether the stack contains a matching entry identifier.
    ///
    /// - Parameter id: Identifier to search for.
    /// - Returns: `true` when a matching entry exists in the stack.
    public func containsEntry(_ id: NavigationEntryID) -> Bool {
        stackEntries.contains(where: { $0.id == id })
    }

    /// Pops routes until the last route that matches a predicate becomes top-most.
    ///
    /// - Parameter predicate: Predicate used to find the destination route.
    /// - Returns: The top route after trimming, or `nil` when no match exists.
    @available(*, deprecated, renamed: "popToRoute(where:)")
    @discardableResult
    public func popToView(where predicate: (StackRoute) -> Bool) -> StackRoute? {
        popToRoute(where: predicate)
    }

    /// Presents a new modal flow.
    ///
    /// - Parameters:
    ///   - route: Root route for the presented modal flow.
    ///   - style: Presentation style (`sheet` or `fullScreen`).
    ///   - sheetPresentation: Optional sheet presentation configuration.
    /// - Returns: Identifier assigned to the modal presentation.
    @discardableResult
    public func present(
        _ route: ModalRoute,
        style: ModalPresentationStyle = .sheet,
        sheetPresentation: SheetPresentationOptions? = nil
    ) -> UUID {
        present(route, style: style, sheetPresentation: sheetPresentation, path: [])
    }

    /// Presents a new modal flow with a prebuilt internal navigation path.
    ///
    /// - Parameters:
    ///   - route: Root route for the presented modal flow.
    ///   - style: Presentation style (`sheet` or `fullScreen`).
    ///   - sheetPresentation: Optional sheet presentation configuration.
    ///   - path: Internal modal stack path to preload.
    /// - Returns: Identifier assigned to the modal presentation.
    @discardableResult
    public func present(
        _ route: ModalRoute,
        style: ModalPresentationStyle = .sheet,
        sheetPresentation: SheetPresentationOptions? = nil,
        path: [ModalRoute]
    ) -> UUID {
        let modal = ModalPresentation(
            style: style,
            root: route,
            sheetPresentation: sheetPresentation,
            pathEntries: path.map { NavigationEntry(route: $0) }
        )
        modalStack.append(modal)
        return modal.id
    }

    /// Dismisses the top-most modal flow.
    ///
    /// - Returns: The removed modal snapshot, or `nil` if no modal is active.
    @discardableResult
    public func dismissTopModal() -> ModalPresentation<ModalRoute>? {
        modalStack.popLast()
    }

    /// Dismisses all modal flows from a specific depth to the top.
    ///
    /// - Parameter depth: First modal index to remove.
    public func dismissModals(from depth: Int) {
        guard modalStack.indices.contains(depth) else {
            return
        }

        modalStack.removeSubrange(depth...)
    }

    /// Returns the modal snapshot located at a specific depth.
    ///
    /// - Parameter depth: Modal stack index to read.
    /// - Returns: Modal snapshot at the given depth, or `nil` if out of bounds.
    @discardableResult
    public func modal(at depth: Int) -> ModalPresentation<ModalRoute>? {
        guard modalStack.indices.contains(depth) else {
            return nil
        }
        return modalStack[depth]
    }

    /// Returns the internal path of a modal flow.
    ///
    /// - Parameter depth: Modal stack index to read.
    /// - Returns: Modal internal path, or an empty array when depth is invalid.
    public func modalPath(at depth: Int) -> [ModalRoute] {
        modal(at: depth)?.path ?? []
    }

    /// Returns the internal path entries of a modal flow.
    ///
    /// - Parameter depth: Modal stack index to read.
    /// - Returns: Modal path entries, or an empty array when depth is invalid.
    public func modalPathEntries(at depth: Int) -> [NavigationEntry<ModalRoute>] {
        modal(at: depth)?.pathEntries ?? []
    }

    /// Replaces the internal path of a modal flow.
    ///
    /// - Parameters:
    ///   - path: New modal internal path.
    ///   - depth: Modal stack index to update.
    public func setModalPath(_ path: [ModalRoute], at depth: Int) {
        guard modalStack.indices.contains(depth) else {
            return
        }
        modalStack[depth].pathEntries = reconcileEntries(
            existing: modalStack[depth].pathEntries,
            updatedRoutes: path
        )
    }

    /// Replaces the root stack using route values emitted by SwiftUI.
    ///
    /// - Parameter routes: Route-only stack emitted by native navigation APIs.
    public func setStackRoutes(_ routes: [StackRoute]) {
        stackEntries = reconcileEntries(existing: stackEntries, updatedRoutes: routes)
    }

    /// Replaces a modal snapshot at a specific depth.
    ///
    /// - Parameters:
    ///   - modal: Updated modal snapshot.
    ///   - depth: Modal stack index to update.
    public func setModal(_ modal: ModalPresentation<ModalRoute>, at depth: Int) {
        guard modalStack.indices.contains(depth) else {
            return
        }
        modalStack[depth] = modal
    }

    /// Pushes a route inside a modal's own `NavigationStack`.
    ///
    /// - Parameters:
    ///   - route: Route appended inside the modal flow.
    ///   - depth: Modal stack index to update.
    /// - Returns: Identifier assigned to the pushed modal path entry, or `nil` if depth is invalid.
    @discardableResult
    public func pushModalRoute(_ route: ModalRoute, at depth: Int) -> NavigationEntryID? {
        guard modalStack.indices.contains(depth) else {
            return nil
        }
        let entry = NavigationEntry(route: route)
        modalStack[depth].pathEntries.append(entry)
        return entry.id
    }

    /// Pops the top route from a modal's internal `NavigationStack`.
    ///
    /// - Parameter depth: Modal stack index to update.
    /// - Returns: Removed modal route, or `nil` if unavailable.
    @discardableResult
    public func popModalRoute(at depth: Int) -> ModalRoute? {
        guard modalStack.indices.contains(depth) else {
            return nil
        }
        return modalStack[depth].pathEntries.popLast()?.route
    }

    /// Clears a modal's internal navigation path.
    ///
    /// - Parameter depth: Modal stack index to update.
    public func popModalToRoot(at depth: Int) {
        guard modalStack.indices.contains(depth) else {
            return
        }
        modalStack[depth].pathEntries.removeAll()
    }

    /// Pops routes in a modal flow until the last matching route becomes top-most.
    ///
    /// - Parameters:
    ///   - predicate: Predicate used to find the destination route.
    ///   - depth: Modal stack index to update.
    /// - Returns: Top modal route after trimming, or `nil` if no route matched.
    @discardableResult
    public func popModalToRoute(where predicate: (ModalRoute) -> Bool, at depth: Int) -> ModalRoute? {
        guard modalStack.indices.contains(depth) else {
            return nil
        }

        guard let targetIndex = modalStack[depth].pathEntries.lastIndex(where: { predicate($0.route) }) else {
            return nil
        }

        let trailingIndex = modalStack[depth].pathEntries.index(after: targetIndex)
        if trailingIndex < modalStack[depth].pathEntries.endIndex {
            modalStack[depth].pathEntries.removeSubrange(trailingIndex...)
        }

        return modalStack[depth].pathEntries.last?.route
    }

    /// Pops modal path entries until the matching entry becomes top-most.
    ///
    /// - Parameters:
    ///   - id: Entry identifier used to find the destination route.
    ///   - depth: Modal stack index to update.
    /// - Returns: Top modal entry after trimming, or `nil` if no route matched.
    @discardableResult
    public func popModalToEntry(_ id: NavigationEntryID, at depth: Int) -> NavigationEntry<ModalRoute>? {
        guard modalStack.indices.contains(depth) else {
            return nil
        }

        guard let targetIndex = modalStack[depth].pathEntries.lastIndex(where: { $0.id == id }) else {
            return nil
        }

        let trailingIndex = modalStack[depth].pathEntries.index(after: targetIndex)
        if trailingIndex < modalStack[depth].pathEntries.endIndex {
            modalStack[depth].pathEntries.removeSubrange(trailingIndex...)
        }

        return modalStack[depth].pathEntries.last
    }

    /// Indicates whether a modal path contains a matching entry identifier.
    ///
    /// - Parameters:
    ///   - id: Entry identifier to search for.
    ///   - depth: Modal stack index to read.
    /// - Returns: `true` when a matching entry exists in the modal path.
    public func containsModalEntry(_ id: NavigationEntryID, at depth: Int) -> Bool {
        guard modalStack.indices.contains(depth) else {
            return false
        }

        return modalStack[depth].pathEntries.contains(where: { $0.id == id })
    }

    /// Pops routes in a modal flow until the last matching route becomes top-most.
    ///
    /// - Parameters:
    ///   - predicate: Predicate used to find the destination route.
    ///   - depth: Modal stack index to update.
    /// - Returns: Top modal route after trimming, or `nil` if no route matched.
    @available(*, deprecated, renamed: "popModalToRoute(where:at:)")
    @discardableResult
    public func popModalToView(where predicate: (ModalRoute) -> Bool, at depth: Int) -> ModalRoute? {
        popModalToRoute(where: predicate, at: depth)
    }

    /// Presents a new global alert.
    ///
    /// - Parameter route: Alert route to present.
    /// - Returns: Identifier assigned to the alert instance.
    @discardableResult
    public func presentAlert(_ route: AlertRoute) -> UUID {
        let presentation = AlertPresentation(route: route)
        alertPresentation = presentation
        return presentation.id
    }

    /// Dismisses the active alert.
    ///
    /// - Returns: The removed alert presentation, or `nil` if no alert is active.
    @discardableResult
    public func dismissAlert() -> AlertPresentation<AlertRoute>? {
        defer { alertPresentation = nil }
        return alertPresentation
    }

    /// Exports the complete navigation state.
    ///
    /// - Returns: Serializable snapshot of root, modal, and alert navigation state.
    public func exportState() -> NavigationState<StackRoute, ModalRoute, AlertRoute> {
        NavigationState(
            stackEntries: stackEntries,
            modalStack: modalStack,
            alertPresentation: alertPresentation
        )
    }

    /// Restores navigation state from a previously exported snapshot.
    ///
    /// - Parameter state: Snapshot to apply.
    public func restore(from state: NavigationState<StackRoute, ModalRoute, AlertRoute>) {
        stackEntries = state.stackEntries
        modalStack = state.modalStack
        alertPresentation = state.alertPresentation
        cleanupChildCoordinators()
    }

    /// Resets all navigation state and performs child cleanup.
    public func reset() {
        stackEntries.removeAll()
        modalStack.removeAll()
        alertPresentation = nil
        pendingNavigationState = nil
        cleanupChildCoordinators()
    }

    /// Applies a URL deep link by resolving it into a navigation snapshot.
    ///
    /// - Parameters:
    ///   - url: Incoming deep-link URL.
    ///   - resolver: Resolver that maps the URL to a navigation state.
    /// - Throws: Errors propagated by the resolver.
    public func applyURLDeepLink<Resolver: URLDeepLinkResolving>(
        _ url: URL,
        resolver: Resolver
    ) throws where Resolver.StackRoute == StackRoute, Resolver.ModalRoute == ModalRoute {
        let resolvedState = try resolver.navigationState(for: url)
        restore(from: NavigationState(
            stackEntries: resolvedState.stackEntries,
            modalStack: resolvedState.modalStack
        ))
        pendingNavigationState = nil
    }

    /// Applies a URL deep link by resolving it into a navigation snapshot and running interception.
    ///
    /// - Parameters:
    ///   - url: Incoming deep-link URL.
    ///   - resolver: Resolver that maps the URL to a navigation state.
    ///   - interceptor: Async interceptor invoked before the destination is applied.
    /// - Throws: Errors propagated by the resolver.
    public func applyURLDeepLink<Resolver: URLDeepLinkResolving>(
        _ url: URL,
        resolver: Resolver,
        interceptor: NavigationStateInterceptor<StackRoute, ModalRoute, AlertRoute>
    ) async throws where Resolver.StackRoute == StackRoute, Resolver.ModalRoute == ModalRoute {
        let resolvedState = try resolver.navigationState(for: url)
        let state = NavigationState<StackRoute, ModalRoute, AlertRoute>(
            stackEntries: resolvedState.stackEntries,
            modalStack: resolvedState.modalStack
        )
        let decision = await interceptor(state)
        applyInterception(decision, fallbackState: state)
    }

    /// Applies a URL deep link by resolving it into a navigation snapshot.
    ///
    /// - Parameters:
    ///   - url: Incoming deep-link URL.
    ///   - resolver: Resolver that maps the URL to a navigation state.
    /// - Throws: Errors propagated by the resolver.
    @available(*, deprecated, renamed: "applyURLDeepLink(_:resolver:)")
    public func applyURLDeeplink<Resolver: URLDeepLinkResolving>(
        _ url: URL,
        resolver: Resolver
    ) throws where Resolver.StackRoute == StackRoute, Resolver.ModalRoute == ModalRoute {
        try applyURLDeepLink(url, resolver: resolver)
    }

    /// Applies a notification deep link by resolving payload data into state.
    ///
    /// - Parameters:
    ///   - userInfo: Notification payload dictionary.
    ///   - resolver: Resolver that maps payload data to a navigation state.
    /// - Throws: Errors propagated by the resolver.
    public func applyNotificationDeepLink<Resolver: NotificationDeepLinkResolving>(
        userInfo: [AnyHashable: Any],
        resolver: Resolver
    ) throws where Resolver.StackRoute == StackRoute, Resolver.ModalRoute == ModalRoute {
        let resolvedState = try resolver.navigationState(for: userInfo)
        restore(from: NavigationState(
            stackEntries: resolvedState.stackEntries,
            modalStack: resolvedState.modalStack
        ))
        pendingNavigationState = nil
    }

    /// Applies a notification deep link by resolving payload data into state and running interception.
    ///
    /// - Parameters:
    ///   - userInfo: Notification payload dictionary.
    ///   - resolver: Resolver that maps payload data to a navigation state.
    ///   - interceptor: Async interceptor invoked before the destination is applied.
    /// - Throws: Errors propagated by the resolver.
    public func applyNotificationDeepLink<Resolver: NotificationDeepLinkResolving>(
        userInfo: [AnyHashable: Any],
        resolver: Resolver,
        interceptor: NavigationStateInterceptor<StackRoute, ModalRoute, AlertRoute>
    ) async throws where Resolver.StackRoute == StackRoute, Resolver.ModalRoute == ModalRoute {
        let resolvedState = try resolver.navigationState(for: userInfo)
        let state = NavigationState<StackRoute, ModalRoute, AlertRoute>(
            stackEntries: resolvedState.stackEntries,
            modalStack: resolvedState.modalStack
        )
        let decision = await interceptor(state)
        applyInterception(decision, fallbackState: state)
    }

    /// Applies a notification deep link by resolving payload data into state.
    ///
    /// - Parameters:
    ///   - userInfo: Notification payload dictionary.
    ///   - resolver: Resolver that maps payload data to a navigation state.
    /// - Throws: Errors propagated by the resolver.
    @available(*, deprecated, renamed: "applyNotificationDeepLink(userInfo:resolver:)")
    public func applyNotificationDeeplink<Resolver: NotificationDeepLinkResolving>(
        userInfo: [AnyHashable: Any],
        resolver: Resolver
    ) throws where Resolver.StackRoute == StackRoute, Resolver.ModalRoute == ModalRoute {
        try applyNotificationDeepLink(userInfo: userInfo, resolver: resolver)
    }

    /// Resumes a pending intercepted navigation request if available.
    ///
    /// - Returns: The resumed state, or `nil` when no pending state exists.
    @discardableResult
    public func resumePendingNavigation() -> NavigationState<StackRoute, ModalRoute, AlertRoute>? {
        guard let state = pendingNavigationState else {
            return nil
        }

        restore(from: state)
        pendingNavigationState = nil
        return state
    }

    /// Clears any pending intercepted navigation request.
    ///
    /// - Returns: The removed pending state, or `nil` when no pending state exists.
    @discardableResult
    public func clearPendingNavigation() -> NavigationState<StackRoute, ModalRoute, AlertRoute>? {
        defer { pendingNavigationState = nil }
        return pendingNavigationState
    }

    private func applyInterception(
        _ decision: NavigationInterceptionDecision<StackRoute, ModalRoute, AlertRoute>,
        fallbackState: NavigationState<StackRoute, ModalRoute, AlertRoute>
    ) {
        switch decision {
        case .proceed:
            restore(from: fallbackState)
            pendingNavigationState = nil

        case .redirect(let loginState, let pendingState):
            restore(from: loginState)
            pendingNavigationState = pendingState

        case .cancel:
            pendingNavigationState = nil
        }
    }

    private func reconcileEntries<Route: NavigationRoute>(
        existing: [NavigationEntry<Route>],
        updatedRoutes: [Route]
    ) -> [NavigationEntry<Route>] {
        let existingRoutes = existing.map(\.route)
        let sharedPrefixCount = zip(existingRoutes, updatedRoutes)
            .prefix { existingRoute, updatedRoute in
                existingRoute == updatedRoute
            }
            .count

        let preservedPrefix = Array(existing.prefix(sharedPrefixCount))
        let appendedEntries = updatedRoutes
            .dropFirst(sharedPrefixCount)
            .map { NavigationEntry(route: $0) }
        return preservedPrefix + appendedEntries
    }
}

private protocol AnyWeakChildCoordinator: AnyObject {
    /// Returns the underlying coordinator instance if it is still alive.
    var coordinator: CoordinatorLifecycle? { get }
}

/// Weak reference wrapper used to avoid retaining child coordinators.
private final class WeakChildCoordinatorRef<Child: CoordinatorLifecycle>: AnyWeakChildCoordinator {
    weak var child: Child?

    /// Creates a weak wrapper around a child coordinator.
    ///
    /// - Parameter child: Child coordinator reference to wrap.
    init(_ child: Child) {
        self.child = child
    }

    /// Returns the wrapped coordinator while it is still retained elsewhere.
    var coordinator: CoordinatorLifecycle? {
        child
    }
}
