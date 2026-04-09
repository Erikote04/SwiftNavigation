# Migration Guide

SwiftNavigation v2 keeps the coordinator mental model from v1, but expands the navigation surface in a few important ways.

## 1. Add the Alert Route Generic

v1:

```swift
NavigationCoordinator<AppRoute, AppModalRoute>
```

v2:

```swift
NavigationCoordinator<AppRoute, AppModalRoute, AppAlertRoute>
```

If you do not use global alerts, use `Never`:

```swift
NavigationCoordinator<AppRoute, AppModalRoute, Never>
```

## 2. Update `RoutingView`

Apps with alerts now provide `alertDestination`.

```swift
RoutingView(
    coordinator: coordinator,
    root: { RootView() },
    stackDestination: { route in ... },
    modalDestination: { route in ... },
    alertDestination: { route in ... }
)
```

Apps using `Never` can use the no-alert initializer instead.

## 3. Expect Entry IDs From Navigation Calls

`push(_:)` and `present(_:)` now return identifiers:

```swift
let reviewEntryID = coordinator.push(.review)
let loginModalID = coordinator.present(.login, style: .sheet)
```

You can ignore the return value when you do not need bookmarks, but flows that revisit the same route should store it.

## 4. Prefer Entry Bookmarks Over Route Matching

v1 often relied on `popToRoute(where:)`.

v2 still keeps that API, but `popToEntry(_:)` is the safer choice when the same route can appear multiple times:

```swift
coordinator.popToEntry(savedEntryID)
```

The same applies to modal-internal navigation with `popModalToEntry(_:at:)`.

## 5. Move Alerts Into Navigation

Instead of keeping raw SwiftUI alert state in views, present alerts through the coordinator:

```swift
coordinator.presentAlert(.error("The request failed."))
```

Then map the alert route into an `AlertDescriptor` inside `RoutingView`.

## 6. Adopt Sheet Presentation Options

v2 lets you attach sheet-specific configuration when presenting modals:

```swift
_ = coordinator.present(
    .login,
    style: .sheet,
    sheetPresentation: SheetPresentationOptions(
        detents: [.medium, .large],
        interactiveDismissDisabled: true
    )
)
```

## 7. Use Async Interception For Login Gates

Deep-link APIs now have async overloads that accept an interceptor:

```swift
try await coordinator.applyURLDeepLink(url, resolver: resolver, interceptor: interceptor)
```

Use this to redirect unauthenticated users to login and later call `resumePendingNavigation()`.

## 8. Restore Legacy Snapshots Safely

`NavigationState` and `ModalPresentation` still decode older route-only payloads. Missing entry IDs are synthesized automatically, so existing persisted snapshots do not need a one-off migration.
