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
    /// Optional sheet-specific presentation options.
    public var sheetPresentation: SheetPresentationOptions?
    /// Internal path entries pushed inside the modal's own `NavigationStack`.
    public var pathEntries: [NavigationEntry<Route>]

    /// Internal path pushed inside the modal's own `NavigationStack`.
    public var path: [Route] {
        get { pathEntries.map(\.route) }
        set { pathEntries = newValue.map { NavigationEntry(route: $0) } }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case style
        case root
        case sheetPresentation
        case pathEntries
        case path
    }

    /// Creates a modal flow snapshot.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the modal presentation instance.
    ///   - style: Presentation style (`sheet` or `fullScreen`).
    ///   - root: Root route shown when the modal is first presented.
    ///   - sheetPresentation: Optional sheet presentation options.
    ///   - path: Optional nested path inside the modal flow.
    public init(
        id: UUID = UUID(),
        style: ModalPresentationStyle,
        root: Route,
        sheetPresentation: SheetPresentationOptions? = nil,
        path: [Route] = []
    ) {
        self.init(
            id: id,
            style: style,
            root: root,
            sheetPresentation: sheetPresentation,
            pathEntries: path.map { NavigationEntry(route: $0) }
        )
    }

    /// Creates a modal flow snapshot using prebuilt internal path entries.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the modal presentation instance.
    ///   - style: Presentation style (`sheet` or `fullScreen`).
    ///   - root: Root route shown when the modal is first presented.
    ///   - sheetPresentation: Optional sheet presentation options.
    ///   - pathEntries: Prebuilt internal path entries.
    public init(
        id: UUID = UUID(),
        style: ModalPresentationStyle,
        root: Route,
        sheetPresentation: SheetPresentationOptions? = nil,
        pathEntries: [NavigationEntry<Route>]
    ) {
        self.id = id
        self.style = style
        self.root = root
        self.sheetPresentation = style == .sheet ? sheetPresentation : nil
        self.pathEntries = pathEntries
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        style = try container.decode(ModalPresentationStyle.self, forKey: .style)
        root = try container.decode(Route.self, forKey: .root)
        sheetPresentation = try container.decodeIfPresent(SheetPresentationOptions.self, forKey: .sheetPresentation)

        if let decodedEntries = try container.decodeIfPresent([NavigationEntry<Route>].self, forKey: .pathEntries) {
            pathEntries = decodedEntries
        } else {
            let legacyPath = try container.decodeIfPresent([Route].self, forKey: .path) ?? []
            pathEntries = legacyPath.map { NavigationEntry(route: $0) }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(style, forKey: .style)
        try container.encode(root, forKey: .root)
        try container.encodeIfPresent(sheetPresentation, forKey: .sheetPresentation)
        try container.encode(pathEntries, forKey: .pathEntries)
    }
}

/// Full coordinator snapshot used for restoration and deep links.
public struct NavigationState<
    StackRoute: NavigationRoute,
    ModalRoute: NavigationRoute,
    AlertRoute: NavigationRoute
>: Codable, Hashable, Sendable {
    /// Root navigation stack entries.
    public var stackEntries: [NavigationEntry<StackRoute>]
    /// Active modal stack, including nested modal navigation paths.
    public var modalStack: [ModalPresentation<ModalRoute>]
    /// Current active global alert.
    public var alertPresentation: AlertPresentation<AlertRoute>?

    /// Root navigation stack routes.
    public var stack: [StackRoute] {
        get { stackEntries.map(\.route) }
        set { stackEntries = newValue.map { NavigationEntry(route: $0) } }
    }

    private enum CodingKeys: String, CodingKey {
        case stackEntries
        case stack
        case modalStack
        case alertPresentation
    }

    /// Creates a full navigation snapshot.
    ///
    /// - Parameters:
    ///   - stack: Stack routes representing root navigation depth.
    ///   - modalStack: Modal presentations layered on top of the root stack.
    ///   - alertPresentation: Optional active alert snapshot.
    public init(
        stack: [StackRoute] = [],
        modalStack: [ModalPresentation<ModalRoute>] = [],
        alertPresentation: AlertPresentation<AlertRoute>? = nil
    ) {
        self.init(
            stackEntries: stack.map { NavigationEntry(route: $0) },
            modalStack: modalStack,
            alertPresentation: alertPresentation
        )
    }

    /// Creates a full navigation snapshot using entry-backed stack values.
    ///
    /// - Parameters:
    ///   - stackEntries: Entry-backed stack values.
    ///   - modalStack: Modal presentations layered on top of the root stack.
    ///   - alertPresentation: Optional active alert snapshot.
    public init(
        stackEntries: [NavigationEntry<StackRoute>],
        modalStack: [ModalPresentation<ModalRoute>] = [],
        alertPresentation: AlertPresentation<AlertRoute>? = nil
    ) {
        self.stackEntries = stackEntries
        self.modalStack = modalStack
        self.alertPresentation = alertPresentation
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let decodedEntries = try container.decodeIfPresent([NavigationEntry<StackRoute>].self, forKey: .stackEntries) {
            stackEntries = decodedEntries
        } else {
            let legacyStack = try container.decodeIfPresent([StackRoute].self, forKey: .stack) ?? []
            stackEntries = legacyStack.map { NavigationEntry(route: $0) }
        }

        modalStack = try container.decodeIfPresent([ModalPresentation<ModalRoute>].self, forKey: .modalStack) ?? []
        alertPresentation = try container.decodeIfPresent(AlertPresentation<AlertRoute>.self, forKey: .alertPresentation)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stackEntries, forKey: .stackEntries)
        try container.encode(modalStack, forKey: .modalStack)
        try container.encodeIfPresent(alertPresentation, forKey: .alertPresentation)
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
