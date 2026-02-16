# SwiftNavigation

Type-safe, coordinator-driven navigation for SwiftUI apps using only native APIs (`NavigationStack`, `.sheet`, `.fullScreenCover`).

[![Swift](https://img.shields.io/badge/Swift-6.1-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue.svg)](https://developer.apple.com/ios/)
[![DocC Deploy](https://github.com/Erikote04/SwiftNavigation/actions/workflows/publish-docc.yml/badge.svg)](https://github.com/Erikote04/SwiftNavigation/actions/workflows/publish-docc.yml)
[![Documentation](https://img.shields.io/badge/Documentation-GitHub%20Pages-2ea44f)](https://erikote04.github.io/SwiftNavigation/documentation/swiftnavigation/)

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [MVVM-C Decoupling](#mvvm-c-decoupling)
- [State Restoration](#state-restoration)
- [Deep Linking](#deep-linking)
- [Testing](#testing)
- [Documentation](#documentation)

## Overview

`SwiftNavigation` provides a modular MVVM-C navigation layer with:

- Pure SwiftUI navigation and presentation APIs.
- `@Observable` + `@MainActor` coordinator state.
- Type-safe stack operations over plain route arrays.
- Nested modal flows with independent internal stacks.
- Codable snapshots for restoration and deep-link reconstruction.

## Key Features

- Type-safe root stack (`[Route]`) with `push`, `pop`, `popToRoot`, and `popToView`.
- Recursive modal navigation (`sheet` + `fullScreenCover`) with internal stack state per modal.
- Automatic state sync when users dismiss modals via native gestures.
- Scoped coordinators (`application`, `feature`, `tab`) and child lifecycle cleanup.
- Protocol-based routing contracts to decouple ViewModels from SwiftUI.
- Swift Testing-friendly architecture for deterministic navigation tests.

## Requirements

- iOS 17+
- Swift 6.1+
- Xcode 16+

## Installation

### Xcode

In Xcode:

1. `File` -> `Add Packages...`
2. Enter: `https://github.com/Erikote04/SwiftNavigation`
3. Select `Up to Next Major Version` and set it to `1.0.0`
4. Add the `SwiftNavigation` product to your target

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/Erikote04/SwiftNavigation", from: "1.0.0")
]
```

## Quick Start

### 1. Define Routes

```swift
import SwiftNavigation

enum AppRoute: String, NavigationRoute {
    case home
    case detail
    case settings
}

enum AppModalRoute: String, NavigationRoute {
    case login
    case terms
}
```

### 2. Create a Coordinator

```swift
import SwiftNavigation

@MainActor
let coordinator = NavigationCoordinator<AppRoute, AppModalRoute>(scope: .application)
```

### 3. Build the Routing Container

```swift
import SwiftUI
import SwiftNavigation

@MainActor
struct AppRootView: View {
    @State private var coordinator = NavigationCoordinator<AppRoute, AppModalRoute>(scope: .application)

    var body: some View {
        RoutingView(
            coordinator: coordinator,
            root: {
                HomeView(
                    onOpenDetail: { coordinator.push(.detail) },
                    onOpenLogin: { coordinator.present(.login, style: .sheet) }
                )
            },
            destination: { route in
                switch route {
                case .home:
                    HomeView(onOpenDetail: {}, onOpenLogin: {})
                case .detail:
                    DetailView()
                case .settings:
                    SettingsView()
                }
            },
            modalDestination: { route in
                switch route {
                case .login:
                    LoginView()
                case .terms:
                    TermsView()
                }
            }
        )
        .navigationCoordinator(coordinator)
    }
}
```

## MVVM-C Decoupling

Create a feature-focused routing protocol and inject it into your ViewModel.

```swift
import SwiftNavigation

@MainActor
protocol AuthRouting: AnyObject {
    func showTerms()
    func finishLogin()
}

@MainActor
final class AuthRouter: AuthRouting {
    private let router: NavigationRouterProxy<AppRoute, AppModalRoute>

    init(coordinator: NavigationCoordinator<AppRoute, AppModalRoute>) {
        self.router = NavigationRouterProxy(coordinator: coordinator)
    }

    func showTerms() {
        router.present(.terms, style: .fullScreen)
    }

    func finishLogin() {
        router.dismissTopModal()
        router.push(.home)
    }
}
```

## State Restoration

```swift
let snapshot = coordinator.exportState()
let data = try JSONEncoder().encode(snapshot)

let restored = try JSONDecoder().decode(
    NavigationState<AppRoute, AppModalRoute>.self,
    from: data
)

coordinator.restore(from: restored)
```

## Deep Linking

```swift
import Foundation
import SwiftNavigation

struct URLResolver: URLDeeplinkResolving {
    func navigationState(for url: URL) throws -> NavigationState<AppRoute, AppModalRoute> {
        if url.host == "settings" {
            return NavigationState(stack: [.home, .settings])
        }
        return NavigationState(stack: [.home])
    }
}

try coordinator.applyURLDeeplink(URL(string: "myapp://settings")!, resolver: URLResolver())
```

## Testing

The coordinator is designed for direct state assertions with Swift Testing.

```swift
import Testing
@testable import SwiftNavigation

@Test @MainActor
func pushAndPop() {
    let coordinator = NavigationCoordinator<AppRoute, AppModalRoute>(scope: .feature("test"))

    coordinator.push(.home)
    coordinator.push(.detail)
    #expect(coordinator.stack == [.home, .detail])

    _ = coordinator.pop()
    #expect(coordinator.stack == [.home])
}
```

## Documentation

- DocC site: [https://erikote04.github.io/SwiftNavigation/documentation/swiftnavigation/](https://erikote04.github.io/SwiftNavigation/documentation/swiftnavigation/)
- CI workflow: [publish-docc.yml](https://github.com/Erikote04/SwiftNavigation/actions/workflows/publish-docc.yml)
