import SwiftUI

/// Root SwiftUI wrapper that binds a `NavigationCoordinator` to native navigation APIs.
@available(iOS 17, macOS 14, *)
@MainActor
public struct RoutingView<
    StackRoute: NavigationRoute,
    ModalRoute: NavigationRoute,
    AlertRoute: NavigationRoute,
    Root: View,
    StackDestination: View,
    ModalDestination: View
>: View {
    @Bindable private var coordinator: NavigationCoordinator<StackRoute, ModalRoute, AlertRoute>

    private let root: () -> Root
    private let stackDestination: (StackRoute) -> StackDestination
    private let modalDestination: (ModalRoute) -> ModalDestination
    private let alertDestination: (AlertRoute) -> AlertDescriptor

    /// Creates a routing container that renders stack, modal, and alert destinations.
    ///
    /// - Parameters:
    ///   - coordinator: Coordinator that owns stack and modal navigation state.
    ///   - root: Root content rendered as the base of the root `NavigationStack`.
    ///   - stackDestination: Builder for root stack route destinations.
    ///   - modalDestination: Builder for modal root and modal stack destinations.
    ///   - alertDestination: Builder for global alert descriptors.
    public init(
        coordinator: NavigationCoordinator<StackRoute, ModalRoute, AlertRoute>,
        @ViewBuilder root: @escaping () -> Root,
        @ViewBuilder stackDestination: @escaping (StackRoute) -> StackDestination,
        @ViewBuilder modalDestination: @escaping (ModalRoute) -> ModalDestination,
        alertDestination: @escaping (AlertRoute) -> AlertDescriptor
    ) {
        _coordinator = Bindable(coordinator)
        self.root = root
        self.stackDestination = stackDestination
        self.modalDestination = modalDestination
        self.alertDestination = alertDestination
    }

    /// Creates a routing container that renders stack, modal, and alert destinations.
    ///
    /// - Parameters:
    ///   - coordinator: Coordinator that owns stack and modal navigation state.
    ///   - root: Root content rendered as the base of the root `NavigationStack`.
    ///   - destination: Builder for root stack route destinations.
    ///   - modalDestination: Builder for modal root and modal stack destinations.
    ///   - alertDestination: Builder for global alert descriptors.
    @available(*, deprecated, renamed: "init(coordinator:root:stackDestination:modalDestination:alertDestination:)")
    public init(
        coordinator: NavigationCoordinator<StackRoute, ModalRoute, AlertRoute>,
        @ViewBuilder root: @escaping () -> Root,
        @ViewBuilder destination: @escaping (StackRoute) -> StackDestination,
        @ViewBuilder modalDestination: @escaping (ModalRoute) -> ModalDestination,
        alertDestination: @escaping (AlertRoute) -> AlertDescriptor
    ) {
        self.init(
            coordinator: coordinator,
            root: root,
            stackDestination: destination,
            modalDestination: modalDestination,
            alertDestination: alertDestination
        )
    }

    /// Renders the root stack, recursive modal presenters, and global alerts.
    public var body: some View {
        ModalLayerHost(coordinator: coordinator, depth: 0, modalDestination: modalDestination) {
            NavigationStack(path: stackBinding) {
                root()
                    .navigationDestination(for: StackRoute.self, destination: stackDestination)
            }
        }
        .alert(
            currentAlertDescriptor?.title ?? "",
            isPresented: alertIsPresented,
            presenting: currentAlertDescriptor
        ) { descriptor in
            ForEach(descriptor.actions) { action in
                Button(action.title, role: action.buttonRole) {
                    if action.dismissesAlert {
                        coordinator.dismissAlert()
                    }
                    action.perform()
                }
            }
        } message: { descriptor in
            if let message = descriptor.message {
                Text(message)
            }
        }
    }

    private var stackBinding: Binding<[StackRoute]> {
        Binding(
            get: { coordinator.stack },
            set: { coordinator.setStackRoutes($0) }
        )
    }

    private var currentAlertDescriptor: AlertDescriptor? {
        guard let route = coordinator.alertPresentation?.route else {
            return nil
        }
        return alertDestination(route)
    }

    private var alertIsPresented: Binding<Bool> {
        Binding(
            get: { coordinator.alertPresentation != nil },
            set: { isPresented in
                if !isPresented {
                    coordinator.dismissAlert()
                }
            }
        )
    }
}

@available(iOS 17, macOS 14, *)
public extension RoutingView where AlertRoute == Never {
    /// Creates a routing container for apps that do not use global alerts.
    ///
    /// - Parameters:
    ///   - coordinator: Coordinator that owns stack and modal navigation state.
    ///   - root: Root content rendered as the base of the root `NavigationStack`.
    ///   - stackDestination: Builder for root stack route destinations.
    ///   - modalDestination: Builder for modal root and modal stack destinations.
    init(
        coordinator: NavigationCoordinator<StackRoute, ModalRoute, AlertRoute>,
        @ViewBuilder root: @escaping () -> Root,
        @ViewBuilder stackDestination: @escaping (StackRoute) -> StackDestination,
        @ViewBuilder modalDestination: @escaping (ModalRoute) -> ModalDestination
    ) {
        self.init(
            coordinator: coordinator,
            root: root,
            stackDestination: stackDestination,
            modalDestination: modalDestination,
            alertDestination: { _ in
                preconditionFailure("RoutingView<..., Never> should never build an alert descriptor.")
            }
        )
    }

    /// Creates a routing container for apps that do not use global alerts.
    ///
    /// - Parameters:
    ///   - coordinator: Coordinator that owns stack and modal navigation state.
    ///   - root: Root content rendered as the base of the root `NavigationStack`.
    ///   - destination: Builder for root stack route destinations.
    ///   - modalDestination: Builder for modal root and modal stack destinations.
    @available(*, deprecated, renamed: "init(coordinator:root:stackDestination:modalDestination:)")
    init(
        coordinator: NavigationCoordinator<StackRoute, ModalRoute, AlertRoute>,
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
}

/// Internal recursive presenter that allows unlimited nested modal layers.
@available(iOS 17, macOS 14, *)
@MainActor
private struct ModalLayerHost<
    StackRoute: NavigationRoute,
    ModalRoute: NavigationRoute,
    AlertRoute: NavigationRoute,
    ModalDestination: View
>: View {
    @Bindable var coordinator: NavigationCoordinator<StackRoute, ModalRoute, AlertRoute>
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
        coordinator: NavigationCoordinator<StackRoute, ModalRoute, AlertRoute>,
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
        .applySheetPresentation(modal.sheetPresentation)
    }

    /// Creates a binding to a modal flow's internal navigation path.
    ///
    /// - Parameter modalDepth: Index of the modal flow in the modal stack.
    /// - Returns: Two-way binding to the modal flow's internal path.
    private func modalPathBinding(at modalDepth: Int) -> Binding<[ModalRoute]> {
        Binding(
            get: { coordinator.modalPath(at: modalDepth) },
            set: { coordinator.setModalPath($0, at: modalDepth) }
        )
    }
}

@available(iOS 17, macOS 14, *)
private extension AlertAction {
    var buttonRole: ButtonRole? {
        switch role {
        case .default:
            nil
        case .cancel:
            .cancel
        case .destructive:
            .destructive
        }
    }
}

@available(iOS 17, macOS 14, *)
private extension View {
    @ViewBuilder
    func applySheetPresentation(_ options: SheetPresentationOptions?) -> some View {
        if let options {
            modifier(SheetPresentationModifier(options: options))
        } else {
            self
        }
    }
}

@available(iOS 17, macOS 14, *)
private struct SheetPresentationModifier: ViewModifier {
    let options: SheetPresentationOptions

    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .presentationDetents(options.swiftUIDetents)
            .applySheetBackground(options.background)
            .applySheetBackgroundInteraction(options.backgroundInteraction)
            .interactiveDismissDisabled(options.interactiveDismissDisabled)
        #else
        content
        #endif
    }
}

@available(iOS 17, macOS 14, *)
private extension SheetPresentationOptions {
    var swiftUIDetents: Set<PresentationDetent> {
        Set(detents.map(\.swiftUIDetent))
    }
}

@available(iOS 17, macOS 14, *)
private extension SheetDetent {
    var swiftUIDetent: PresentationDetent {
        switch self {
        case .medium:
            .medium
        case .large:
            .large
        case .fraction(let value):
            .fraction(value)
        case .height(let value):
            .height(value)
        }
    }
}

@available(iOS 17, macOS 14, *)
private extension View {
    @ViewBuilder
    func applySheetBackground(_ background: SheetBackgroundStyle?) -> some View {
        #if os(iOS)
        switch background {
        case .clear:
            presentationBackground(.clear)
        case .ultraThinMaterial:
            presentationBackground(.ultraThinMaterial)
        case .thinMaterial:
            presentationBackground(.thinMaterial)
        case .regularMaterial:
            presentationBackground(.regularMaterial)
        case .thickMaterial:
            presentationBackground(.thickMaterial)
        case nil:
            self
        }
        #else
        self
        #endif
    }

    @ViewBuilder
    func applySheetBackgroundInteraction(_ interaction: SheetBackgroundInteraction?) -> some View {
        #if os(iOS)
        switch interaction {
        case nil, .automatic:
            self
        case .disabled:
            presentationBackgroundInteraction(.disabled)
        case .enabled:
            presentationBackgroundInteraction(.enabled)
        case .enabledThrough(let detent):
            presentationBackgroundInteraction(.enabled(upThrough: detent.swiftUIDetent))
        }
        #else
        self
        #endif
    }
}
