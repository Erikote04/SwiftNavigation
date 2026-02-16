import Foundation

/// Presentation type for modal navigation.
public enum ModalPresentationStyle: String, Codable, Hashable, Sendable {
    case sheet
    case fullScreen
}

/// A single modal flow snapshot.
public struct ModalPresentation<Route: NavigationRoute>: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var style: ModalPresentationStyle
    public var root: Route
    public var path: [Route]

    public init(
        id: UUID = UUID(),
        style: ModalPresentationStyle,
        root: Route,
        path: [Route] = []
    ) {
        self.id = id
        self.style = style
        self.root = root
        self.path = path
    }
}

/// Full coordinator snapshot used for restoration and deep links.
public struct NavigationState<StackRoute: NavigationRoute, ModalRoute: NavigationRoute>: Codable, Hashable, Sendable {
    public var stack: [StackRoute]
    public var modalStack: [ModalPresentation<ModalRoute>]

    public init(
        stack: [StackRoute] = [],
        modalStack: [ModalPresentation<ModalRoute>] = []
    ) {
        self.stack = stack
        self.modalStack = modalStack
    }
}

/// Logical coordinator boundary for modular architectures.
public enum CoordinatorScope: Codable, Hashable, Sendable {
    case application
    case feature(String)
    case tab(String)
}
