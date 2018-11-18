import XCTest
@testable import DadKit

class PlayerTests: XCTestCase {

    override func setUp() {
        Bungie.key = ENV_API_KEY
        Bungie.appId = ""
        Bungie.appVersion = ""
    }

    func test_DecodePlayerSearchResponse() {
        let data = plaintextResponseExample.data(using: .utf8)!

        do {
            _ = try JSONDecoder().decode(PlayerSearchMetaResponse.self, from: data)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_API_FindPlayerRequestResponds200() {
        let req = Bungie.API.getFindPlayer(withQuery: "WeirdRituals#1656", onPlatform: .blizzard).request
        let x = expectation(description: "Find Player request responds with 200.")
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
    return "{\"Response\":[{\"membershipType\":4,\"membershipId\":\"4611686018468167462\",\"displayName\":\"WeirdRituals#1656\"}],\"ErrorCode\":1,\"ThrottleSeconds\":0,\"ErrorStatus\":\"Success\",\"Message\":\"Ok\",\"MessageData\":{}}"
}
