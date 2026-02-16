import SwiftUI

@main
@MainActor
struct SwiftNavigationSampleAppApp: App {
    @State private var appCoordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            AppRootView(appCoordinator: appCoordinator)
        }
    }
}
