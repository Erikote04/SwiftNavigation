import SwiftUI

@available(iOS 17, macOS 14, *)
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

    public init(
        coordinator: NavigationCoordinator<StackRoute, ModalRoute>,
        @ViewBuilder root: @escaping () -> Root,
        @ViewBuilder destination: @escaping (StackRoute) -> StackDestination,
        @ViewBuilder modalDestination: @escaping (ModalRoute) -> ModalDestination
    ) {
        _coordinator = Bindable(coordinator)
        self.root = root
        self.stackDestination = destination
        self.modalDestination = modalDestination
    }

    public var body: some View {
        ModalLayerHost(coordinator: coordinator, depth: 0, modalDestination: modalDestination) {
            NavigationStack(path: $coordinator.stack) {
                root()
                    .navigationDestination(for: StackRoute.self, destination: stackDestination)
            }
        }
    }
}

@available(iOS 17, macOS 14, *)
private struct ModalLayerHost<
    StackRoute: NavigationRoute,
    ModalRoute: NavigationRoute,
    ModalDestination: View
>: View {
    @Bindable var coordinator: NavigationCoordinator<StackRoute, ModalRoute>
    let depth: Int
    let modalDestination: (ModalRoute) -> ModalDestination
    let content: AnyView

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

    @ViewBuilder
    private func modalContent(_ modal: ModalPresentation<ModalRoute>) -> some View {
        ModalLayerHost(coordinator: coordinator, depth: depth + 1, modalDestination: modalDestination) {
            NavigationStack(path: modalPathBinding(at: depth)) {
                modalDestination(modal.root)
                    .navigationDestination(for: ModalRoute.self, destination: modalDestination)
            }
        }
    }

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
