# SwiftNavigation

Type-safe, coordinator-driven navigation for SwiftUI apps using only native APIs (`NavigationStack`, `.sheet`, `.fullScreenCover`, and `.alert`).

[![Swift](https://img.shields.io/badge/Swift-6-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue.svg)](https://developer.apple.com/ios/)
[![DocC Deploy](https://github.com/Erikote04/SwiftNavigation/actions/workflows/publish-docc.yml/badge.svg)](https://github.com/Erikote04/SwiftNavigation/actions/workflows/publish-docc.yml)
[![Documentation](https://img.shields.io/badge/Documentation-GitHub%20Pages-2ea44f)](https://erikote04.github.io/SwiftNavigation/documentation/swiftnavigation/)

## Overview

`SwiftNavigation` is an MVVM-C-friendly navigation layer built around entry-backed navigation state.

- Every pushed or presented destination gets its own stable identity.
- Root stacks, modal stacks, modal-internal paths, and global alerts all live in one coordinator.
- Deep links can be intercepted asynchronously before they mutate navigation.
- Universal links reuse the same URL resolver pipeline as custom schemes.
- Codable snapshots remain compatible with older route-only state payloads.

## Key Features

- Entry-backed root navigation with `NavigationEntryID`, `push`, `popToEntry`, and duplicate-route safety.
- Recursive modal flows with their own internal stacks and exact modal-path bookmarks.
- Global typed alerts driven by `AlertPresentation`, `AlertDescriptor`, and `presentAlert`.
- Sheet-specific presentation controls for detents, backgrounds, background interaction, and interactive dismissal.
- Async external-navigation interception for login gates, redirects, and pending-state resume.
- Protocol-based router proxies that keep ViewModels decoupled from SwiftUI.

## Requirements

- iOS 26+
- Swift 6 language mode
- Xcode 16.4+

## Installation

### Xcode

1. `File` -> `Add Packages...`
2. Enter `https://github.com/Erikote04/SwiftNavigation`
3. Select the `2.x` line
4. Add the `SwiftNavigation` product to your target

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/Erikote04/SwiftNavigation", from: "2.0.0")
]
```

## Quick Start

### 1. Define routes

```swift
import SwiftNavigation

enum AppRoute: NavigationRoute {
    case home
    case paymentReview
}

enum AppModalRoute: NavigationRoute {
    case login
}

enum AppAlertRoute: NavigationRoute {
    case networkError(String)
}
```

### 2. Create a coordinator

```swift
import SwiftNavigation

@MainActor
let coordinator = NavigationCoordinator<AppRoute, AppModalRoute, AppAlertRoute>(
    scope: .application
)
```

Apps without alerts can use `Never` as the third generic:

```swift
let coordinator = NavigationCoordinator<AppRoute, AppModalRoute, Never>(
    scope: .application
)
```

### 3. Build the routing container

```swift
import SwiftUI
import SwiftNavigation

@MainActor
struct AppRootView: View {
    @State private var coordinator = NavigationCoordinator<AppRoute, AppModalRoute, AppAlertRoute>(
        scope: .application
    )

    var body: some View {
        RoutingView(
            coordinator: coordinator,
            root: {
                HomeView(
                    onOpenReview: { _ = coordinator.push(.paymentReview) },
                    onOpenLogin: {
                        _ = coordinator.present(
                            .login,
                            style: .sheet,
                            sheetPresentation: SheetPresentationOptions(
                                detents: [.medium, .large],
                                background: .regularMaterial
                            )
                        )
                    }
                )
            },
            stackDestination: { route in
                switch route {
                case .home:
                    HomeView(onOpenReview: {}, onOpenLogin: {})
                case .paymentReview:
                    PaymentReviewView()
                }
            },
            modalDestination: { route in
                switch route {
                case .login:
                    LoginView()
                }
            },
            alertDestination: { route in
                switch route {
                case .networkError(let message):
                    AlertDescriptor(
                        title: "Something went wrong",
                        message: message,
                        actions: [.dismiss("OK")]
                    )
                }
            }
        )
        .navigationCoordinator(coordinator)
    }
}
```

## Flow Bookmarks

`push(_:)` and modal-path pushes now return `NavigationEntryID`, so duplicate screens stay addressable.

```swift
let recipientEntryID = coordinator.push(.home)
let reviewEntryID = coordinator.push(.paymentReview)

coordinator.popToEntry(recipientEntryID)
```

Use the same pattern inside modal flows with `pushModalRoute(_:at:)`, `modalPathEntries(at:)`, and `popModalToEntry(_:at:)`.

## Alerts and Sheets

Present alerts from the coordinator instead of storing raw SwiftUI alert state in views:

```swift
coordinator.presentAlert(.networkError("The payment could not be completed."))
```

Customize sheets at presentation time:

```swift
_ = coordinator.present(
    .login,
    style: .sheet,
    sheetPresentation: SheetPresentationOptions(
        detents: [.medium, .large],
        background: .thinMaterial,
        backgroundInteraction: .enabledThrough(.medium),
        interactiveDismissDisabled: true
    )
)
```

## Deep Linking and Interception

Resolvers still rebuild full navigation snapshots, but v2 can now intercept them asynchronously before applying state.

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

After sign-in succeeds:

```swift
coordinator.resumePendingNavigation()
```

## State Restoration

```swift
let snapshot = coordinator.exportState()
let data = try JSONEncoder().encode(snapshot)

let restored = try JSONDecoder().decode(
    NavigationState<AppRoute, AppModalRoute, AppAlertRoute>.self,
    from: data
)

coordinator.restore(from: restored)
```

Legacy v1 snapshots that only stored route arrays still decode. Missing entry IDs are synthesized during restore.

## Universal Links

Universal links are just regular `https` URLs passed through your resolver.

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

`SwiftNavigation` handles URL-to-state reconstruction. Your app still owns the Associated Domains entitlement and the `apple-app-site-association` file.

## Testing

`SwiftNavigation` is designed for direct state assertions with Swift Testing.

```swift
import Testing
@testable import SwiftNavigation

enum TestRoute: NavigationRoute {
    case amount
}

enum TestModalRoute: NavigationRoute {
    case login
}

@Test @MainActor
func popToExactEntry() {
    let coordinator = NavigationCoordinator<TestRoute, TestModalRoute, Never>(
        scope: .feature(name: "test")
    )

    let first = coordinator.push(.amount)
    _ = coordinator.push(.amount)

    coordinator.popToEntry(first)

    #expect(coordinator.stack.count == 1)
}
```

## Sample App

The sample app now includes a dedicated `Showcase` tab with:

- a send-money flow that stores entry bookmarks for exact back navigation
- sheet demos for detents, background styles, and background interaction
- coordinator-driven alerts from root and modal contexts
- login-gated deep links that resume pending destinations after sign-in
- custom-scheme and `https` universal-link parsing through the same resolver pipeline

See [Sample App/README.md](./Sample%20App/README.md) for concrete deep-link commands and the test command used to verify the showcase flow.

## Documentation

- DocC site: [https://erikote04.github.io/SwiftNavigation/documentation/swiftnavigation/](https://erikote04.github.io/SwiftNavigation/documentation/swiftnavigation/)
- See `Quick Start`, `Alerts and Sheets`, `Flow Bookmarks`, `Deep Link Interception`, `Universal Links`, and `Migration Guide` in the DocC catalog
