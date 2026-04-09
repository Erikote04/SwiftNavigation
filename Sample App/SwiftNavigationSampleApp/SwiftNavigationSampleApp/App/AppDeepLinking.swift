import Foundation
import SwiftNavigation

enum AppDeepLinkPreferredRootTab: String {
    case characters
    case explore
    case showcase
}

enum AppDeepLinkError: LocalizedError {
    case unsupportedURLScheme(String?)
    case unsupportedTarget(String)
    case missingIdentifier(String)
    case invalidIdentifier(String)
    case missingNotificationField(String)
    case invalidURLString(String)
    case invalidNumericValue(field: String, rawValue: String)

    var errorDescription: String? {
        switch self {
        case .unsupportedURLScheme(let scheme):
            "Unsupported deep link URL scheme: \(scheme ?? "nil")."
        case .unsupportedTarget(let target):
            "Unsupported deep link target: \(target)."
        case .missingIdentifier(let target):
            "Missing identifier for deep link target '\(target)'."
        case .invalidIdentifier(let rawValue):
            "Invalid deep link identifier: \(rawValue)."
        case .missingNotificationField(let field):
            "Missing notification deep link field: \(field)."
        case .invalidURLString(let rawValue):
            "Invalid deeplink URL string in notification payload: \(rawValue)."
        case .invalidNumericValue(let field, let rawValue):
            "Invalid numeric value for \(field): \(rawValue)."
        }
    }
}

/// URL deeplink examples:
/// - `swiftnavsample://characters`
/// - `swiftnavsample://characters/1?episode=28`
/// - `swiftnavsample://locations/3?about=1`
/// - `swiftnavsample://showcase/send-money`
/// - `swiftnavsample://showcase/profile`
/// - `https://demo.swiftnavigation.app/showcase/receipt?recipient=Sonia&amount=35`
struct AppURLDeepLinkResolver: URLDeepLinkResolving {
    func navigationState(for url: URL) throws -> NavigationState<AppRoute, AppModalRoute, Never> {
        try AppDeepLinkParser.parseURL(url).navigationState
    }

    static func preferredRootTab(for url: URL) throws -> AppDeepLinkPreferredRootTab? {
        try AppDeepLinkParser.parseURL(url).preferredRootTab
    }
}

/// Notification deeplink payload examples:
/// - `["target": "character", "id": 1]`
/// - `["target": "location", "id": 3, "showAbout": true]`
/// - `["target": "send-money", "recipient": "Sonia"]`
/// - `["target": "profile", "displayName": "Sonia"]`
/// - `["deeplink_url": "https://demo.swiftnavigation.app/showcase/profile"]`
struct AppNotificationDeepLinkResolver: NotificationDeepLinkResolving {
    func navigationState(for userInfo: [AnyHashable: Any]) throws -> NavigationState<AppRoute, AppModalRoute, Never> {
        try AppDeepLinkParser.parseNotification(userInfo).navigationState
    }

    static func preferredRootTab(for userInfo: [AnyHashable: Any]) throws -> AppDeepLinkPreferredRootTab? {
        try AppDeepLinkParser.parseNotification(userInfo).preferredRootTab
    }
}

extension Notification.Name {
    /// Internal bridge notification posted by the sample `UNUserNotificationCenterDelegate`.
    nonisolated static let sampleAppNotificationDeepLinkReceived =
        Notification.Name("SwiftNavigationSampleApp.notificationDeepLinkReceived")
}

private struct ParsedAppDeepLink {
    let preferredRootTab: AppDeepLinkPreferredRootTab?
    let navigationState: NavigationState<AppRoute, AppModalRoute, Never>
}

private enum AppDeepLinkParser {
    private static let customSchemes = ["swiftnavsample", "swiftnavigationsample"]
    private static let webSchemes = ["http", "https"]

    static func parseURL(_ url: URL) throws -> ParsedAppDeepLink {
        if let scheme = url.scheme?.lowercased(),
           !scheme.isEmpty,
           !customSchemes.contains(scheme),
           !webSchemes.contains(scheme) {
            throw AppDeepLinkError.unsupportedURLScheme(url.scheme)
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        let segments = normalizedSegments(from: url)

        guard let target = segments.first?.lowercased() else {
            return ParsedAppDeepLink(
                preferredRootTab: defaultPreferredRootTab(for: url),
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

        case "showcase":
            return try showcaseDeepLink(
                segments: segments.dropFirst(),
                queryItems: queryItems
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

        case "showcase":
            return try showcaseNotification(userInfo)

        case "send-money", "sendmoney", "payment":
            return try sendMoneyNotification(userInfo)

        case "profile":
            return try protectedProfileNotification(userInfo)

        case "receipt":
            return try protectedReceiptNotification(userInfo)

        default:
            throw AppDeepLinkError.unsupportedTarget(target)
        }
    }

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

    private static func showcaseDeepLink(
        segments: ArraySlice<String>,
        queryItems: [URLQueryItem]
    ) throws -> ParsedAppDeepLink {
        guard let destination = segments.first?.lowercased() else {
            return ParsedAppDeepLink(preferredRootTab: .showcase, navigationState: NavigationState())
        }

        switch destination {
        case "send-money", "sendmoney", "payment", "bizum":
            let recipient = stringQueryItem(named: "recipient", in: queryItems) ?? "Sonia"
            let flowID = uuidQueryItem(named: "flowID", in: queryItems) ?? UUID()
            let route = makeSendMoneyRecipientRoute(
                flowID: flowID,
                selectedRecipient: recipient
            )
            return ParsedAppDeepLink(
                preferredRootTab: .showcase,
                navigationState: NavigationState(stack: [.sendMoneyRecipient(route)])
            )

        case "profile":
            let displayName = stringQueryItem(named: "displayName", in: queryItems)
                ?? stringQueryItem(named: "recipient", in: queryItems)
                ?? "Sonia"
            let profileID = uuidQueryItem(named: "profileID", in: queryItems)
            let route = makeProtectedProfileRoute(
                profileID: profileID,
                displayName: displayName
            )
            return ParsedAppDeepLink(
                preferredRootTab: .showcase,
                navigationState: NavigationState(stack: [.protectedProfile(route)])
            )

        case "receipt":
            let recipient = stringQueryItem(named: "recipient", in: queryItems) ?? "Sonia"
            let amount = try doubleQueryItem(named: "amount", in: queryItems) ?? 35
            let flowID = uuidQueryItem(named: "flowID", in: queryItems) ?? UUID()
            let reference = stringQueryItem(named: "reference", in: queryItems)
                ?? makeReference(for: flowID)
            let route = ProtectedReceiptRouteData(
                flowID: flowID,
                selectedRecipient: recipient,
                amount: amount,
                reference: reference
            )
            return ParsedAppDeepLink(
                preferredRootTab: .showcase,
                navigationState: NavigationState(stack: [.protectedReceipt(route)])
            )

        default:
            throw AppDeepLinkError.unsupportedTarget(destination)
        }
    }

    private static func showcaseNotification(_ userInfo: [AnyHashable: Any]) throws -> ParsedAppDeepLink {
        guard let screen = try stringValue(forKey: "screen", in: userInfo) else {
            return ParsedAppDeepLink(preferredRootTab: .showcase, navigationState: NavigationState())
        }

        switch screen.lowercased() {
        case "send-money", "sendmoney", "payment":
            return try sendMoneyNotification(userInfo)
        case "profile":
            return try protectedProfileNotification(userInfo)
        case "receipt":
            return try protectedReceiptNotification(userInfo)
        default:
            throw AppDeepLinkError.unsupportedTarget(screen)
        }
    }

    private static func sendMoneyNotification(_ userInfo: [AnyHashable: Any]) throws -> ParsedAppDeepLink {
        let recipient = try stringValue(forKey: "recipient", in: userInfo) ?? "Sonia"
        let flowID = try uuidValue(forKey: "flowID", in: userInfo) ?? UUID()
        let route = makeSendMoneyRecipientRoute(
            flowID: flowID,
            selectedRecipient: recipient
        )

        return ParsedAppDeepLink(
            preferredRootTab: .showcase,
            navigationState: NavigationState(stack: [.sendMoneyRecipient(route)])
        )
    }

    private static func protectedProfileNotification(_ userInfo: [AnyHashable: Any]) throws -> ParsedAppDeepLink {
        let displayName = try stringValue(forKey: "displayName", in: userInfo)
            ?? stringValue(forKey: "recipient", in: userInfo)
            ?? "Sonia"
        let profileID = try uuidValue(forKey: "profileID", in: userInfo)
        let route = makeProtectedProfileRoute(
            profileID: profileID,
            displayName: displayName
        )

        return ParsedAppDeepLink(
            preferredRootTab: .showcase,
            navigationState: NavigationState(stack: [.protectedProfile(route)])
        )
    }

    private static func protectedReceiptNotification(_ userInfo: [AnyHashable: Any]) throws -> ParsedAppDeepLink {
        let recipient = try stringValue(forKey: "recipient", in: userInfo) ?? "Sonia"
        let amount = try doubleValue(forKey: "amount", in: userInfo) ?? 35
        let flowID = try uuidValue(forKey: "flowID", in: userInfo) ?? UUID()
        let reference = try stringValue(forKey: "reference", in: userInfo)
            ?? makeReference(for: flowID)
        let route = ProtectedReceiptRouteData(
            flowID: flowID,
            selectedRecipient: recipient,
            amount: amount,
            reference: reference
        )

        return ParsedAppDeepLink(
            preferredRootTab: .showcase,
            navigationState: NavigationState(stack: [.protectedReceipt(route)])
        )
    }

    private static func defaultPreferredRootTab(for url: URL) -> AppDeepLinkPreferredRootTab {
        switch url.scheme?.lowercased() {
        case "http", "https":
            .showcase
        default:
            .characters
        }
    }

    private static func normalizedSegments(from url: URL) -> [String] {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let pathSegments = (components?.path ?? "")
            .split(separator: "/")
            .map(String.init)

        switch url.scheme?.lowercased() {
        case "http", "https":
            return pathSegments.filter { !$0.isEmpty }
        default:
            let hostSegment = components?.host
            return ([hostSegment].compactMap { $0 } + pathSegments)
                .filter { !$0.isEmpty }
        }
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

    private static func makeSendMoneyRecipientRoute(
        flowID: UUID,
        selectedRecipient: String
    ) -> SendMoneyRecipientRouteData {
        SendMoneyRecipientRouteData(
            flowID: flowID,
            selectedRecipient: selectedRecipient,
            availableRecipients: showcaseRecipients(selectedRecipient: selectedRecipient)
        )
    }

    private static func makeProtectedProfileRoute(
        profileID: UUID?,
        displayName: String
    ) -> ProtectedProfileRouteData {
        ProtectedProfileRouteData(
            profileID: profileID ?? UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE") ?? UUID(),
            displayName: displayName,
            subtitle: "This destination is protected to demonstrate deep-link login interception."
        )
    }

    private static func showcaseRecipients(selectedRecipient: String) -> [String] {
        let defaultRecipients = ["Sonia", "Alex", "Maya", "Taylor"]
        guard !defaultRecipients.contains(selectedRecipient) else {
            return defaultRecipients
        }
        return [selectedRecipient] + defaultRecipients
    }

    private static func makeReference(for flowID: UUID) -> String {
        let compactID = flowID.uuidString.replacing("-", with: "")
        return "BZM-\(compactID.prefix(6))"
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

    private static func doubleQueryItem(named name: String, in items: [URLQueryItem]) throws -> Double? {
        guard let rawValue = stringQueryItem(named: name, in: items) else {
            return nil
        }
        guard let value = Double(rawValue) else {
            throw AppDeepLinkError.invalidNumericValue(field: name, rawValue: rawValue)
        }
        return value
    }

    private static func boolQueryItem(named name: String, in items: [URLQueryItem]) -> Bool? {
        guard let rawValue = stringQueryItem(named: name, in: items) else {
            return nil
        }
        return parseBool(rawValue)
    }

    private static func uuidQueryItem(named name: String, in items: [URLQueryItem]) -> UUID? {
        guard let rawValue = stringQueryItem(named: name, in: items) else {
            return nil
        }
        return UUID(uuidString: rawValue)
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

    private static func doubleValue(forKey key: String, in dictionary: [AnyHashable: Any]) throws -> Double? {
        guard let value = dictionary[key] else {
            return nil
        }

        if let doubleValue = value as? Double {
            return doubleValue
        }

        if let intValue = value as? Int {
            return Double(intValue)
        }

        if let numberValue = value as? NSNumber {
            return numberValue.doubleValue
        }

        if let stringValue = value as? String {
            guard let parsed = Double(stringValue) else {
                throw AppDeepLinkError.invalidNumericValue(field: key, rawValue: stringValue)
            }
            return parsed
        }

        throw AppDeepLinkError.missingNotificationField(key)
    }

    private static func uuidValue(forKey key: String, in dictionary: [AnyHashable: Any]) throws -> UUID? {
        guard let rawValue = try stringValue(forKey: key, in: dictionary) else {
            return nil
        }

        guard let uuid = UUID(uuidString: rawValue) else {
            throw AppDeepLinkError.invalidIdentifier(rawValue)
        }

        return uuid
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
            true
        case "0", "false", "no", "n", "off":
            false
        default:
            nil
        }
    }
}
