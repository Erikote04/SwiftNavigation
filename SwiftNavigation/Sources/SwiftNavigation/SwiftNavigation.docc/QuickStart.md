# Quick Start

Set up a coordinator, wrap your root view in `RoutingView`, and map typed routes to destinations.

## Define Routes

```swift
import SwiftNavigation

enum AppRoute: String, NavigationRoute {
    case profile
    case settings
}

enum AppModalRoute: String, NavigationRoute {
    case signIn
    case terms
}
```

## Create Coordinator

```swift
import SwiftNavigation

@MainActor
let coordinator = NavigationCoordinator<AppRoute, AppModalRoute>(
    scope: .application
)
```

## Build Routing View

```swift
import SwiftUI
import SwiftNavigation

struct AppRootView: View {
    @State private var coordinator = NavigationCoordinator<AppRoute, AppModalRoute>(scope: .application)

    var body: some View {
        RoutingView(
            coordinator: coordinator,
            root: {
                HomeView(
                    onOpenProfile: { coordinator.push(.profile) },
                    onOpenSignIn: { coordinator.present(.signIn, style: .sheet) }
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
            }
        )
        .navigationCoordinator(coordinator)
    }
}
```

## Next Steps

- Use <doc:MVVMCoordinator> to keep ViewModels UI-framework agnostic.
- Use <doc:StateRestoration> to persist and restore state snapshots.
- Use <doc:DeepLinking> to reconstruct full navigation flows from external triggers.
