import Foundation
import Observation

@MainActor
@Observable
final class CharactersListViewModel {
    // MARK: - 2.3 ViewModel del feature: depende de `CharactersRouting`, no de SwiftNavigation directamente

    private let service: RickMortyService
    private weak var router: (any CharactersRouting)?

    private(set) var characters: [CharacterRouteData] = []
    private(set) var isInitialLoading = false
    private(set) var isLoadingNextPage = false
    var errorMessage: String?

    private var nextPage: Int? = 1

    // MARK: - 2.3.1 Inyección del router del feature (implementado por `CharactersCoordinator`)

    init(service: RickMortyService, router: any CharactersRouting) {
        self.service = service
        self.router = router
    }

    func loadInitialIfNeeded() async {
        guard characters.isEmpty, !isInitialLoading else {
            return
        }

        await loadPage(reset: true)
    }

    func refresh() async {
        await loadPage(reset: true)
    }

    func loadMoreIfNeeded(currentID: Int) async {
        guard
            let nextPage,
            !isInitialLoading,
            !isLoadingNextPage,
            currentID == characters.last?.id
        else {
            return
        }

        await loadPage(number: nextPage, reset: false)
    }

    // MARK: - 2.3.2 Acción de UI -> intención de navegación del feature

    func didTapCharacter(_ character: CharacterRouteData) {
        router?.showCharacterDetail(character)
    }

    private func loadPage(reset: Bool) async {
        await loadPage(number: 1, reset: reset)
    }

    private func loadPage(number: Int, reset: Bool) async {
        if reset {
            isInitialLoading = true
        } else {
            isLoadingNextPage = true
        }

        defer {
            if reset {
                isInitialLoading = false
            } else {
                isLoadingNextPage = false
            }
        }

        do {
            let response = try await service.fetchCharacters(page: number)
            let mappedCharacters = response.results.map(\.routeData)

            if reset {
                characters = mappedCharacters
            } else {
                characters.append(contentsOf: mappedCharacters)
            }

            nextPage = await service.nextPage(from: response.info.next)
            errorMessage = nil
        } catch {
            if reset {
                characters = []
            }
            errorMessage = error.localizedDescription
        }
    }
}
