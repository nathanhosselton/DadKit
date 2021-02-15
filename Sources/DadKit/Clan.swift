import Foundation
import PromiseKit
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
        let request = API.getClan(withId: id).request

        return firstly {
            Bungie.send(request)
        }.map(on: .global()) { data, _ in
            try Bungie.decoder.decode(ClanMetaResponse.self, from: data).Response.detail
        }
    }

    /// Performs a clan search using the provided name.
    static func searchForClan(named name: String) -> Promise<Clan> {
        let request = API.getFindClan(withQuery: name).request
        
        return firstly {
            Bungie.send(request)
        }.map(on: .global()) { data, _ in
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
