import SwiftUI

/// Root SwiftUI wrapper that binds a `NavigationCoordinator` to native navigation APIs.
@available(iOS 17, macOS 14, *)
@MainActor
public struct RoutingView<
    StackRoute: NavigationRoute,
    ModalRoute: NavigationRoute,
    Root: View,
    StackDestination: View,
    ModalDestination: View
>: View {
    @Bindable private var coordinator: NavigationCoordinator<StackRoute, ModalRoute>

    private let root: () -> Root
    private let stackDestination: (StackRoute) -> StackDestination
    private let modalDestination: (ModalRoute) -> ModalDestination

    /// Creates a routing container that renders stack and modal destinations.
    ///
    /// - Parameters:
    ///   - coordinator: Coordinator that owns stack and modal navigation state.
    ///   - root: Root content rendered as the base of the root `NavigationStack`.
    ///   - stackDestination: Builder for root stack route destinations.
    ///   - modalDestination: Builder for modal root and modal stack destinations.
    public init(
        coordinator: NavigationCoordinator<StackRoute, ModalRoute>,
        @ViewBuilder root: @escaping () -> Root,
        @ViewBuilder stackDestination: @escaping (StackRoute) -> StackDestination,
        @ViewBuilder modalDestination: @escaping (ModalRoute) -> ModalDestination
    ) {
        _coordinator = Bindable(coordinator)
        self.root = root
        self.stackDestination = stackDestination
        self.modalDestination = modalDestination
    }

    /// Creates a routing container that renders stack and modal destinations.
    ///
    /// - Parameters:
    ///   - coordinator: Coordinator that owns stack and modal navigation state.
    ///   - root: Root content rendered as the base of the root `NavigationStack`.
    ///   - destination: Builder for root stack route destinations.
    ///   - modalDestination: Builder for modal root and modal stack destinations.
    @available(*, deprecated, renamed: "init(coordinator:root:stackDestination:modalDestination:)")
    public init(
        coordinator: NavigationCoordinator<StackRoute, ModalRoute>,
        @ViewBuilder root: @escaping () -> Root,
        @ViewBuilder destination: @escaping (StackRoute) -> StackDestination,
        @ViewBuilder modalDestination: @escaping (ModalRoute) -> ModalDestination
    ) {
        self.init(
            coordinator: coordinator,
            root: root,
            stackDestination: destination,
            modalDestination: modalDestination
        )
    }

    /// Renders the root stack and recursively attaches nested modal presenters.
    public var body: some View {
        ModalLayerHost(coordinator: coordinator, depth: 0, modalDestination: modalDestination) {
            NavigationStack(path: $coordinator.stack) {
                root()
                    .navigationDestination(for: StackRoute.self, destination: stackDestination)
            }
        }
    }
}

/// Internal recursive presenter that allows unlimited nested modal layers.
@available(iOS 17, macOS 14, *)
@MainActor
private struct ModalLayerHost<
    StackRoute: NavigationRoute,
    ModalRoute: NavigationRoute,
    ModalDestination: View
>: View {
    @Bindable var coordinator: NavigationCoordinator<StackRoute, ModalRoute>
    let depth: Int
    let modalDestination: (ModalRoute) -> ModalDestination
    let content: AnyView

    /// Creates a recursive modal host layer.
    ///
    /// - Parameters:
    ///   - coordinator: Coordinator containing current navigation state.
    ///   - depth: Modal depth represented by this host instance.
    ///   - modalDestination: Destination builder for modal routes.
    ///   - content: View content wrapped by this modal host layer.
    init<Content: View>(
        coordinator: NavigationCoordinator<StackRoute, ModalRoute>,
        depth: Int,
        modalDestination: @escaping (ModalRoute) -> ModalDestination,
        @ViewBuilder content: () -> Content
    ) {
        _coordinator = Bindable(coordinator)
        self.depth = depth
        self.modalDestination = modalDestination
        self.content = AnyView(content())
    }

    /// Renders content and attaches presentation modifiers for the current modal depth.
    var body: some View {
        #if os(iOS)
        content
            .sheet(item: sheetBinding, onDismiss: {
                coordinator.dismissModals(from: depth)
            }, content: modalContent)
            .fullScreenCover(item: fullScreenBinding, onDismiss: {
                coordinator.dismissModals(from: depth)
            }, content: modalContent)
        #else
        content
            .sheet(item: sheetBinding, onDismiss: {
                coordinator.dismissModals(from: depth)
            }, content: modalContent)
        #endif
    }

    /// Binding for a sheet modal at the current depth.
    private var sheetBinding: Binding<ModalPresentation<ModalRoute>?> {
        Binding(
            get: {
                guard
                    let modal = coordinator.modal(at: depth),
                    modal.style == .sheet
                else {
                    return nil
                }
                return modal
            },
            set: { updatedModal in
                guard let updatedModal else {
                    coordinator.dismissModals(from: depth)
                    return
                }
                coordinator.setModal(updatedModal, at: depth)
            }
        )
    }

    /// Binding for a full-screen modal at the current depth.
    private var fullScreenBinding: Binding<ModalPresentation<ModalRoute>?> {
        Binding(
            get: {
                guard
                    let modal = coordinator.modal(at: depth),
                    modal.style == .fullScreen
                else {
                    return nil
                }
                return modal
            },
            set: { updatedModal in
                guard let updatedModal else {
                    coordinator.dismissModals(from: depth)
                    return
                }
                coordinator.setModal(updatedModal, at: depth)
            }
        )
    }

    /// Builds modal content and recursively enables nested modal presentations.
    ///
    /// - Parameter modal: Modal snapshot currently being presented.
    /// - Returns: A modal root wrapped in its own `NavigationStack`.
    @ViewBuilder
    private func modalContent(_ modal: ModalPresentation<ModalRoute>) -> some View {
        ModalLayerHost(coordinator: coordinator, depth: depth + 1, modalDestination: modalDestination) {
            NavigationStack(path: modalPathBinding(at: depth)) {
                modalDestination(modal.root)
                    .navigationDestination(for: ModalRoute.self, destination: modalDestination)
            }
        }
    }

    /// Creates a binding to a modal flow's internal navigation path.
    ///
    /// - Parameter modalDepth: Index of the modal flow in the modal stack.
    /// - Returns: Two-way binding to the modal flow's internal path.
    private func modalPathBinding(at modalDepth: Int) -> Binding<[ModalRoute]> {
        Binding(
            get: {
                coordinator.modalPath(at: modalDepth)
            },
            set: { newPath in
                coordinator.setModalPath(newPath, at: modalDepth)
            }
        )
    }
}
