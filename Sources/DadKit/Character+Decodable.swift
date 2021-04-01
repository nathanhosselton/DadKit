import Foundation

extension Character {

    private enum RootKeys: CodingKey {
        case profile, characters, characterEquipment, itemComponents, profileTransitoryData
    }

    /// Custom decodable implementation
    public init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: RootKeys.self)

        //Player profile
        let rawProfile = try root.decode(PlayerProfile.self, forKey: .profile)
        player = rawProfile.data.userInfo

        //Back out if the player has no characters
        guard !rawProfile.data.characterIds.isEmpty else { throw Bungie.Error.noCharactersAssociatedWithPlayer }

        //Grab current character and its hash
        typealias IndexedCharacter = (CharacterHash, RawCharacter)
        let mostRecent: (IndexedCharacter, IndexedCharacter) -> Bool = { $0.1.dateLastPlayed > $1.1.dateLastPlayed }
        let indexedCharacters = try root.decode(PlayerCharacters.self, forKey: .characters).data
        let (characterHash, character) = indexedCharacters.sorted(by: mostRecent)[0] //Indexing is safe because of the guard

        guard let emblemUrl = URL(string: "https://bungie.net" + character.emblemPath),
            let emblemBackgroundUrl = URL(string: "https://bungie.net" + character.emblemBackgroundPath)
            else { throw Bungie.Error.emblemImageUrlsMissingOrMalformed }

        //Map properties from the auto-decoded RawCharacter object
        light = character.light
        emblemPath = emblemUrl
        emblemBackgroundPath = emblemBackgroundUrl
        dateLastPlayed = character.dateLastPlayed
        id = character.characterId
        level = character.levelProgression.level
        mobility = character.stats.mobility
        resilience = character.stats.resilience
        recovery = character.stats.recovery
        discipline = character.stats.discipline
        intellect = character.stats.intellect
        strength = character.stats.strength

        classType = character.classType

        //Current character's relevant equipment
        let rawEquipment = try root.decode(CharacterEquipment.self, forKey: .characterEquipment)
        let allEquipment = rawEquipment.data[characterHash]!.items //Can't Decodable this because of dynamic keys but ! is safe due to guard
        equipment = allEquipment.filter { Item.Slot.weaponsAndArmor.contains($0.bucketHash) || $0.bucketHash == Item.Slot.subclass }
                                .reduce(into: [Int: CharacterEquipment.Equipment.Item]()) { $0[$1.itemHash] = $1 }

        //Instance information for the character's equipment
        let itemComponents = try root.decode(ItemComponents.self, forKey: .itemComponents)
        let currentInstanceIds = equipment.map { ($1.itemInstanceId, $0) }
        itemInstances = currentInstanceIds.reduce(into: [Int: ItemComponents.Instances.Item]()) { $0[$1.1] = itemComponents.instances.data[$1.0] }

        // Parse out the sockets.
        sockets = itemComponents.sockets.data.compactMap { (key: ItemHash, value: ItemSockets) -> (Int, [ItemSockets.Socket])? in
            if let itemHash = Int(key) {
                return (itemHash, value.sockets)
            } else {
                return nil
            }
        }.reduce(into: [:]) { $0[$1.0] = $1.1 }

        //Current character's subclass
        let subclassKey = allEquipment.subclassItem?.itemInstanceId
        let subclassTalentGrid = itemComponents.talentGrids.data.first(where: { $0.key == subclassKey } )?.value
        subclass = Subclass(withHash: subclassTalentGrid?.talentGridHash)

        // If we have no subclass, we need to parse out stasis manually.
        // It's very weirdly handled currently so we can fix this once the poison subclass arrives.
        if subclass == .unknown {
            subclass = .stasis(character.classType)
        }

        //Current character's subclass tree
        let activeNodes = subclassTalentGrid?.nodes.compactMap { $0.isActivated ? $0.nodeIndex : nil }
        tree = Subclass.Tree(withNodes: activeNodes ?? [])

        // Parses out the fireteam info from the transitory data. This seems pretty unreliable though.
        if let rawTransitoryData = try? root.decode(TransitoryDataResponse.self, forKey: .profileTransitoryData) {
            self.transitoryData = rawTransitoryData.data
            self.fireteamMembers = rawTransitoryData.data.partyMembers.map { (transitoryPlayer) -> Member in
                return Member(isOnline: true, destinyUserInfo: Player(displayName: transitoryPlayer.displayName,
                                                                            membershipId: transitoryPlayer.membershipId,
                                                                            membershipPlatform: .none))
            }
        } else {
            self.transitoryData = nil
            self.fireteamMembers = nil
        }
    }
}

private extension Array where Element == CharacterEquipment.Equipment.Item {
    /// Returns the subclass item from a collection of the character's equipment items.
    var subclassItem: Element? {
        return first(where: { $0.bucketHash == Item.Slot.subclass })
    }
}

/// An indirect type used for automatically decoding character representations while the
/// public `Character` type maintains a custom decodable implementation.
struct RawCharacter: Decodable {
    let light: Int
    let emblemPath: String
    let emblemBackgroundPath: String
    let dateLastPlayed: Date // .iso8601 e.g. "2018-09-18T22:44:28Z"
    let characterId: String
    let levelProgression: LevelProgression
    let stats: Stats
    let classType: Character.Class

    struct Stats: Decodable {
        let mobility: Int
        let resilience: Int
        let recovery: Int
        let discipline: Int
        let intellect: Int
        let strength: Int

        enum Keys: String, CodingKey {
            case mobility = "2996146975"
            case resilience = "392767087"
            case recovery = "1943323491"
            case discipline = "1735777505"
            case intellect = "144602215"
            case strength = "4244567218"
        }

        init(from decoder: Decoder) throws {
            let rawStats = try decoder.container(keyedBy: Keys.self)

            mobility = try rawStats.decode(Int.self, forKey: .mobility)
            resilience = try rawStats.decode(Int.self, forKey: .resilience)
            recovery = try rawStats.decode(Int.self, forKey: .recovery)
            discipline = try rawStats.decode(Int.self, forKey: .discipline)
            intellect = try rawStats.decode(Int.self, forKey: .intellect)
            strength = try rawStats.decode(Int.self, forKey: .strength)
        }
    }

    struct LevelProgression: Decodable {
        let level: Int
    }
}
