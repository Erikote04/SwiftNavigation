import Foundation

/// Stable identifier used to distinguish individual navigation instances.
public struct NavigationEntryID: RawRepresentable, Codable, Hashable, Identifiable, Sendable {
    public let rawValue: UUID

    /// Identifier used by `Identifiable`.
    public var id: UUID {
        rawValue
    }

    /// Creates a new navigation entry identifier.
    ///
    /// - Parameter rawValue: Raw UUID value to wrap.
    public init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

/// A uniquely identifiable navigation instance for a route value.
public struct NavigationEntry<Route: NavigationRoute>: Codable, Hashable, Identifiable, Sendable {
    /// Stable identifier for this navigation instance.
    public let id: NavigationEntryID
    /// Route value represented by the entry.
    public var route: Route

    /// Creates a navigation entry.
    ///
    /// - Parameters:
    ///   - id: Identifier for the navigation instance.
    ///   - route: Route stored in the entry.
    public init(
        id: NavigationEntryID = NavigationEntryID(),
        route: Route
    ) {
        self.id = id
        self.route = route
    }
}

@available(iOS 17, macOS 14, *)
extension Never: NavigationRoute {}
