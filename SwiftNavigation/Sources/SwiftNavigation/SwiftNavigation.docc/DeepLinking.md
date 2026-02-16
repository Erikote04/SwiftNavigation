# Deep Linking

Use resolvers to translate URLs or notification payloads into complete `NavigationState` values.

## URL Resolver

```swift
import Foundation
import SwiftNavigation

struct AppURLResolver: URLDeeplinkResolving {
    func navigationState(for url: URL) throws -> NavigationState<AppRoute, AppModalRoute> {
        if url.host == "settings" {
            return NavigationState(stack: [.profile, .settings])
        }

        if url.host == "login" {
            return NavigationState(
                stack: [.profile],
                modalStack: [ModalPresentation(style: .sheet, root: .signIn)]
            )
        }

        return NavigationState(stack: [.profile])
    }
}
```

## Apply URL State

```swift
try coordinator.applyURLDeeplink(url, resolver: AppURLResolver())
```

## Notification Resolver

```swift
struct AppNotificationResolver: NotificationDeeplinkResolving {
    func navigationState(for userInfo: [AnyHashable: Any]) throws -> NavigationState<AppRoute, AppModalRoute> {
        let openTerms = (userInfo["openTerms"] as? Bool) == true
        return NavigationState(
            stack: [.profile],
            modalStack: openTerms ? [ModalPresentation(style: .fullScreen, root: .terms)] : []
        )
    }
}
```

## Apply Notification State

```swift
try coordinator.applyNotificationDeeplink(userInfo: payload, resolver: AppNotificationResolver())
```

By returning full snapshots, resolvers can reconstruct deeply nested navigation hierarchies in a deterministic way.
