import Foundation
import SwiftNavigation

// MARK: - 1. Definir contratos de navegación compartidos (tipos que viajarán por SwiftNavigation)

// MARK: - 1.1 Payloads de ruta: datos mínimos que la navegación necesita para abrir pantallas

struct CharacterRouteData: NavigationRoute, Identifiable {
    let id: Int
    let name: String
    let status: String
    let species: String
    let imageURL: String
    let episodeIDs: [Int]
}

struct EpisodeRouteData: NavigationRoute, Identifiable {
    let id: Int
    let name: String
    let code: String
    let airDate: String
}

struct LocationRouteData: NavigationRoute, Identifiable {
    let id: Int
    let name: String
    let type: String
    let dimension: String
}

// MARK: - 1.2 Rutas de stack (push) de toda la app

enum AppRoute: NavigationRoute {
    case characterDetail(CharacterRouteData)
    case episodeDetail(EpisodeRouteData)
    case locationDetail(LocationRouteData)
}

// MARK: - 1.3 Rutas modales (sheet/fullScreen) de toda la app

enum AppModalRoute: NavigationRoute {
    case characterActions(CharacterRouteData)
    case characterEpisodes(CharacterRouteData)
    case characterEpisodeDetail(EpisodeRouteData)
    case favoritesPlanner(CharacterRouteData)
    case plannerConfirmation(CharacterRouteData)
    case settings
    case about
}
