import Foundation

/// Presentation type for modal navigation.
public enum ModalPresentationStyle: String, Codable, Hashable, Sendable {
    /// Presents content as a standard sheet.
    case sheet
    /// Presents content as a full-screen cover.
    case fullScreen
}

/// A single modal flow snapshot.
public struct ModalPresentation<Route: NavigationRoute>: Identifiable, Codable, Hashable, Sendable {
    /// Stable modal identifier used by SwiftUI presentation APIs.
    public let id: UUID
    /// Presentation style used for the modal flow.
    public var style: ModalPresentationStyle
    /// Root route displayed when the modal flow starts.
    public var root: Route
    /// Internal path pushed inside the modal's own `NavigationStack`.
    public var path: [Route]

    /// Creates a modal flow snapshot.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the modal presentation instance.
    ///   - style: Presentation style (`sheet` or `fullScreen`).
    ///   - root: Root route shown when the modal is first presented.
    ///   - path: Optional nested path inside the modal flow.
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
    /// Root navigation stack path.
    public var stack: [StackRoute]
    /// Active modal stack, including nested modal navigation paths.
    public var modalStack: [ModalPresentation<ModalRoute>]

    /// Creates a full navigation snapshot.
    ///
    /// - Parameters:
    ///   - stack: Stack routes representing root navigation depth.
    ///   - modalStack: Modal presentations layered on top of the root stack.
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
    /// Scope for top-level app navigation flows.
    case application
    /// Scope for a feature-specific coordinator.
    case feature(String)
    /// Scope for a tab-specific coordinator.
    case tab(String)
}
