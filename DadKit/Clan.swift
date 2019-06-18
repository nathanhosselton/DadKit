import Foundation
import PMKFoundation

/// A type representing a clan on Bungie.net.
public struct Clan: Codable {

    /// The unique identifier for this clan on Bungie.net.
    public let groupId: String

    /// The display name for this clan.
    public let name: String
}

extension Clan: Equatable
{}

extension Clan: Hashable
{}

//MARK: API Request

public extension Bungie {
    /// Gets the specific `Clan` with the provided identifier.
    static func getClan(with id: String) -> Promise<Clan> {
        let req = API.getClan(withId: id).request

        return firstly {
            URLSession.shared.dataTask(.promise, with: req).validate()
        }.map(on: .global()) { data, _ in
            try Bungie.decoder.decode(ClanMetaResponse.self, from: data).Response.detail
        }
    }

    /// Performs a clan search using the provided name.
    static func searchForClan(named name: String) -> Promise<Clan> {
        let req = API.getFindClan(withQuery: name).request
        
        return firstly {
            URLSession.shared.dataTask(.promise, with: req).validate()
        }.map(on: .global()) { data, _ in
            //TODO: Error state?
            try Bungie.decoder.decode(ClanMetaResponse.self, from: data).Response.detail
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
