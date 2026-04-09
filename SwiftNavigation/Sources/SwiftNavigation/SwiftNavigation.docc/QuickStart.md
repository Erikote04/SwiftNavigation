# Quick Start

Set up a coordinator, wrap your root view in `RoutingView`, and map typed routes to stack, modal, and alert destinations.

## Define Routes

```swift
import SwiftNavigation

enum AppRoute: NavigationRoute {
    case profile
    case settings
}

enum AppModalRoute: NavigationRoute {
    case signIn
    case terms
}

enum AppAlertRoute: NavigationRoute {
    case sessionExpired
}
```

## Create Coordinator

```swift
import SwiftNavigation

let coordinator = NavigationCoordinator<AppRoute, AppModalRoute, AppAlertRoute>(
    scope: .application
)
```

If you do not use global alerts, use `Never` and the no-alert `RoutingView` initializer:

```swift
let coordinator = NavigationCoordinator<AppRoute, AppModalRoute, Never>(
    scope: .application
)
```

## Build Routing View

```swift
import SwiftUI
import SwiftNavigation

struct AppRootView: View {
    @State private var coordinator = NavigationCoordinator<AppRoute, AppModalRoute, AppAlertRoute>(
        scope: .application
    )

    var body: some View {
        RoutingView(
            coordinator: coordinator,
            root: {
                HomeView(
                    onOpenProfile: { _ = coordinator.push(.profile) },
                    onOpenSignIn: {
                        _ = coordinator.present(
                            .signIn,
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
                case .profile:
                    ProfileView()
                case .settings:
                    SettingsView()
                }
            },
            modalDestination: { modalRoute in
                switch modalRoute {
                case .signIn:
                    SignInView()
                case .terms:
                    TermsView()
                }
            },
            alertDestination: { alertRoute in
                switch alertRoute {
                case .sessionExpired:
                    AlertDescriptor(
                        title: "Session expired",
                        message: "Please sign in again to continue.",
                        actions: [.dismiss("OK")]
                    )
                }
            }
        )
        .navigationCoordinator(coordinator)
    }
}
```

## Next Steps

- Use <doc:MVVMCoordinator> to keep ViewModels UI-framework agnostic.
- Use <doc:AlertsAndSheets> to present alerts and customize sheets from the coordinator.
- Use <doc:FlowBookmarks> to jump back to exact destinations when a flow repeats the same route.
- Use <doc:StateRestoration> to persist and restore state snapshots.
- Use <doc:DeepLinking>, <doc:DeepLinkInterception>, and <doc:UniversalLinks> to reconstruct full navigation flows from external triggers.
