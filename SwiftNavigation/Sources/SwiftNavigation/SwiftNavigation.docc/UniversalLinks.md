# Universal Links

SwiftNavigation does not need a separate universal-link API.

Universal links are regular `http` or `https` URLs that flow through the same resolver you already use for custom schemes.

## 1. Resolve HTTPS URLs

```swift
struct AppURLResolver: URLDeepLinkResolving {
    func navigationState(for url: URL) throws -> NavigationState<AppRoute, AppModalRoute, Never> {
        if url.scheme == "https", url.path == "/profile" {
            return NavigationState(stack: [.profile])
        }

        if url.scheme == "myapp", url.host == "profile" {
            return NavigationState(stack: [.profile])
        }

        return NavigationState()
    }
}
```

## 2. Handle both URL entry points

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

## 3. Configure Associated Domains

SwiftNavigation handles URL reconstruction only. Your app still needs the normal Apple setup:

- add an `applinks:` Associated Domains entitlement
- host an `apple-app-site-association` file on your HTTPS domain
- make sure your incoming URLs match the paths you resolve in `URLDeepLinkResolving`

See Apple's documentation for the app-side setup:

- [Allowing apps and websites to link to your content](https://developer.apple.com/documentation/xcode/allowing-apps-and-websites-to-link-to-your-content/)
- [Supporting associated domains](https://developer.apple.com/documentation/xcode/supporting-associated-domains)
