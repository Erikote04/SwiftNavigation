import Foundation

/// Result of an external navigation interception decision.
public enum NavigationInterceptionDecision<
    StackRoute: NavigationRoute,
    ModalRoute: NavigationRoute,
    AlertRoute: NavigationRoute
>: Sendable {
    /// Apply the resolved destination immediately.
    case proceed
    /// Redirect to a new state while storing the original destination for later resume.
    case redirect(
        loginState: NavigationState<StackRoute, ModalRoute, AlertRoute>,
        pendingState: NavigationState<StackRoute, ModalRoute, AlertRoute>
    )
    /// Ignore the resolved destination.
    case cancel
}

/// Async interceptor invoked before external navigation is applied.
public typealias NavigationStateInterceptor<
    StackRoute: NavigationRoute,
    ModalRoute: NavigationRoute,
    AlertRoute: NavigationRoute
> = @MainActor (
    NavigationState<StackRoute, ModalRoute, AlertRoute>
) async -> NavigationInterceptionDecision<StackRoute, ModalRoute, AlertRoute>
