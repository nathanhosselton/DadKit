import Foundation
import PMKFoundation

/// A type representing a clan on Bungie.net.
public struct Clan: Decodable {

    /// The unique identifier for this clan on Bungie.net.
    public let groupId: String

    /// The display name for this clan.
    public let name: String
}

//MARK: API Request

public extension Bungie {
    /// Gets the specific `Clan` with the provided identifier.
    public static func getClan(with id: String) -> Promise<Clan> {
        let req = API.getClan(withId: id).request

        return firstly {
            URLSession.shared.dataTask(.promise, with: req).validate()
        }.map { data, _ in
            try JSONDecoder().decode(ClanMetaResponse.self, from: data).Response.detail
        }
    }

    /// Performs a clan search using the provided name.
    public static func searchForClan(named name: String) -> Promise<Clan> {
        let req = API.getFindClan(withQuery: name).request
        
        return firstly {
            URLSession.shared.dataTask(.promise, with: req).validate()
        }.map { data, _ in
            //TODO: Error state?
            try JSONDecoder().decode(ClanMetaResponse.self, from: data).Response.detail
        }
    }
}

//MARK: API Response

struct ClanMetaResponse: Decodable {
    let Response: ClanResponse

    struct ClanResponse: Decodable {
        let detail: Clan
    }
}
