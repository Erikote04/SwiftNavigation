# Deep Link Interception

Use interception when an external destination should not be applied immediately.

The most common case is authentication:

- a notification wants to open a protected profile
- the user session has expired
- the app should present login first
- after login succeeds, the original destination should resume

## Interceptor Contract

```swift
public typealias NavigationStateInterceptor<
    StackRoute,
    ModalRoute,
    AlertRoute
> = @MainActor (
    NavigationState<StackRoute, ModalRoute, AlertRoute>
) async -> NavigationInterceptionDecision<StackRoute, ModalRoute, AlertRoute>
```

The decision can be:

- `.proceed`
- `.redirect(loginState:pendingState:)`
- `.cancel`

## URL Example

```swift
try await coordinator.applyURLDeepLink(url, resolver: AppURLResolver()) { state in
    guard sessionStore.isAuthenticated else {
        return .redirect(
            loginState: NavigationState(
                modalStack: [.init(style: .sheet, root: .login)]
            ),
            pendingState: state
        )
    }

    return .proceed
}
```

## Notification Example

```swift
try await coordinator.applyNotificationDeepLink(
    userInfo: payload,
    resolver: AppNotificationResolver()
) { state in
    guard sessionStore.isAuthenticated else {
        return .redirect(
            loginState: NavigationState(
                modalStack: [.init(style: .sheet, root: .login)]
            ),
            pendingState: state
        )
    }

    return .proceed
}
```

## Resuming Pending Navigation

When login finishes:

```swift
coordinator.resumePendingNavigation()
```

If the pending destination should be discarded instead:

```swift
coordinator.clearPendingNavigation()
```

Only one pending navigation snapshot is stored at a time. A newer redirect replaces the previous pending state.
