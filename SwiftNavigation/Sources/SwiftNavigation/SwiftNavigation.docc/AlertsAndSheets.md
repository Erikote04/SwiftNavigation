# Alerts and Sheets

SwiftNavigation v2 lets the coordinator own both global alerts and sheet presentation details.

## Typed Alerts

Define an alert route alongside your stack and modal routes:

```swift
enum AppAlertRoute: NavigationRoute {
    case error(message: String)
    case discardDraft
}
```

Present alerts from a coordinator, router proxy, or feature router:

```swift
coordinator.presentAlert(.error(message: "The payment failed."))
```

Map alert routes into library-owned `AlertDescriptor` values inside `RoutingView`:

```swift
alertDestination: { route in
    switch route {
    case .error(let message):
        AlertDescriptor(
            title: "Something went wrong",
            message: message,
            actions: [.dismiss("OK")]
        )

    case .discardDraft:
        AlertDescriptor(
            title: "Discard draft?",
            message: "Your pending changes will be lost.",
            actions: [
                AlertAction(title: "Keep editing", role: .cancel),
                AlertAction(title: "Discard", role: .destructive)
            ]
        )
    }
}
```

This keeps raw SwiftUI alert state out of views and centralizes alert presentation inside navigation.

## No-Alert Apps

If your app does not use coordinator-driven alerts, use `Never` for `AlertRoute`:

```swift
let coordinator = NavigationCoordinator<AppRoute, AppModalRoute, Never>(
    scope: .application
)
```

`RoutingView` has a dedicated initializer for `AlertRoute == Never`, so you do not need to provide an `alertDestination`.

## Sheet Presentation Options

Sheets can now carry presentation settings directly in navigation state:

```swift
_ = coordinator.present(
    .login,
    style: .sheet,
    sheetPresentation: SheetPresentationOptions(
        detents: [.medium, .large],
        background: .regularMaterial,
        backgroundInteraction: .enabledThrough(.medium),
        interactiveDismissDisabled: true
    )
)
```

Available options:

- `SheetDetent`: `.medium`, `.large`, `.fraction(Double)`, `.height(Double)`
- `SheetBackgroundStyle`: `.clear`, `.ultraThinMaterial`, `.thinMaterial`, `.regularMaterial`, `.thickMaterial`
- `SheetBackgroundInteraction`: `.automatic`, `.disabled`, `.enabled`, `.enabledThrough(...)`
- `interactiveDismissDisabled`: disables swipe-to-dismiss when set to `true`

`RoutingView` applies these settings automatically when the modal style is `.sheet`.
