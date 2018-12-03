import XCTest
@testable import DadKit
import PMKFoundation

class BungieTests: XCTestCase {

    override func setUp() {
        Bungie.key = ENV_API_KEY
        Bungie.appId = ""
        Bungie.appVersion = ""
    }

    func test_FullRequestPathSucceeds() {
        let x = expectation(description: #file + #function)

        firstly {
            Bungie.searchForClan(named: "Meow Pew Pew")
        }.then {
            Bungie.getMembers(in: $0)
        }.map {
            $0.prefix(6)
        }.mapValues {
            Bungie.getCurrentCharacter(for: $0.destinyUserInfo)
        }.then {
            when(fulfilled: $0)
        }.done { _ in
            x.fulfill()
        }.catch {
            print($0)
            XCTFail($0.localizedDescription)
            x.fulfill()
        }

        wait(for: [x], timeout: 1000)
    }
}
