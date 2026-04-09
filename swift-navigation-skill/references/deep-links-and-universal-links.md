# Deep Links, Notifications, Universal Links, and Interception

## Rebuild NavigationState from External Inputs

Implement resolvers instead of replaying navigation imperatively.

## URL Resolver Pattern

```swift
struct AppURLResolver: URLDeepLinkResolving {
    func navigationState(for url: URL) throws -> NavigationState<AppRoute, AppModalRoute, Never> {
        // Parse the URL and return the full stack/modal state.
    }
}
```

The resolver should:

- validate the scheme or host
- parse path segments and query items
- choose the preferred tab or root context if needed
- return the full `NavigationState`

## Notification Resolver Pattern

```swift
struct AppNotificationResolver: NotificationDeepLinkResolving {
    func navigationState(for userInfo: [AnyHashable: Any]) throws -> NavigationState<AppRoute, AppModalRoute, Never> {
        // Decode payload fields and return the full state.
    }
}
```

Prefer this for notification taps, silent push routing, or payload-driven entry points.

## Apply URL and Notification Deep Links

```swift
try await coordinator.applyURLDeepLink(url, resolver: AppURLResolver())

try await coordinator.applyNotificationDeepLink(
    userInfo: payload,
    resolver: AppNotificationResolver()
)
```

## Intercept Protected Destinations

Use interception when login or another prerequisite must happen first:

```swift
try await coordinator.applyURLDeepLink(url, resolver: AppURLResolver()) { state in
    guard sessionStore.isAuthenticated else {
        return .redirect(
            loginState: NavigationState(
                modalStack: [.init(style: .sheet, root: .signIn(signInRoute))]
            ),
            pendingState: state
        )
    }

    return .proceed
}
```

When login finishes:

```swift
coordinator.resumePendingNavigation()
```

If the pending deep link should be abandoned:

```swift
coordinator.clearPendingNavigation()
```

Only one pending state is stored at a time, so a newer redirect replaces the previous pending destination.

## Universal Links

Treat universal links as ordinary `https` URLs flowing through the same resolver pipeline:

```swift
.onOpenURL { url in
    Task {
        try? await coordinator.applyURLDeepLink(url, resolver: AppURLResolver())
    }
}
.onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
    guard let url = activity.webpageURL else { return }
    Task {
        try? await coordinator.applyURLDeepLink(url, resolver: AppURLResolver())
    }
}
```

Keep the app responsible for:

- Associated Domains entitlement
- `apple-app-site-association`
- hosted domain ownership and configuration

Keep SwiftNavigation responsible for turning the URL into `NavigationState`.

## Notification Tap Bridging

If a notification delegate exists outside SwiftUI, bridge it into the app coordinator with `NotificationCenter` or another app-level event handoff, then call the notification resolver from the root coordinator.

## Recommended Parsing Strategy

- Centralize URL and payload parsing in one parser namespace.
- Prefer explicit validation errors over silent fallback.
- Return empty `NavigationState()` only when an input is valid but intentionally maps to the app root.
