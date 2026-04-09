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

enum SendMoneyAmountEditorKind: String, Codable, Hashable, Sendable {
    case primary
    case duplicate

    var title: String {
        switch self {
        case .primary:
            "Primary amount"
        case .duplicate:
            "Duplicate amount"
        }
    }
}

struct SendMoneyRecipientRouteData: NavigationRoute {
    let flowID: UUID
    var selectedRecipient: String
    let availableRecipients: [String]
}

struct SendMoneyAmountRouteData: NavigationRoute {
    let flowID: UUID
    let selectedRecipient: String
    var amount: Double
    let recipientEntryID: NavigationEntryID?
    let editorKind: SendMoneyAmountEditorKind
}

struct SendMoneyReviewRouteData: NavigationRoute {
    let flowID: UUID
    let selectedRecipient: String
    let primaryAmount: Double
    let duplicateAmount: Double
    let recipientEntryID: NavigationEntryID
    let primaryAmountEntryID: NavigationEntryID
    let duplicateAmountEntryID: NavigationEntryID
}

struct ProtectedReceiptRouteData: NavigationRoute {
    let flowID: UUID
    let selectedRecipient: String
    let amount: Double
    let reference: String
}

struct ProtectedProfileRouteData: NavigationRoute {
    let profileID: UUID
    let displayName: String
    let subtitle: String
}

struct LoginRouteData: NavigationRoute {
    let title: String
    let message: String
    let source: String
    let isDismissDisabled: Bool
}

enum SheetShowcaseVariant: String, Codable, Hashable, Sendable {
    case material
    case clear
}

struct SheetShowcaseRouteData: NavigationRoute {
    let title: String
    let subtitle: String
    let details: String
    let variant: SheetShowcaseVariant
    let systemImage: String
}

enum AppRoute: NavigationRoute {
    case characterDetail(CharacterRouteData)
    case episodeDetail(EpisodeRouteData)
    case locationDetail(LocationRouteData)
    case sendMoneyRecipient(SendMoneyRecipientRouteData)
    case sendMoneyAmount(SendMoneyAmountRouteData)
    case sendMoneyReview(SendMoneyReviewRouteData)
    case protectedReceipt(ProtectedReceiptRouteData)
    case protectedProfile(ProtectedProfileRouteData)
}

enum AppModalRoute: NavigationRoute {
    case characterActions(CharacterRouteData)
    case characterEpisodes(CharacterRouteData)
    case characterEpisodeDetail(EpisodeRouteData)
    case favoritesPlanner(CharacterRouteData)
    case plannerConfirmation(CharacterRouteData)
    case settings
    case about
    case login(LoginRouteData)
    case sheetShowcase(SheetShowcaseRouteData)
    case alertShowcase
}

enum AppAlertRoute: NavigationRoute {
    case deepLinkError(String)
    case showcaseError(String)
    case discardDraft(UUID)
}
