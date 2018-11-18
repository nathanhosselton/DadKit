import XCTest
@testable import DadKit

class MemberTests: XCTestCase {

    override func setUp() {
        Bungie.key = ENV_API_KEY
        Bungie.appId = ""
        Bungie.appVersion = ""
    }

    func test_DecodeMemberResponse() {
        let data = plaintextResponseExample.data(using: .utf8)!

        do {
            _ = try JSONDecoder().decode(MemberMetaResponse.self, from: data)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_API_GetClanMembersRequestResponds200() {
        let req = Bungie.API.getMembers(withClanId: "2771930").request //Meow Pew Pew
        let x = expectation(description: "Get Clan Members request responds with 200.")
        let promise = URLSession.shared.dataTask(.promise, with: req).validate()

        _ = promise.done { _ in
            x.fulfill()
        }.catch {
            XCTFail($0.localizedDescription)
            x.fulfill()
        }

        wait(for: [x], timeout: 10)
    }

}

private var plaintextResponseExample: String {
    return "{\"Response\":{\"results\":[{\"memberType\":2,\"isOnline\":false,\"groupId\":\"2771930\",\"destinyUserInfo\":{\"iconPath\":\"\",\"membershipType\":4,\"membershipId\":\"4611686018467346411\",\"displayName\":\"b3ll\"},\"bungieNetUserInfo\":{\"supplementalDisplayName\":\"11652279\",\"iconPath\":\"/img/profile/avatars/s_tbagjx8.gif\",\"membershipType\":254,\"membershipId\":\"11652279\",\"displayName\":\"decib3ll_117\"},\"joinDate\":\"2017-10-26T20:04:17Z\"},{\"memberType\":2,\"isOnline\":false,\"groupId\":\"2771930\",\"destinyUserInfo\":{\"iconPath\":\"/img/theme/destiny/icons/icon_xbl.png\",\"membershipType\":1,\"membershipId\":\"4611686018447081737\",\"displayName\":\"MalarkeyMaybe\"},\"bungieNetUserInfo\":{\"supplementalDisplayName\":\"10851215\",\"iconPath\":\"/img/profile/avatars/default_avatar.gif\",\"membershipType\":254,\"membershipId\":\"10851215\",\"displayName\":\"ZX2MS\"},\"joinDate\":\"2017-10-25T02:34:15Z\"},{\"memberType\":2,\"isOnline\":false,\"groupId\":\"2771930\",\"destinyUserInfo\":{\"iconPath\":\"\",\"membershipType\":4,\"membershipId\":\"4611686018467286809\",\"displayName\":\"cagey\"},\"bungieNetUserInfo\":{\"supplementalDisplayName\":\"5129524\",\"iconPath\":\"/img/profile/avatars/cc71.jpg\",\"membershipType\":254,\"membershipId\":\"5129524\",\"displayName\":\"cagey\"},\"joinDate\":\"2017-10-25T21:25:25Z\"}],\"totalResults\":38,\"hasMore\":false,\"query\":{\"itemsPerPage\":100,\"currentPage\":1},\"useTotalResults\":true},\"ErrorCode\":1,\"ThrottleSeconds\":0,\"ErrorStatus\":\"Success\",\"Message\":\"Ok\",\"MessageData\":{}}"
}
