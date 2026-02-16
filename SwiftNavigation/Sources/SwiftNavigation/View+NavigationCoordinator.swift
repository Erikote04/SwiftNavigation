import SwiftUI

@available(iOS 17, macOS 14, *)
public extension View {
    /// Injects a coordinator into the SwiftUI environment.
    func navigationCoordinator<StackRoute: NavigationRoute, ModalRoute: NavigationRoute>(
        _ coordinator: NavigationCoordinator<StackRoute, ModalRoute>
    ) -> some View {
        environment(coordinator)
    }
}
