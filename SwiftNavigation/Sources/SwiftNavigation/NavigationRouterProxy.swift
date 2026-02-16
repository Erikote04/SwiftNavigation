import Foundation

@available(iOS 17, macOS 14, *)
@MainActor
public final class NavigationRouterProxy<StackRoute: NavigationRoute, ModalRoute: NavigationRoute>: NavigationRouting {
    private weak var coordinator: NavigationCoordinator<StackRoute, ModalRoute>?

    public init(coordinator: NavigationCoordinator<StackRoute, ModalRoute>) {
        self.coordinator = coordinator
    }

    public var stack: [StackRoute] {
        coordinator?.stack ?? []
    }

    public var modalStack: [ModalPresentation<ModalRoute>] {
        coordinator?.modalStack ?? []
    }

    public func push(_ route: StackRoute) {
        coordinator?.push(route)
    }

    @discardableResult
    public func pop() -> StackRoute? {
        coordinator?.pop()
    }

    public func popToRoot() {
        coordinator?.popToRoot()
    }

    @discardableResult
    public func popToView(where predicate: (StackRoute) -> Bool) -> StackRoute? {
        coordinator?.popToView(where: predicate)
    }

    public func present(_ route: ModalRoute, style: ModalPresentationStyle) {
        coordinator?.present(route, style: style)
    }

    @discardableResult
    public func dismissTopModal() -> ModalPresentation<ModalRoute>? {
        coordinator?.dismissTopModal()
    }

    public func dismissModals(from depth: Int) {
        coordinator?.dismissModals(from: depth)
    }

    public func exportState() -> NavigationState<StackRoute, ModalRoute> {
        coordinator?.exportState() ?? NavigationState()
    }

    public func restore(from state: NavigationState<StackRoute, ModalRoute>) {
        coordinator?.restore(from: state)
    }
}
