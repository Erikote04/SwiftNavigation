import Foundation
import Observation

@available(iOS 17, macOS 14, *)
@MainActor
@Observable
public final class NavigationCoordinator<StackRoute: NavigationRoute, ModalRoute: NavigationRoute>: NavigationRouting, CoordinatorLifecycle {
    public let coordinatorID: UUID
    public let scope: CoordinatorScope

    public var stack: [StackRoute]
    public var modalStack: [ModalPresentation<ModalRoute>]

    @ObservationIgnored
    private var childCoordinatorRefs: [UUID: AnyWeakChildCoordinator] = [:]

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

    public var isFlowFinished: Bool {
        stack.isEmpty && modalStack.isEmpty
    }

    public var activeChildCoordinatorIDs: [UUID] {
        childCoordinatorRefs.values.compactMap { ref in
            guard let coordinator = ref.coordinator, !coordinator.isFlowFinished else {
                return nil
            }
            return coordinator.coordinatorID
        }
    }

    public func attachChild<Child: CoordinatorLifecycle>(_ child: Child) {
        childCoordinatorRefs[child.coordinatorID] = WeakChildCoordinatorRef(child)
        cleanupChildCoordinators()
    }

    public func detachChild(id: UUID) {
        childCoordinatorRefs[id] = nil
    }

    public func cleanupChildCoordinators() {
        childCoordinatorRefs = childCoordinatorRefs.filter { _, ref in
            guard let coordinator = ref.coordinator else {
                return false
            }
            return !coordinator.isFlowFinished
        }
    }

    public func push(_ route: StackRoute) {
        stack.append(route)
    }

    @discardableResult
    public func pop() -> StackRoute? {
        stack.popLast()
    }

    public func popToRoot() {
        stack.removeAll()
    }

    @discardableResult
    public func popToView(where predicate: (StackRoute) -> Bool) -> StackRoute? {
        guard let targetIndex = stack.lastIndex(where: predicate) else {
            return nil
        }

        let trailingIndex = stack.index(after: targetIndex)
        if trailingIndex < stack.endIndex {
            stack.removeSubrange(trailingIndex...)
        }

        return stack.last
    }

    public func present(_ route: ModalRoute, style: ModalPresentationStyle = .sheet) {
        modalStack.append(ModalPresentation(style: style, root: route))
    }

    public func present(
        _ route: ModalRoute,
        style: ModalPresentationStyle = .sheet,
        path: [ModalRoute]
    ) {
        modalStack.append(ModalPresentation(style: style, root: route, path: path))
    }

    @discardableResult
    public func dismissTopModal() -> ModalPresentation<ModalRoute>? {
        modalStack.popLast()
    }

    public func dismissModals(from depth: Int) {
        guard modalStack.indices.contains(depth) else {
            return
        }

        modalStack.removeSubrange(depth...)
    }

    @discardableResult
    public func modal(at depth: Int) -> ModalPresentation<ModalRoute>? {
        guard modalStack.indices.contains(depth) else {
            return nil
        }
        return modalStack[depth]
    }

    public func modalPath(at depth: Int) -> [ModalRoute] {
        modal(at: depth)?.path ?? []
    }

    public func setModalPath(_ path: [ModalRoute], at depth: Int) {
        guard modalStack.indices.contains(depth) else {
            return
        }
        modalStack[depth].path = path
    }

    public func setModal(_ modal: ModalPresentation<ModalRoute>, at depth: Int) {
        guard modalStack.indices.contains(depth) else {
            return
        }
        modalStack[depth] = modal
    }

    public func pushModalRoute(_ route: ModalRoute, at depth: Int) {
        guard modalStack.indices.contains(depth) else {
            return
        }
        modalStack[depth].path.append(route)
    }

    @discardableResult
    public func popModalRoute(at depth: Int) -> ModalRoute? {
        guard modalStack.indices.contains(depth) else {
            return nil
        }
        return modalStack[depth].path.popLast()
    }

    public func popModalToRoot(at depth: Int) {
        guard modalStack.indices.contains(depth) else {
            return
        }
        modalStack[depth].path.removeAll()
    }

    @discardableResult
    public func popModalToView(where predicate: (ModalRoute) -> Bool, at depth: Int) -> ModalRoute? {
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

    public func exportState() -> NavigationState<StackRoute, ModalRoute> {
        NavigationState(stack: stack, modalStack: modalStack)
    }

    public func restore(from state: NavigationState<StackRoute, ModalRoute>) {
        stack = state.stack
        modalStack = state.modalStack
        cleanupChildCoordinators()
    }

    public func reset() {
        stack.removeAll()
        modalStack.removeAll()
        cleanupChildCoordinators()
    }

    public func applyURLDeeplink<Resolver: URLDeeplinkResolving>(
        _ url: URL,
        resolver: Resolver
    ) throws where Resolver.StackRoute == StackRoute, Resolver.ModalRoute == ModalRoute {
        let state = try resolver.navigationState(for: url)
        restore(from: state)
    }

    public func applyNotificationDeeplink<Resolver: NotificationDeeplinkResolving>(
        userInfo: [AnyHashable: Any],
        resolver: Resolver
    ) throws where Resolver.StackRoute == StackRoute, Resolver.ModalRoute == ModalRoute {
        let state = try resolver.navigationState(for: userInfo)
        restore(from: state)
    }
}

private protocol AnyWeakChildCoordinator: AnyObject {
    var coordinator: CoordinatorLifecycle? { get }
}

private final class WeakChildCoordinatorRef<Child: CoordinatorLifecycle>: AnyWeakChildCoordinator {
    weak var child: Child?

    init(_ child: Child) {
        self.child = child
    }

    var coordinator: CoordinatorLifecycle? {
        child
    }
}
