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
    case feature(name: String)
    /// Scope for a tab-specific coordinator.
    case tab(name: String)

    @available(*, deprecated, renamed: "feature(name:)")
    public static func feature(_ name: String) -> CoordinatorScope {
        .feature(name: name)
    }

    @available(*, deprecated, renamed: "tab(name:)")
    public static func tab(_ name: String) -> CoordinatorScope {
        .tab(name: name)
    }

    private enum CodingKeys: String, CodingKey {
        case application
        case feature
        case tab
    }

    private enum AssociatedValueKeys: String, CodingKey {
        case name
        case _0
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.contains(.application) {
            self = .application
            return
        }

        if container.contains(.feature) {
            let nested = try container.nestedContainer(keyedBy: AssociatedValueKeys.self, forKey: .feature)
            if let name = try nested.decodeIfPresent(String.self, forKey: .name)
                ?? nested.decodeIfPresent(String.self, forKey: ._0) {
                self = .feature(name: name)
                return
            }
            throw DecodingError.dataCorruptedError(
                forKey: .feature,
                in: container,
                debugDescription: "Missing associated value for feature scope."
            )
        }

        if container.contains(.tab) {
            let nested = try container.nestedContainer(keyedBy: AssociatedValueKeys.self, forKey: .tab)
            if let name = try nested.decodeIfPresent(String.self, forKey: .name)
                ?? nested.decodeIfPresent(String.self, forKey: ._0) {
                self = .tab(name: name)
                return
            }
            throw DecodingError.dataCorruptedError(
                forKey: .tab,
                in: container,
                debugDescription: "Missing associated value for tab scope."
            )
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Invalid CoordinatorScope payload."
            )
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .application:
            _ = container.nestedContainer(keyedBy: AssociatedValueKeys.self, forKey: .application)
        case .feature(name: let name):
            var nested = container.nestedContainer(keyedBy: AssociatedValueKeys.self, forKey: .feature)
            try nested.encode(name, forKey: .name)
            try nested.encode(name, forKey: ._0)
        case .tab(name: let name):
            var nested = container.nestedContainer(keyedBy: AssociatedValueKeys.self, forKey: .tab)
            try nested.encode(name, forKey: .name)
            try nested.encode(name, forKey: ._0)
        }
    }
}
