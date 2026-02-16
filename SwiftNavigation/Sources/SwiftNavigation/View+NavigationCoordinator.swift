import SwiftUI

@available(iOS 17, macOS 14, *)
public extension View {
    /// Injects a coordinator into the SwiftUI environment.
    ///
    /// - Parameter coordinator: Coordinator instance to expose through environment lookup.
    /// - Returns: A view that provides the coordinator to its descendant hierarchy.
    func navigationCoordinator<StackRoute: NavigationRoute, ModalRoute: NavigationRoute>(
        _ coordinator: NavigationCoordinator<StackRoute, ModalRoute>
    ) -> some View {
        environment(coordinator)
    }
}
