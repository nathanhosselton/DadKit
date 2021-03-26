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
        var request = API.postFindClan().request

        let parameters: [String: Any] = [
            "groupName": name,
            "groupType": 1
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch let error {
            print(error.localizedDescription)
        }

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

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
