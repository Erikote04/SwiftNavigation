import Foundation

nonisolated struct APIPageInfo: Decodable, Sendable {
    let count: Int
    let pages: Int
    let next: String?
    let prev: String?
}

nonisolated struct APIListResponse<Value: Decodable & Sendable>: Decodable, Sendable {
    let info: APIPageInfo
    let results: [Value]
}

nonisolated struct APINamedResource: Decodable, Sendable {
    let name: String
    let url: String
}

nonisolated struct APICharacter: Decodable, Sendable, Identifiable {
    let id: Int
    let name: String
    let status: String
    let species: String
    let type: String
    let gender: String
    let origin: APINamedResource
    let location: APINamedResource
    let image: String
    let episode: [String]
}

nonisolated struct APIEpisode: Decodable, Sendable, Identifiable {
    let id: Int
    let name: String
    let airDate: String
    let code: String
    let characters: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case airDate = "air_date"
        case code = "episode"
        case characters
    }
}

nonisolated struct APILocation: Decodable, Sendable, Identifiable {
    let id: Int
    let name: String
    let type: String
    let dimension: String
    let residents: [String]
}

extension APICharacter {
    var routeData: CharacterRouteData {
        CharacterRouteData(
            id: id,
            name: name,
            status: status,
            species: species,
            imageURL: image,
            episodeIDs: episode.compactMap { extractID(from: $0) }
        )
    }
}

extension APIEpisode {
    var routeData: EpisodeRouteData {
        EpisodeRouteData(id: id, name: name, code: code, airDate: airDate)
    }
}

extension APILocation {
    var routeData: LocationRouteData {
        LocationRouteData(id: id, name: name, type: type, dimension: dimension)
    }
}

nonisolated func extractID(from absoluteURL: String) -> Int? {
    URL(string: absoluteURL)
        .flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        .flatMap { $0.path.split(separator: "/").last }
        .flatMap { Int($0) }
}
