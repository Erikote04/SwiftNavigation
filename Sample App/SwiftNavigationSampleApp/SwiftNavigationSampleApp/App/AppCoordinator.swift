import Foundation
import Observation
import SwiftNavigation

// MARK: - 3. Composición de la app: integrar SwiftNavigation a nivel raíz

@available(iOS 17, *)
@MainActor
@Observable
final class AppCoordinator {
    private static let navigationStateStorageKey = "swiftNavigationSample.navigationState.v1"
    private static let selectedRootTabStorageKey = "swiftNavigationSample.selectedRootTab"

    let navigationCoordinator: NavigationCoordinator<AppRoute, AppModalRoute>
    let service: RickMortyService

    let charactersCoordinator: CharactersCoordinator
    let exploreCoordinator: LocationsCoordinator

    let charactersViewModel: CharactersListViewModel
    let locationsViewModel: LocationsListViewModel
    var deepLinkErrorMessage: String?

    // MARK: - 3.1 Crear el `NavigationCoordinator` global y un `NavigationRouterProxy` compartido

    init() {
        let navigationCoordinator = NavigationCoordinator<AppRoute, AppModalRoute>(scope: .application)
        let sharedRouter = NavigationRouterProxy(coordinator: navigationCoordinator)

        // MARK: - 3.2 Crear coordinadores de feature reutilizando el mismo router

        let charactersCoordinator = CharactersCoordinator(router: sharedRouter)
        let exploreCoordinator = LocationsCoordinator(router: sharedRouter)

        let service = RickMortyService()

        self.navigationCoordinator = navigationCoordinator
        self.charactersCoordinator = charactersCoordinator
        self.exploreCoordinator = exploreCoordinator
        self.service = service

        // MARK: - 3.3 Inyectar coordinadores en ViewModels (la UI navega vía protocolos)

        self.charactersViewModel = CharactersListViewModel(service: service, router: charactersCoordinator)
        self.locationsViewModel = LocationsListViewModel(service: service, router: exploreCoordinator)

        // MARK: - 3.4 Registrar child coordinators para ciclo de vida/arquitectura de SwiftNavigation

        navigationCoordinator.attachChild(charactersCoordinator)
        navigationCoordinator.attachChild(exploreCoordinator)

        // MARK: - 3.5 Restaurar estado de navegación persistido (stack + modales)

        restorePersistedNavigationStateIfAvailable()
    }

    // MARK: - 3.6 Persistencia de navegación: exportar `NavigationState` antes de salir

    func persistNavigationState() {
        do {
            let snapshot = navigationCoordinator.exportState()
            let data = try JSONEncoder().encode(snapshot)
            UserDefaults.standard.set(data, forKey: Self.navigationStateStorageKey)
        } catch {
            assertionFailure("Failed to encode navigation state: \(error)")
        }
    }

    // MARK: - 3.7 Deep links URL: resolver y aplicar estado a `NavigationCoordinator`

    func handleDeepLinkURL(_ url: URL) {
        let resolver = AppURLDeepLinkResolver()

        do {
            let preferredRootTab = try AppURLDeepLinkResolver.preferredRootTab(for: url)
            try navigationCoordinator.applyURLDeepLink(url, resolver: resolver)
            applyPreferredRootTab(preferredRootTab)
            deepLinkErrorMessage = nil
        } catch {
            deepLinkErrorMessage = error.localizedDescription
        }
    }

    // MARK: - 3.8 Deep links de notificación: mismo flujo usando resolver de payloads

    func handleNotificationDeepLink(userInfo: [AnyHashable: Any]) {
        let resolver = AppNotificationDeepLinkResolver()

        do {
            let preferredRootTab = try AppNotificationDeepLinkResolver.preferredRootTab(for: userInfo)
            try navigationCoordinator.applyNotificationDeepLink(userInfo: userInfo, resolver: resolver)
            applyPreferredRootTab(preferredRootTab)
            deepLinkErrorMessage = nil
        } catch {
            deepLinkErrorMessage = error.localizedDescription
        }
    }

    // MARK: - 3.9 Helpers privados (tab preferida + restore del estado)

    private func applyPreferredRootTab(_ preferredRootTab: AppDeepLinkPreferredRootTab?) {
        guard let preferredRootTab else {
            return
        }

        UserDefaults.standard.set(
            preferredRootTab.rawValue,
            forKey: Self.selectedRootTabStorageKey
        )
    }

    private func restorePersistedNavigationStateIfAvailable() {
        guard let data = UserDefaults.standard.data(forKey: Self.navigationStateStorageKey) else {
            return
        }

        do {
            let snapshot = try JSONDecoder().decode(
                NavigationState<AppRoute, AppModalRoute>.self,
                from: data
            )
            navigationCoordinator.restore(from: snapshot)
        } catch {
            UserDefaults.standard.removeObject(forKey: Self.navigationStateStorageKey)
            assertionFailure("Failed to restore navigation state: \(error)")
        }
    }
}
