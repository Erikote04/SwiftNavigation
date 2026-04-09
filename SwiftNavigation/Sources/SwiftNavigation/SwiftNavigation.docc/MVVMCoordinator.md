# MVVM-C Integration

Use protocol-based routing contracts to keep ViewModels independent from SwiftUI.

## 1. Define a Feature Routing Protocol

```swift
import SwiftNavigation

@MainActor
protocol PaymentRouting: AnyObject {
    func showTerms()
    func showReview() -> NavigationEntryID
    func showError(_ message: String)
}
```

## 2. Implement the Protocol in a Coordinator Adapter

```swift
import SwiftNavigation

@MainActor
final class PaymentRouter: PaymentRouting {
    private let routing: NavigationRouterProxy<AppRoute, AppModalRoute, AppAlertRoute>

    init(coordinator: NavigationCoordinator<AppRoute, AppModalRoute, AppAlertRoute>) {
        self.routing = NavigationRouterProxy(coordinator: coordinator)
    }

    func showTerms() {
        routing.present(.terms, style: .fullScreen)
    }

    func showReview() -> NavigationEntryID {
        routing.push(.profile)
    }

    func showError(_ message: String) {
        routing.presentAlert(.sessionExpired)
    }
}
```

## 3. Inject the Protocol into the ViewModel

```swift
@Observable
@MainActor
final class PaymentViewModel {
    private let router: PaymentRouting
    private var reviewEntryID: NavigationEntryID?

    init(router: PaymentRouting) {
        self.router = router
    }

    func didTapTerms() {
        router.showTerms()
    }

    func didTapContinue() {
        reviewEntryID = router.showReview()
    }

    func didFailPayment() {
        router.showError("The bank declined the payment.")
    }
}
```

This pattern keeps ViewModels free of direct references to SwiftUI navigation APIs and preserves strict MVVM-C boundaries.

When a feature needs exact back navigation, store the returned `NavigationEntryID` inside the ViewModel or feature coordinator and call `popToEntry(_:)` later through your routing abstraction.
