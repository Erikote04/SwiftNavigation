import Foundation

/// A typed representation of SwiftUI sheet detents.
public enum SheetDetent: Codable, Hashable, Sendable {
    case medium
    case large
    case fraction(Double)
    case height(Double)
}

/// A typed representation of sheet background styles supported by SwiftNavigation.
public enum SheetBackgroundStyle: String, Codable, Hashable, Sendable {
    case clear
    case ultraThinMaterial
    case thinMaterial
    case regularMaterial
    case thickMaterial
}

/// A typed representation of background interaction rules for sheets.
public enum SheetBackgroundInteraction: Codable, Hashable, Sendable {
    case automatic
    case disabled
    case enabled
    case enabledThrough(SheetDetent)

    private enum CodingKeys: String, CodingKey {
        case automatic
        case disabled
        case enabled
        case enabledThrough
    }

    private enum AssociatedValueKeys: String, CodingKey {
        case detent
        case _0
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.contains(.automatic) {
            self = .automatic
            return
        }

        if container.contains(.disabled) {
            self = .disabled
            return
        }

        if container.contains(.enabled) {
            self = .enabled
            return
        }

        if container.contains(.enabledThrough) {
            let nested = try container.nestedContainer(keyedBy: AssociatedValueKeys.self, forKey: .enabledThrough)
            if let detent = try nested.decodeIfPresent(SheetDetent.self, forKey: .detent)
                ?? nested.decodeIfPresent(SheetDetent.self, forKey: ._0) {
                self = .enabledThrough(detent)
                return
            }
            throw DecodingError.dataCorruptedError(
                forKey: .enabledThrough,
                in: container,
                debugDescription: "Missing detent for enabledThrough background interaction."
            )
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Invalid SheetBackgroundInteraction payload."
            )
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .automatic:
            _ = container.nestedContainer(keyedBy: AssociatedValueKeys.self, forKey: .automatic)
        case .disabled:
            _ = container.nestedContainer(keyedBy: AssociatedValueKeys.self, forKey: .disabled)
        case .enabled:
            _ = container.nestedContainer(keyedBy: AssociatedValueKeys.self, forKey: .enabled)
        case .enabledThrough(let detent):
            var nested = container.nestedContainer(keyedBy: AssociatedValueKeys.self, forKey: .enabledThrough)
            try nested.encode(detent, forKey: .detent)
            try nested.encode(detent, forKey: ._0)
        }
    }
}

/// Typed sheet presentation options applied by `RoutingView`.
public struct SheetPresentationOptions: Codable, Hashable, Sendable {
    /// Supported sheet detents for the presentation.
    public var detents: [SheetDetent]
    /// Optional background style rendered behind the sheet content.
    public var background: SheetBackgroundStyle?
    /// Optional interaction rule for the content behind the sheet.
    public var backgroundInteraction: SheetBackgroundInteraction?
    /// Whether interactive dismissal is disabled.
    public var interactiveDismissDisabled: Bool

    /// Creates sheet presentation options.
    ///
    /// - Parameters:
    ///   - detents: Supported sheet detents.
    ///   - background: Optional background style.
    ///   - backgroundInteraction: Optional interaction rule for the background.
    ///   - interactiveDismissDisabled: Whether the sheet can be dismissed interactively.
    public init(
        detents: [SheetDetent] = [.large],
        background: SheetBackgroundStyle? = nil,
        backgroundInteraction: SheetBackgroundInteraction? = nil,
        interactiveDismissDisabled: Bool = false
    ) {
        self.detents = detents
        self.background = background
        self.backgroundInteraction = backgroundInteraction
        self.interactiveDismissDisabled = interactiveDismissDisabled
    }
}
