import Foundation
import SwiftNavigation

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

enum AppRoute: NavigationRoute {
    case characterDetail(CharacterRouteData)
    case episodeDetail(EpisodeRouteData)
    case locationDetail(LocationRouteData)
}

enum AppModalRoute: NavigationRoute {
    case characterActions(CharacterRouteData)
    case characterEpisodes(CharacterRouteData)
    case characterEpisodeDetail(EpisodeRouteData)
    case favoritesPlanner(CharacterRouteData)
    case plannerConfirmation(CharacterRouteData)
    case settings
    case about
}
