import Foundation
import PromiseKit
import PMKFoundation

/// A type for representing a player of Destiny 2.
public struct Player: Decodable, Encodable {

    /// The player's chosen name on their platform.
    /// - Note: Does not display the trailing hash for Battlenet ids.
    public let displayName: String

    public let lastSeenDisplayName: String?

    /// The platform on which this player account originates.
    public var platform: Bungie.Platform {
        return .init(rawValue: .some(membershipType))
    }

    /// The raw value that represent's the player account's platform.
    internal let membershipType: Int
    /// The unique platform-specific identifier of this player account.
    public let membershipId: String

    public init(displayName: String = "", lastSeenDisplayName: String? = nil, membershipId: String, membershipPlatform: Bungie.Platform) {
        self.displayName = displayName
        self.lastSeenDisplayName = lastSeenDisplayName ?? displayName
        self.membershipId = membershipId
        self.membershipType = membershipPlatform.rawValue
    }

    enum CodingKeys: String, CodingKey {
        case displayName
        case membershipType
        case membershipId
        case lastSeenDisplayName = "LastSeenDisplayName"
    }
    
}

extension Player: Comparable {
    public static func < (lhs: DadKit.Player, rhs: DadKit.Player) -> Bool {
        return lhs.displayName < rhs.displayName
    }

    public static func == (lhs: DadKit.Player, rhs: DadKit.Player) -> Bool {
        return lhs.displayName == rhs.displayName && lhs.membershipId == rhs.membershipId
    }
}

extension Player: Hashable
{}

//MARK: API Request

public extension Bungie {
    /// Performs a search for the given player tag on the provided platform.
    /// - Note: Searches for `.steam` players requires inclusion of the trailing hash, e.g. "#1234".
    static func searchForPlayer(with tag: String, on platform: Platform = .all) -> Promise<[Player]> {
        let request = API.getFindPlayer(withQuery: tag, onPlatform: platform).request

        return firstly {
            Bungie.send(request)
        }.map(on: .global()) { data, _ in
            try Bungie.decoder.decode(PlayerSearchMetaResponse.self, from: data).Response
        }
    }

    static func getCurrentPlayer(signRequest: (URLRequest) -> URLRequest) -> Promise<[Player]> {
        let request = API.getCurrentUser().request
        let signedRequest = signRequest(request)

        return firstly {
            Bungie.send(signedRequest)
        }.map(on: .global()) { data, _ in
            try Bungie.decoder.decode(UserMetaResponse.self, from: data).Response.destinyMemberships
        }
    }

    static func getMembershipData(for membershipId: String, platform: Platform) -> Promise<[Player]> {
        let request = API.getMembershipData(withId: membershipId, onPlatform: platform).request

        return firstly {
            Bungie.send(request)
        }.map(on: .global()) { data, _ in
            try Bungie.decoder.decode(UserMetaResponse.self, from: data).Response.destinyMemberships
        }
    }

}

//MARK: API Response

struct PlayerSearchMetaResponse: Decodable {
    let Response: [Player]
}

struct UserMetaResponse: Decodable {
    let Response: UserResponse

    struct UserResponse: Decodable {
        let destinyMemberships: [Player]
    }
}
