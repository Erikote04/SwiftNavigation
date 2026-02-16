import Foundation

/// Marker protocol for routes used by the navigation engine.
///
/// Routes must be codable and hashable to support type-safe navigation,
/// deep-link reconstruction, and state restoration.
public protocol NavigationRoute: Codable, Hashable, Sendable {}
