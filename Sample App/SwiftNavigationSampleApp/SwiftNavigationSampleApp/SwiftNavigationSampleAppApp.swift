import SwiftUI

// MARK: - 5. Ciclo de vida de app: arranque SwiftUI y persistencia del estado de navegación

@main
@MainActor
struct SwiftNavigationSampleAppApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(SampleAppNotificationDelegate.self)
    private var notificationDelegate

    // MARK: - 5.1 Crear `AppCoordinator` y montar `AppRootView` como raíz de SwiftNavigation

    @State private var appCoordinator = AppCoordinator()

    // MARK: - 5.2 Conectar `scenePhase` con persistencia de `NavigationState`

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
