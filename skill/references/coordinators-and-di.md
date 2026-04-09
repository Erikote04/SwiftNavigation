# Coordinators and Dependency Injection

## Root Composition Pattern

Create the app coordinator at the composition root and keep dependency construction there.

```swift
@MainActor
@Observable
final class AppCoordinator {
    let navigationCoordinator: NavigationCoordinator<AppRoute, AppModalRoute, AppAlertRoute>
    let homeCoordinator: HomeCoordinator
    let accountCoordinator: AccountCoordinator

    let homeViewModel: HomeViewModel
    let accountViewModel: AccountViewModel

    init() {
        let navigationCoordinator = NavigationCoordinator<AppRoute, AppModalRoute, AppAlertRoute>(
            scope: .application
        )
        let router = NavigationRouterProxy(coordinator: navigationCoordinator)

        let apiClient = APIClient()
        let sessionStore = SessionStore()

        let homeCoordinator = HomeCoordinator(router: router)
        let accountCoordinator = AccountCoordinator(router: router)

        self.navigationCoordinator = navigationCoordinator
        self.homeCoordinator = homeCoordinator
        self.accountCoordinator = accountCoordinator
        self.homeViewModel = HomeViewModel(apiClient: apiClient, router: homeCoordinator)
        self.accountViewModel = AccountViewModel(sessionStore: sessionStore, router: accountCoordinator)

        navigationCoordinator.attachChild(homeCoordinator)
        navigationCoordinator.attachChild(accountCoordinator)
    }
}
```

## Feature Routing Pattern

Define a focused routing protocol per feature:

```swift
@MainActor
protocol AccountRouting: AnyObject {
    func showProfile(_ route: ProfileRouteData) -> NavigationEntryID
    func showSignIn(_ route: SignInRouteData)
    func showError(_ message: String)
}
```

Implement it in a feature coordinator:

```swift
@MainActor
final class AccountCoordinator: CoordinatorLifecycle, AccountRouting {
    let coordinatorID = UUID()
    private let router: NavigationRouterProxy<AppRoute, AppModalRoute, AppAlertRoute>

    init(router: NavigationRouterProxy<AppRoute, AppModalRoute, AppAlertRoute>) {
        self.router = router
    }

    var isFlowFinished: Bool {
        false
    }

    func showProfile(_ route: ProfileRouteData) -> NavigationEntryID {
        router.push(.profile(route))
    }

    func showSignIn(_ route: SignInRouteData) {
        _ = router.present(.signIn(route), style: .sheet)
    }

    func showError(_ message: String) {
        _ = router.presentAlert(.errorMessage(message))
    }
}
```

## View-Model Injection Pattern

Inject routing protocols, not concrete app coordinators:

```swift
@MainActor
@Observable
final class AccountViewModel {
    private let router: any AccountRouting

    init(router: any AccountRouting) {
        self.router = router
    }
}
```

## Prefer Explicit Dependencies

- Inject repositories, services, clocks, and session stores through initializers.
- Keep `UserDefaults` or persistence adapters at the app/root level unless a feature owns its own persistence boundary.
- Avoid hidden globals or singletons when a dependency can be passed explicitly.

## Use Child Coordinators for Reusable Flow Logic

Create a child coordinator when:

- multiple views in a feature share route-building logic
- a feature owns reusable sheet or alert presentation rules
- a flow needs exact bookmarks or backtracking logic
- a view model would otherwise collect too much navigation orchestration

Keep child coordinators thin. They should adapt domain/user intent to `NavigationRouterProxy`, not absorb unrelated business logic.
