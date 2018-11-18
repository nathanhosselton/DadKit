import Foundation
import PMKFoundation

/// A type for representing a player of Destiny 2.
public struct Player: Decodable {

    /// The player's chosen name on their platform.
    /// - Note: Does not display the trailing hash for Battlenet ids.
    public let displayName: String

    /// The platform on which this player account originates.
    public var platform: Bungie.Platform {
        return .init(rawValue: .some(membershipType))
    }

    /// The raw value that represent's the player account's platform.
    internal let membershipType: Int
    /// The unique platform-specific identifier of this player account.
    internal let membershipId: String
}

//MARK: API Request

public extension Bungie {
    /// Performs a search for the given player tag on the provided platform.
    /// - Note: Searches for `.blizzard` players requires inclusion of the trailing hash, e.g. "#1234".
    public static func searchForPlayer(with tag: String, on platform: Platform = .all) -> Promise<[Player]> {
        let req = API.getFindPlayer(withQuery: tag, onPlatform: platform).request

        return firstly {
            URLSession.shared.dataTask(.promise, with: req).validate()
        }.map { data, _ in
            try JSONDecoder().decode(PlayerSearchMetaResponse.self, from: data).Response
        }
    }
}

//MARK: API Response

struct PlayerSearchMetaResponse: Decodable {
    let Response: [Player]
}
