# Deep Linking

Use resolvers to translate URLs or notification payloads into complete `NavigationState` values.

## URL Resolver

```swift
import Foundation
import SwiftNavigation

struct AppURLResolver: URLDeepLinkResolving {
    func navigationState(for url: URL) throws -> NavigationState<AppRoute, AppModalRoute, Never> {
        if url.host == "settings" {
            return NavigationState(stack: [.profile, .settings])
        }

        if url.host == "login" || url.path == "/login" {
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
try coordinator.applyURLDeepLink(url, resolver: AppURLResolver())
```

The same resolver can handle both custom schemes and universal links:

- `myapp://settings`
- `https://example.com/settings`

## Notification Resolver

```swift
struct AppNotificationResolver: NotificationDeepLinkResolving {
    func navigationState(for userInfo: [AnyHashable: Any]) throws -> NavigationState<AppRoute, AppModalRoute, Never> {
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
try coordinator.applyNotificationDeepLink(userInfo: payload, resolver: AppNotificationResolver())
```

By returning full snapshots, resolvers can reconstruct deeply nested navigation hierarchies in a deterministic way.

If a destination must pass through authentication first, pair your resolver with <doc:DeepLinkInterception>. If you are wiring `https` URLs from Associated Domains, see <doc:UniversalLinks>.
