# Presentation: RoutingView, Sheets, Full Screen Covers, Alerts

## Build One Routing Container

Use a single `RoutingView` at the app root:

```swift
RoutingView(
    coordinator: appCoordinator.navigationCoordinator,
    root: {
        HomeView(viewModel: appCoordinator.homeViewModel)
    },
    stackDestination: { route in
        switch route {
        case .profile(let route):
            ProfileView(route: route, viewModel: appCoordinator.accountViewModel)
        }
    },
    modalDestination: { route in
        switch route {
        case .signIn(let route):
            SignInView(route: route)
        case .settings:
            SettingsView()
        }
    },
    alertDestination: { route in
        switch route {
        case .errorMessage(let message):
            AlertDescriptor(
                title: "Something went wrong",
                message: message,
                actions: [.dismiss("OK")]
            )
        }
    }
)
.navigationCoordinator(appCoordinator.navigationCoordinator)
```

If alerts are not used, configure the coordinator as `NavigationCoordinator<AppRoute, AppModalRoute, Never>` and use the no-alert `RoutingView` initializer.

## Present Sheets

Use `.sheet` plus `SheetPresentationOptions`:

```swift
_ = router.present(
    .signIn(signInRoute),
    style: .sheet,
    sheetPresentation: SheetPresentationOptions(
        detents: [.medium, .large],
        background: .regularMaterial,
        backgroundInteraction: .enabledThrough(.medium),
        interactiveDismissDisabled: true
    )
)
```

Use sheet options when you need:

- `presentationDetents`
- `presentationBackground`
- `presentationBackgroundInteraction`
- `interactiveDismissDisabled`

## Present Full Screen Covers

Use `.fullScreen` when the presented flow should feel separate from the underlying UI:

```swift
_ = router.present(.settings, style: .fullScreen)
```

Prefer this for onboarding, locked flows, or experiences that should not visually stack like a sheet.

## Present Alerts

Keep alert state in the coordinator, not in feature views:

```swift
_ = router.presentAlert(.errorMessage("The request failed."))
```

Map alert routes into `AlertDescriptor`:

```swift
AlertDescriptor(
    title: "Discard draft?",
    message: "Your edits will be lost.",
    actions: [
        AlertAction(title: "Discard", role: .destructive),
        .dismiss("Keep Editing", role: .cancel)
    ]
)
```

## Keep Views Thin

- Let views render route data and forward user intent to the view model.
- Let the coordinator decide whether that intent becomes a push, a sheet, a full screen cover, or an alert.
- Do not reintroduce `.sheet(isPresented:)`, `.alert(isPresented:)`, or view-local navigation booleans for flows already owned by SwiftNavigation.
