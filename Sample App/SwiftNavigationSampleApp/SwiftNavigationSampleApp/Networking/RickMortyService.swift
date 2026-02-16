import Foundation
import SwiftNetwork

actor RickMortyService {
    private let client: NetworkClient
    private let baseURL = "https://rickandmortyapi.com/api"

    init(client: NetworkClient = NetworkClient()) {
        self.client = client
    }

    func fetchCharacters(page: Int) async throws -> APIListResponse<APICharacter> {
        try await client.get("\(baseURL)/character?page=\(page)", cachePolicy: .ignoreCache)
    }

    func fetchCharacter(id: Int) async throws -> APICharacter {
        try await client.get("\(baseURL)/character/\(id)", cachePolicy: .ignoreCache)
    }

    func fetchEpisode(id: Int) async throws -> APIEpisode {
        try await client.get("\(baseURL)/episode/\(id)", cachePolicy: .ignoreCache)
    }

    func fetchEpisodes(ids: [Int]) async throws -> [APIEpisode] {
        guard !ids.isEmpty else {
            return []
        }

        if ids.count == 1, let singleID = ids.first {
            return [try await fetchEpisode(id: singleID)]
        }

        let joinedIDs = ids.map(String.init).joined(separator: ",")
        let episodes: [APIEpisode] = try await client.get("\(baseURL)/episode/\(joinedIDs)", cachePolicy: .ignoreCache)

        let order = Dictionary(uniqueKeysWithValues: ids.enumerated().map { ($1, $0) })
        return episodes.sorted { (order[$0.id] ?? .max) < (order[$1.id] ?? .max) }
    }

    func fetchLocations(page: Int) async throws -> APIListResponse<APILocation> {
        try await client.get("\(baseURL)/location?page=\(page)", cachePolicy: .ignoreCache)
    }

    func fetchLocation(id: Int) async throws -> APILocation {
        try await client.get("\(baseURL)/location/\(id)", cachePolicy: .ignoreCache)
    }

    func nextPage(from urlString: String?) -> Int? {
        guard
            let urlString,
            let components = URLComponents(string: urlString),
            let pageValue = components.queryItems?.first(where: { $0.name == "page" })?.value,
            let page = Int(pageValue)
        else {
            return nil
        }

        return page
    }
}
