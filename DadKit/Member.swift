import Foundation
import PMKFoundation

/// A type for representing a player who is a member of a clan. Returned from API requests for clan members.
public struct Member: Decodable {

    /// A flag to indicate whether this clan member is currently online.
    public let isOnline: Bool

    /// The Destiny player information for this clan member.
    public let destinyUserInfo: Player
}

extension Member: Comparable {
    public static func < (lhs: Member, rhs: Member) -> Bool {
        return lhs.destinyUserInfo < rhs.destinyUserInfo
    }

    public static func == (lhs: Member, rhs: Member) -> Bool {
        return lhs.destinyUserInfo == rhs.destinyUserInfo
    }
}

//MARK: API Request

public extension Bungie {
    /// Retreives all clan members in the provided clan.
    public static func getClanMembers(in clan: Clan) -> Promise<[Member]> {
        let req = API.getMembers(withClanId: clan.groupId).request

        return firstly {
            URLSession.shared.dataTask(.promise, with: req).validate()
        }.map { data, _ in
            try Bungie.decoder.decode(MemberMetaResponse.self, from: data).Response.results
        }
    }
}

//MARK: API Response

struct MemberMetaResponse: Decodable {
    let Response: MemberResponse

    struct MemberResponse: Decodable {
        let results: [Member]
    }
}
