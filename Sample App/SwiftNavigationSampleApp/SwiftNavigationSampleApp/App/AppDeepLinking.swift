import Foundation
import SwiftNavigation

// MARK: - 6. Deep Linking con SwiftNavigation: construir `NavigationState` desde URL/payloads

enum AppDeepLinkPreferredRootTab: String {
    case characters
    case explore
}

// MARK: - 6.1 Tipos de soporte: errores de parsing para feedback en la UI

enum AppDeepLinkError: LocalizedError {
    case unsupportedURLScheme(String?)
    case unsupportedTarget(String)
    case missingIdentifier(String)
    case invalidIdentifier(String)
    case missingNotificationField(String)
    case invalidURLString(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedURLScheme(let scheme):
            return "Unsupported deep link URL scheme: \(scheme ?? "nil")."
        case .unsupportedTarget(let target):
            return "Unsupported deep link target: \(target)."
        case .missingIdentifier(let target):
            return "Missing identifier for deep link target '\(target)'."
        case .invalidIdentifier(let rawValue):
            return "Invalid deep link identifier: \(rawValue)."
        case .missingNotificationField(let field):
            return "Missing notification deep link field: \(field)."
        case .invalidURLString(let rawValue):
            return "Invalid deeplink URL string in notification payload: \(rawValue)."
        }
    }
}

/// URL deeplink examples (URL scheme registration is intentionally not included in this sample):
/// - `swiftnavsample://characters`
/// - `swiftnavsample://characters/1`
/// - `swiftnavsample://characters/1?episode=28`
/// - `swiftnavsample://characters/1?actions=1`
/// - `swiftnavsample://locations/3?about=1`
/// - `swiftnavsample://settings`
// MARK: - 6.2 Resolver de URL: adapta el parser al protocolo `URLDeepLinkResolving`
struct AppURLDeepLinkResolver: URLDeepLinkResolving {
    func navigationState(for url: URL) throws -> NavigationState<AppRoute, AppModalRoute> {
        try AppDeepLinkParser.parseURL(url).navigationState
    }

    static func preferredRootTab(for url: URL) throws -> AppDeepLinkPreferredRootTab? {
        try AppDeepLinkParser.parseURL(url).preferredRootTab
    }
}

/// Notification deeplink payload examples:
/// - `["target": "character", "id": 1]`
/// - `["target": "character", "id": 1, "showActions": true]`
/// - `["target": "location", "id": 3, "showAbout": true]`
/// - `["target": "settings"]`
/// - `["deeplink_url": "swiftnavsample://characters/1?episode=28"]`
// MARK: - 6.3 Resolver de notificaciones: adapta payloads al protocolo `NotificationDeepLinkResolving`
struct AppNotificationDeepLinkResolver: NotificationDeepLinkResolving {
    func navigationState(for userInfo: [AnyHashable: Any]) throws -> NavigationState<AppRoute, AppModalRoute> {
        try AppDeepLinkParser.parseNotification(userInfo).navigationState
    }

    static func preferredRootTab(for userInfo: [AnyHashable: Any]) throws -> AppDeepLinkPreferredRootTab? {
        try AppDeepLinkParser.parseNotification(userInfo).preferredRootTab
    }
}

extension Notification.Name {
    // MARK: - 6.4 Evento interno para conectar UNUserNotificationCenter con SwiftUI/AppCoordinator
    /// Internal bridge notification posted by the sample `UNUserNotificationCenterDelegate`.
    static let sampleAppNotificationDeepLinkReceived =
        Notification.Name("SwiftNavigationSampleApp.notificationDeepLinkReceived")
}

private struct ParsedAppDeepLink {
    let preferredRootTab: AppDeepLinkPreferredRootTab?
    let navigationState: NavigationState<AppRoute, AppModalRoute>
}

// MARK: - 6.5 Parser central: traduce URLs/payloads a `NavigationState<AppRoute, AppModalRoute>`

private enum AppDeepLinkParser {
    static func parseURL(_ url: URL) throws -> ParsedAppDeepLink {
        let allowedSchemes = ["swiftnavsample", "swiftnavigationsample"]
        if let scheme = url.scheme?.lowercased(), !scheme.isEmpty, !allowedSchemes.contains(scheme) {
            throw AppDeepLinkError.unsupportedURLScheme(url.scheme)
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        let segments = normalizedSegments(from: url)

        guard let target = segments.first?.lowercased() else {
            return ParsedAppDeepLink(
                preferredRootTab: .characters,
                navigationState: NavigationState()
            )
        }

        switch target {
        case "characters", "character":
            return try characterDeepLink(
                idSegment: segments.dropFirst().first,
                queryItems: queryItems
            )

        case "episodes", "episode":
            let episodeID = try parseRequiredID(segments.dropFirst().first, target: "episode")
            return ParsedAppDeepLink(
                preferredRootTab: .characters,
                navigationState: NavigationState(stack: [.episodeDetail(makeEpisodeRoute(id: episodeID))])
            )

        case "locations", "location":
            return try locationDeepLink(
                idSegment: segments.dropFirst().first,
                queryItems: queryItems
            )

        case "settings":
            return ParsedAppDeepLink(
                preferredRootTab: .explore,
                navigationState: NavigationState(
                    modalStack: [.init(style: .fullScreen, root: .settings)]
                )
            )

        case "about":
            return ParsedAppDeepLink(
                preferredRootTab: .explore,
                navigationState: NavigationState(
                    modalStack: [.init(style: .sheet, root: .about)]
                )
            )

        default:
            throw AppDeepLinkError.unsupportedTarget(target)
        }
    }

    static func parseNotification(_ userInfo: [AnyHashable: Any]) throws -> ParsedAppDeepLink {
        if let deepLinkURLString = try stringValue(forKey: "deeplink_url", in: userInfo) {
            guard let url = URL(string: deepLinkURLString) else {
                throw AppDeepLinkError.invalidURLString(deepLinkURLString)
            }
            return try parseURL(url)
        }

        guard let target = try stringValue(forKey: "target", in: userInfo) else {
            throw AppDeepLinkError.missingNotificationField("target")
        }

        switch target.lowercased() {
        case "character", "characters":
            guard let id = try intValue(forKey: "id", in: userInfo) else {
                throw AppDeepLinkError.missingIdentifier("character")
            }
            let episodeID = try intValue(forKey: "episodeID", in: userInfo)
            let showActions = boolValue(forKey: "showActions", in: userInfo) ?? false

            var stack: [AppRoute] = [.characterDetail(makeCharacterRoute(id: id))]
            if let episodeID {
                stack.append(.episodeDetail(makeEpisodeRoute(id: episodeID)))
            }

            let modalStack: [ModalPresentation<AppModalRoute>] = showActions
                ? [.init(style: .sheet, root: .characterActions(makeCharacterRoute(id: id)))]
                : []

            return ParsedAppDeepLink(
                preferredRootTab: .characters,
                navigationState: NavigationState(stack: stack, modalStack: modalStack)
            )

        case "episode", "episodes":
            guard let id = try intValue(forKey: "id", in: userInfo) else {
                throw AppDeepLinkError.missingIdentifier("episode")
            }
            return ParsedAppDeepLink(
                preferredRootTab: .characters,
                navigationState: NavigationState(stack: [.episodeDetail(makeEpisodeRoute(id: id))])
            )

        case "location", "locations":
            guard let id = try intValue(forKey: "id", in: userInfo) else {
                throw AppDeepLinkError.missingIdentifier("location")
            }
            let showAbout = boolValue(forKey: "showAbout", in: userInfo) ?? false
            let showSettings = boolValue(forKey: "showSettings", in: userInfo) ?? false

            var modalStack: [ModalPresentation<AppModalRoute>] = []
            if showAbout {
                modalStack.append(.init(style: .sheet, root: .about))
            }
            if showSettings {
                modalStack.append(.init(style: .fullScreen, root: .settings))
            }

            return ParsedAppDeepLink(
                preferredRootTab: .explore,
                navigationState: NavigationState(
                    stack: [.locationDetail(makeLocationRoute(id: id))],
                    modalStack: modalStack
                )
            )

        case "settings":
            return ParsedAppDeepLink(
                preferredRootTab: .explore,
                navigationState: NavigationState(modalStack: [.init(style: .fullScreen, root: .settings)])
            )

        case "about":
            return ParsedAppDeepLink(
                preferredRootTab: .explore,
                navigationState: NavigationState(modalStack: [.init(style: .sheet, root: .about)])
            )

        default:
            throw AppDeepLinkError.unsupportedTarget(target)
        }
    }

    // MARK: - 6.5.1 Builders por target (character/location) para stack + modal stack

    private static func characterDeepLink(
        idSegment: String?,
        queryItems: [URLQueryItem]
    ) throws -> ParsedAppDeepLink {
        guard let idSegment else {
            return ParsedAppDeepLink(preferredRootTab: .characters, navigationState: NavigationState())
        }

        let characterID = try parseRequiredID(idSegment, target: "character")
        let episodeID = intQueryItem(named: "episode", in: queryItems)
        let showActions = boolQueryItem(named: "actions", in: queryItems)
            ?? (stringQueryItem(named: "modal", in: queryItems)?.lowercased() == "actions")

        let episodeIDs = episodeID.map { [$0] } ?? []
        let characterRoute = makeCharacterRoute(id: characterID, episodeIDs: episodeIDs)

        var stack: [AppRoute] = [.characterDetail(characterRoute)]
        if let episodeID {
            stack.append(.episodeDetail(makeEpisodeRoute(id: episodeID)))
        }

        let modalStack: [ModalPresentation<AppModalRoute>] = showActions == true
            ? [.init(style: .sheet, root: .characterActions(characterRoute))]
            : []

        return ParsedAppDeepLink(
            preferredRootTab: .characters,
            navigationState: NavigationState(stack: stack, modalStack: modalStack)
        )
    }

    private static func locationDeepLink(
        idSegment: String?,
        queryItems: [URLQueryItem]
    ) throws -> ParsedAppDeepLink {
        guard let idSegment else {
            return ParsedAppDeepLink(preferredRootTab: .explore, navigationState: NavigationState())
        }

        let locationID = try parseRequiredID(idSegment, target: "location")
        let showAbout = boolQueryItem(named: "about", in: queryItems) ?? false
        let showSettings = boolQueryItem(named: "settings", in: queryItems) ?? false

        var modalStack: [ModalPresentation<AppModalRoute>] = []
        if showAbout {
            modalStack.append(.init(style: .sheet, root: .about))
        }
        if showSettings {
            modalStack.append(.init(style: .fullScreen, root: .settings))
        }

        return ParsedAppDeepLink(
            preferredRootTab: .explore,
            navigationState: NavigationState(
                stack: [.locationDetail(makeLocationRoute(id: locationID))],
                modalStack: modalStack
            )
        )
    }

    // MARK: - 6.5.2 Helpers de parsing y factories de `RouteData`

    private static func normalizedSegments(from url: URL) -> [String] {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let hostSegment = components?.host
        let pathSegments = (components?.path ?? "")
            .split(separator: "/")
            .map(String.init)

        return ([hostSegment].compactMap { $0 } + pathSegments)
            .filter { !$0.isEmpty }
    }

    private static func parseRequiredID(_ rawValue: String?, target: String) throws -> Int {
        guard let rawValue else {
            throw AppDeepLinkError.missingIdentifier(target)
        }

        guard let parsedValue = Int(rawValue) else {
            throw AppDeepLinkError.invalidIdentifier(rawValue)
        }

        return parsedValue
    }

    private static func makeCharacterRoute(id: Int, episodeIDs: [Int] = []) -> CharacterRouteData {
        CharacterRouteData(
            id: id,
            name: "Character #\(id)",
            status: "Unknown",
            species: "Unknown",
            imageURL: "",
            episodeIDs: episodeIDs
        )
    }

    private static func makeEpisodeRoute(id: Int) -> EpisodeRouteData {
        EpisodeRouteData(
            id: id,
            name: "Episode #\(id)",
            code: "Unknown",
            airDate: "Unknown"
        )
    }

    private static func makeLocationRoute(id: Int) -> LocationRouteData {
        LocationRouteData(
            id: id,
            name: "Location #\(id)",
            type: "Unknown",
            dimension: "Unknown"
        )
    }

    private static func stringQueryItem(named name: String, in items: [URLQueryItem]) -> String? {
        items.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame })?.value
    }

    private static func intQueryItem(named name: String, in items: [URLQueryItem]) -> Int? {
        guard let rawValue = stringQueryItem(named: name, in: items) else {
            return nil
        }
        return Int(rawValue)
    }

    private static func boolQueryItem(named name: String, in items: [URLQueryItem]) -> Bool? {
        guard let rawValue = stringQueryItem(named: name, in: items) else {
            return nil
        }
        return parseBool(rawValue)
    }

    private static func stringValue(forKey key: String, in dictionary: [AnyHashable: Any]) throws -> String? {
        guard let value = dictionary[key] else {
            return nil
        }

        if let stringValue = value as? String {
            return stringValue
        }

        if let numberValue = value as? NSNumber {
            return numberValue.stringValue
        }

        throw AppDeepLinkError.missingNotificationField(key)
    }

    private static func intValue(forKey key: String, in dictionary: [AnyHashable: Any]) throws -> Int? {
        guard let value = dictionary[key] else {
            return nil
        }

        if let intValue = value as? Int {
            return intValue
        }

        if let numberValue = value as? NSNumber {
            return numberValue.intValue
        }

        if let stringValue = value as? String {
            guard let parsed = Int(stringValue) else {
                throw AppDeepLinkError.invalidIdentifier(stringValue)
            }
            return parsed
        }

        throw AppDeepLinkError.missingNotificationField(key)
    }

    private static func boolValue(forKey key: String, in dictionary: [AnyHashable: Any]) -> Bool? {
        guard let value = dictionary[key] else {
            return nil
        }

        if let boolValue = value as? Bool {
            return boolValue
        }

        if let numberValue = value as? NSNumber {
            return numberValue.boolValue
        }

        if let stringValue = value as? String {
            return parseBool(stringValue)
        }

        return nil
    }

    private static func parseBool(_ rawValue: String) -> Bool? {
        switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "1", "true", "yes", "y", "on":
            return true
        case "0", "false", "no", "n", "off":
            return false
        default:
            return nil
        }
    }
}
