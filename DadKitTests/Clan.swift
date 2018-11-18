import XCTest
@testable import DadKit

class ClanTests: XCTestCase {

    override func setUp() {
        Bungie.key = ENV_API_KEY
        Bungie.appId = ""
        Bungie.appVersion = ""
    }

    func test_DecodeClanResponse() {
        let data = plaintextResponseExample.data(using: .utf8)!

        do {
            _ = try JSONDecoder().decode(ClanMetaResponse.self, from: data)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_API_GetClanRequestResponds200() {
        let req = Bungie.API.getClan(withId: "2771930").request //Meow Pew Pew
        let x = expectation(description: "Get Clan request responds with 200.")
        let promise = URLSession.shared.dataTask(.promise, with: req).validate()

        _ = promise.done { _ in
            x.fulfill()
        }.catch {
            XCTFail($0.localizedDescription)
            x.fulfill()
        }

        wait(for: [x], timeout: 10)
    }

    func test_API_FindClanRequestResponds200() {
        let req = Bungie.API.getFindClan(withQuery: "Meow Pew Pew").request
        let x = expectation(description: "Find Clan request responds with 200.")
        let promise = URLSession.shared.dataTask(.promise, with: req).validate()
        
        _ = promise.done { _ in
            x.fulfill()
        }.catch {
            XCTFail($0.localizedDescription)
            x.fulfill()
        }

        wait(for: [x], timeout: 10)
    }

    func test_API_FindClanRequestWithSpecialCharactersResponds200() {
        let req = Bungie.API.getFindClan(withQuery: "!Meow Pew Pew").request
        let x = expectation(description: "Find Clan request responds with 200.")
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
    return "{\"Response\":{\"detail\":{\"groupId\":\"2771930\",\"name\":\"Meow Pew Pew\",\"groupType\":1,\"membershipIdCreated\":\"6796059\",\"creationDate\":\"2017-10-25T02:17:03.309Z\",\"modificationDate\":\"2017-10-25T02:17:03.309Z\",\"about\":\"We are a nice group of people that Meow and Pew.\",\"tags\":[],\"memberCount\":38,\"isPublic\":true,\"isPublicTopicAdminOnly\":false,\"motto\":\"We MEOW and PEW\",\"allowChat\":true,\"isDefaultPostPublic\":false,\"chatSecurity\":0,\"locale\":\"en\",\"avatarImageIndex\":0,\"homepage\":0,\"membershipOption\":0,\"defaultPublicity\":2,\"theme\":\"Group_Community1\",\"bannerPath\":\"/img/Themes/Group_Community1/struct_images/group_top_banner.jpg\",\"avatarPath\":\"/img/profile/avatars/group/defaultGroup.png\",\"conversationId\":\"32472063\",\"enableInvitationMessagingForAdmins\":false,\"banExpireDate\":\"2001-01-01T00:00:00Z\",\"features\":{\"maximumMembers\":100,\"maximumMembershipsOfGroupType\":1,\"capabilities\":31,\"membershipTypes\":[1,2,4,10],\"invitePermissionOverride\":true,\"updateCulturePermissionOverride\":true,\"hostGuidedGamePermissionOverride\":2,\"updateBannerPermissionOverride\":true,\"joinLevel\":2},\"clanInfo\":{\"d2ClanProgressions\":{\"584850370\":{\"progressionHash\":584850370,\"dailyProgress\":600000,\"dailyLimit\":0,\"weeklyProgress\":0,\"weeklyLimit\":0,\"currentProgress\":600000,\"level\":6,\"levelCap\":6,\"stepIndex\":6,\"progressToNextLevel\":0,\"nextLevelAt\":0},\"1273404180\":{\"progressionHash\":1273404180,\"dailyProgress\":0,\"dailyLimit\":0,\"weeklyProgress\":0,\"weeklyLimit\":0,\"currentProgress\":0,\"level\":1,\"levelCap\":6,\"stepIndex\":1,\"progressToNextLevel\":0,\"nextLevelAt\":1},\"3759191272\":{\"progressionHash\":3759191272,\"dailyProgress\":0,\"dailyLimit\":0,\"weeklyProgress\":0,\"weeklyLimit\":0,\"currentProgress\":0,\"level\":1,\"levelCap\":6,\"stepIndex\":1,\"progressToNextLevel\":0,\"nextLevelAt\":1},\"3381682691\":{\"progressionHash\":3381682691,\"dailyProgress\":0,\"dailyLimit\":0,\"weeklyProgress\":0,\"weeklyLimit\":0,\"currentProgress\":0,\"level\":1,\"levelCap\":6,\"stepIndex\":1,\"progressToNextLevel\":0,\"nextLevelAt\":1}},\"clanCallsign\":\"MEOW\",\"clanBannerData\":{\"decalId\":4125445804,\"decalColorId\":3345832523,\"decalBackgroundColorId\":3568748758,\"gonfalonId\":1473910866,\"gonfalonColorId\":2174413916,\"gonfalonDetailId\":1647698443,\"gonfalonDetailColorId\":4128900502}}},\"founder\":{\"memberType\":5,\"isOnline\":false,\"groupId\":\"2771930\",\"destinyUserInfo\":{\"iconPath\":\"\",\"membershipType\":4,\"membershipId\":\"4611686018467467114\",\"displayName\":\"gargarbot\"},\"bungieNetUserInfo\":{\"supplementalDisplayName\":\"6796059\",\"iconPath\":\"/img/profile/avatars/cc00007.jpg\",\"membershipType\":254,\"membershipId\":\"6796059\",\"displayName\":\"gargarbot\"},\"joinDate\":\"2017-10-25T02:17:03Z\"},\"alliedIds\":[],\"allianceStatus\":0,\"groupJoinInviteCount\":0,\"currentUserMemberMap\":{},\"currentUserPotentialMemberMap\":{}},\"ErrorCode\":1,\"ThrottleSeconds\":0,\"ErrorStatus\":\"Success\",\"Message\":\"Ok\",\"MessageData\":{}}"
}
