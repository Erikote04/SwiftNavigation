import Foundation
import Observation

/// Main navigation engine that owns root stack navigation, nested modal flows,
/// state restoration, and deep-link reconstruction.
@available(iOS 17, macOS 14, *)
@MainActor
@Observable
public final class NavigationCoordinator<StackRoute: NavigationRoute, ModalRoute: NavigationRoute>: NavigationRouting, CoordinatorLifecycle {
    /// Stable identifier for this coordinator instance.
    public let coordinatorID: UUID
    /// Scope describing where this coordinator is used in the app architecture.
    public let scope: CoordinatorScope

    /// Current root navigation stack.
    public var stack: [StackRoute]
    /// Current modal presentation stack.
    public var modalStack: [ModalPresentation<ModalRoute>]

    @ObservationIgnored
    private var childCoordinatorRefs: [UUID: AnyWeakChildCoordinator] = [:]

    /// Creates a coordinator with an optional preloaded navigation state.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the coordinator instance.
    ///   - scope: Logical scope where this coordinator operates.
    ///   - stack: Initial root stack state.
    ///   - modalStack: Initial modal stack state.
    public init(
        id: UUID = UUID(),
        scope: CoordinatorScope,
        stack: [StackRoute] = [],
        modalStack: [ModalPresentation<ModalRoute>] = []
    ) {
        self.coordinatorID = id
        self.scope = scope
        self.stack = stack
        self.modalStack = modalStack
    }

    /// Indicates whether both root and modal stacks are empty.
    public var isFlowFinished: Bool {
        stack.isEmpty && modalStack.isEmpty
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
    public func push(_ route: StackRoute) {
        stack.append(route)
    }

    /// Pops the top-most route from the root stack.
    ///
    /// - Returns: The removed route, or `nil` if the stack is empty.
    @discardableResult
    public func pop() -> StackRoute? {
        stack.popLast()
    }

    /// Clears the root stack, returning navigation to its root view.
    public func popToRoot() {
        stack.removeAll()
    }

    /// Pops routes until the last route that matches a predicate becomes top-most.
    ///
    /// - Parameter predicate: Predicate used to find the destination route.
    /// - Returns: The top route after trimming, or `nil` when no match exists.
    @discardableResult
    public func popToRoute(where predicate: (StackRoute) -> Bool) -> StackRoute? {
        guard let targetIndex = stack.lastIndex(where: predicate) else {
            return nil
        }

        let trailingIndex = stack.index(after: targetIndex)
        if trailingIndex < stack.endIndex {
            stack.removeSubrange(trailingIndex...)
        }

        return stack.last
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
    public func present(_ route: ModalRoute, style: ModalPresentationStyle = .sheet) {
        modalStack.append(ModalPresentation(style: style, root: route))
    }

    /// Presents a new modal flow with a prebuilt internal navigation path.
    ///
    /// - Parameters:
    ///   - route: Root route for the presented modal flow.
    ///   - style: Presentation style (`sheet` or `fullScreen`).
    ///   - path: Internal modal stack path to preload.
    public func present(
        _ route: ModalRoute,
        style: ModalPresentationStyle = .sheet,
        path: [ModalRoute]
    ) {
        modalStack.append(ModalPresentation(style: style, root: route, path: path))
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

    /// Replaces the internal path of a modal flow.
    ///
    /// - Parameters:
    ///   - path: New modal internal path.
    ///   - depth: Modal stack index to update.
    public func setModalPath(_ path: [ModalRoute], at depth: Int) {
        guard modalStack.indices.contains(depth) else {
            return
        }
        modalStack[depth].path = path
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
    public func pushModalRoute(_ route: ModalRoute, at depth: Int) {
        guard modalStack.indices.contains(depth) else {
            return
        }
        modalStack[depth].path.append(route)
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
        return modalStack[depth].path.popLast()
    }

    /// Clears a modal's internal navigation path.
    ///
    /// - Parameter depth: Modal stack index to update.
    public func popModalToRoot(at depth: Int) {
        guard modalStack.indices.contains(depth) else {
            return
        }
        modalStack[depth].path.removeAll()
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

        guard let targetIndex = modalStack[depth].path.lastIndex(where: predicate) else {
            return nil
        }

        let trailingIndex = modalStack[depth].path.index(after: targetIndex)
        if trailingIndex < modalStack[depth].path.endIndex {
            modalStack[depth].path.removeSubrange(trailingIndex...)
        }

        return modalStack[depth].path.last
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

    /// Exports the complete navigation state.
    ///
    /// - Returns: Serializable snapshot of root and modal navigation state.
    public func exportState() -> NavigationState<StackRoute, ModalRoute> {
        NavigationState(stack: stack, modalStack: modalStack)
    }

    /// Restores navigation state from a previously exported snapshot.
    ///
    /// - Parameter state: Snapshot to apply.
    public func restore(from state: NavigationState<StackRoute, ModalRoute>) {
        stack = state.stack
        modalStack = state.modalStack
        cleanupChildCoordinators()
    }

    /// Resets both root and modal stacks and performs child cleanup.
    public func reset() {
        stack.removeAll()
        modalStack.removeAll()
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
        let state = try resolver.navigationState(for: url)
        restore(from: state)
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
        let state = try resolver.navigationState(for: userInfo)
        restore(from: state)
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
