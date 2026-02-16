# MVVM-C Integration

Use protocol-based routing contracts to keep ViewModels independent from SwiftUI.

## 1. Define a Feature Routing Protocol

```swift
import SwiftNavigation

@MainActor
protocol LoginRouting: AnyObject {
    func showTerms()
    func finishLogin()
}
```

## 2. Implement the Protocol in a Coordinator Adapter

```swift
import SwiftNavigation

@MainActor
final class LoginRouter: LoginRouting {
    private let routing: NavigationRouterProxy<AppRoute, AppModalRoute>

    init(coordinator: NavigationCoordinator<AppRoute, AppModalRoute>) {
        self.routing = NavigationRouterProxy(coordinator: coordinator)
    }

    func showTerms() {
        routing.present(.terms, style: .fullScreen)
    }

    func finishLogin() {
        routing.dismissTopModal()
        routing.push(.profile)
    }
}
```

## 3. Inject the Protocol into the ViewModel

```swift
@Observable
@MainActor
final class LoginViewModel {
    private let router: LoginRouting

    init(router: LoginRouting) {
        self.router = router
    }

    func didTapTerms() {
        router.showTerms()
    }

    func didFinishLogin() {
        router.finishLogin()
    }
}
```

This pattern keeps ViewModels free of direct references to SwiftUI navigation APIs and preserves strict MVVM-C boundaries.
