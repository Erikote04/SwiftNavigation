import Foundation

/// A single active alert snapshot.
public struct AlertPresentation<Route: NavigationRoute>: Codable, Hashable, Identifiable, Sendable {
    /// Stable identifier for the alert instance.
    public let id: UUID
    /// Route associated with the alert being presented.
    public var route: Route

    /// Creates an alert presentation snapshot.
    ///
    /// - Parameters:
    ///   - id: Identifier for the alert instance.
    ///   - route: Alert route to render.
    public init(
        id: UUID = UUID(),
        route: Route
    ) {
        self.id = id
        self.route = route
    }
}

/// Button role used by a navigation alert descriptor.
public enum AlertActionRole: String, Codable, Hashable, Sendable {
    case `default`
    case cancel
    case destructive
}

/// Library-owned description of a SwiftUI alert.
public struct AlertDescriptor {
    /// Alert title shown as the primary heading.
    public var title: String
    /// Optional secondary message displayed below the title.
    public var message: String?
    /// Button actions shown in the alert.
    public var actions: [AlertAction]

    /// Creates an alert descriptor.
    ///
    /// - Parameters:
    ///   - title: Primary alert title.
    ///   - message: Optional supporting copy.
    ///   - actions: Button actions rendered in the alert.
    public init(
        title: String,
        message: String? = nil,
        actions: [AlertAction] = [.dismiss()]
    ) {
        self.title = title
        self.message = message
        self.actions = actions
    }
}

/// Library-owned description of a single alert button.
public struct AlertAction: Identifiable {
    /// Stable identifier for the action.
    public let id: UUID
    /// User-facing action title.
    public let title: String
    /// Alert button role.
    public let role: AlertActionRole
    /// Whether tapping the action should dismiss the current alert.
    public let dismissesAlert: Bool

    private let handler: (@MainActor @Sendable () -> Void)?

    /// Creates an alert action.
    ///
    /// - Parameters:
    ///   - id: Stable identifier for the action.
    ///   - title: User-facing title.
    ///   - role: Button role.
    ///   - dismissesAlert: Whether the alert should dismiss after the action runs.
    ///   - handler: Optional handler executed when the button is tapped.
    public init(
        id: UUID = UUID(),
        title: String,
        role: AlertActionRole = .default,
        dismissesAlert: Bool = true,
        handler: (@MainActor @Sendable () -> Void)? = nil
    ) {
        self.id = id
        self.title = title
        self.role = role
        self.dismissesAlert = dismissesAlert
        self.handler = handler
    }

    /// Creates a dismiss-only action.
    ///
    /// - Parameters:
    ///   - title: User-facing title.
    ///   - role: Button role.
    /// - Returns: A dismiss-only alert action.
    public static func dismiss(
        _ title: String = "OK",
        role: AlertActionRole = .cancel
    ) -> AlertAction {
        AlertAction(title: title, role: role)
    }

    @MainActor
    func perform() {
        handler?()
    }
}
