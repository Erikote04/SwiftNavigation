import SwiftUI

@main
@MainActor
struct SwiftNavigationSampleAppApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var appCoordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            AppRootView(appCoordinator: appCoordinator)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .inactive || newPhase == .background else {
                return
            }

            appCoordinator.persistNavigationState()
        }
    }
}
