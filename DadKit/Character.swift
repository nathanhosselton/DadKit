import Foundation
import PMKFoundation

/// A type for represeting an in-game character for Destiny 2.
public struct Character: Decodable, SubclassRepresentable {

    /// The player that owns this character.
    public let player: Player

    /// This character's class, i.e. Titan, Hunter, or Warlock.
    public let classType: Class

    /// This character's subclass, i.e. Solar, Arc, or Void.
    /// - Note: This object is provided for convenience and has no public accessors of its own.
    /// - SeeAlso: `subclassName`, `subclassPath`, `subclassTree`, and `subclassSuper`
    public let subclass: Subclass

    /// The name for this character's chosen Subclass. E.g. "Gunslinger".
    public var subclassName: String {
        return subclass.name
    }

    /// The name of the path for this character's chosen Subclass. E.g. "Way of the Gunslinger".
    public var subclassPath: String {
        return tree.path(for: subclass)
    }

    /// The relative location of this character's chosen Subclass tree in the in-game UI. E.g. “Top”.
    public var subclassTree: String {
        return tree.rawValue
    }

    /// The name of the super for this character's chosen Subclass. E.g. “Golden Gun”.
    public var subclassSuper: String {
        return tree.super(for: subclass)
    }

    /// The current experience progression level of this character.
    public let level: Int

    /// The current power level of this character based on equipped gear.
    public let light: Int

    /// The current mobility stat of this character.
    public let mobility: Int

    /// The current resilience stat of this character.
    public let resilience: Int

    /// The current recovery stat of this character.
    public let recovery: Int

    /// The url for the character's current emblem.
    public let emblemPath: URL

    /// The url for the character's current emblem for background display.
    public let emblemBackgroundPath: URL

    /// The relevant items equipped on the character. Subscriptable with `Item.Slot` and `Item.Tier`.
    /// - Note: This will be empty when using `Bungie.getCurrentCharacterWithoutLoadout(for:)`, requiring manual retreival and loadout tracking with `Bungie.getEquippedItems(for:)`.
    public internal(set) var loadout: Loadout = []

    //This character's unique identifier
    internal let id: String
    //The last date this character was online
    internal let dateLastPlayed: Date
    //This character's active tree for their `Subclass`.
    internal let tree: Subclass.Tree
    //Meta information for the currently euipped items to be used to construct the `loadout`.
    internal let equipment: [CharacterEquipment.Equipment.Item]
    //Instance information for the currently equipped items to be used to construct the `loadout`.
    internal let itemInstances: [ItemComponents.Instances.Item]
}

public extension Character {
    /// A type that represents a `Character`'s class.
    public enum Class: Int, Decodable {
        case titan, hunter, warlock, unknown

        /// The display name of the class.
        public var name: String {
            switch self {
            case .titan:
                return "Titan"
            case .hunter:
                return "Hunter"
            case .warlock:
                return "Warlock"
            default:
                return ""
            }
        }
    }
}

/// Alias for an array that contains `Item`s which can be subscripted with an `Item.Slot` or `Item.Tier`.
/// - Warning: Currently only the Raid Dad `Slot`s and `Tier`s (kinetic, energy, heavy, exotic) are supported. Attempting to subcript with another value will raise an exception.
public typealias Loadout = [Item]

//Loadout
public extension Array where Element == Item {
    /// Access a `Loadout` `Item` for a given `Item.Slot`.
    /// - Warning: Currently only the weapon `Item.Slot`'s are supported. Attempting to subcript with another value will raise an exception.
    public internal(set) subscript(slot: Item.Slot) -> Item? {
        get {
            return first { $0.slot == slot }
        }
        set {
            //FIXME: Needs test
            guard Item.Slot.weapons.contains(slot) else { fatalError("DadKit: `Loadout` subcscripting with type `Item.Slot` only supports weapon slots.") }
            removeAll { $0.slot == slot }
            newValue.flatMap { append($0) }
        }
    }

    /// Access a `Loadout` `Item` for a given `Item.Tier`.
    /// - Warning: Currently only `Item.Tier.exotic` is supported. Attempting to subcript with another value will raise an exception.
    public internal(set) subscript(slot: Item.Tier) -> Item? {
        get {
            return first { $0.tier == slot }
        }
        set {
            //FIXME: Needs test
            guard slot == .exotic else { fatalError("DadKit: `Loadout` subcscripting with type `Item.Tier` only supports `.exotic`.") }
            removeAll { $0.tier == slot }
            newValue.flatMap { append($0) }
        }
    }
}

//MARK: API Request

public extension Bungie {
    /// Retrieves the given `player`'s most recently used `Character` without making the requests for the `loadout`.
    /// When using this function, the `Loadout` will need to be requested using `Bungie.getLoadout(for:)` and tracked separately.
    public static func getCurrentCharacterWithoutLoadout(for player: Player) -> Promise<Character> {
        let req = API.getPlayer(withId: player.membershipId, onPlatform: player.platform).request

        return firstly {
            URLSession.shared.dataTask(.promise, with: req).validate()
        }.map { data, _ in
            try Bungie.decoder.decode(PlayerMetaResponse.self, from: data).Response
        }
    }

    /// Retrieves the given `player`'s most recently used `Character`, fully formed, including all `loadout` data.
    public static func getCurrentCharacter(for player: Player) -> Promise<Character> {
        return firstly {
            Bungie.getCurrentCharacterWithoutLoadout(for: player)
        }.then { character in
            Bungie.getLoadout(for: character).map { (character, $0) }
        }.map { character, items in
            var character = character
            character.loadout = items
            return character
        }
    }
}

//MARK: API Response

typealias CharacterHash = String
typealias ItemHash = String

struct PlayerMetaResponse: Decodable {
    let Response: Character //Custom Decodable
}

struct PlayerProfile: Decodable {
    let data: PlayerInfo

    struct PlayerInfo: Decodable {
        let userInfo: Player
        let characterIds: [String]
    }
}

struct PlayerCharacters: Decodable {
    let data: [CharacterHash: RawCharacter]
}

//Most of this ends up in the public `Item` type.
struct CharacterEquipment: Decodable {
    let data: [CharacterHash: Equipment]

    struct Equipment: Decodable {
        let items: [Equipment.Item]

        struct Item: Decodable {
            let itemHash: Int
            let itemInstanceId: String
            let bucketHash: DadKit.Item.Slot
            let state: State

            struct State: OptionSet, Decodable {
                let rawValue: UInt32

                static let none         = State(rawValue: 1 << 0)
                static let locked       = State(rawValue: 1 << 1)
                static let tracked      = State(rawValue: 1 << 2)
                static let masterwork   = State(rawValue: 1 << 4)
            }
        }
    }
}

//Most of this ends up in the public `Item` type.
struct ItemComponents: Decodable {
    let instances: ItemComponents.Instances
    let talentGrids: ItemComponents.TalentGrids

    struct TalentGrids: Decodable {
        let data: [ItemHash: ItemTalentGrid]
    }

    struct Instances: Decodable {
        let data: [ItemHash: Instances.Item]

        struct Item: Decodable {
            let damageType: DadKit.Item.DamageType
            let isEquipped: Bool
            let primaryStat: Item.Stats?

            struct Stats: Decodable {
                /// A hash that represents the type of stat, e.g. Attack, Defense.
                let statHash: Stats.Hash
                /// Value level for stat, e.g. 600.
                let value: Int

                enum Hash: Int, Decodable {
                    case attack = 1480404414
                    case defense = 3897883278
                    case other

                    /// Custom Decodable conformance
                    init(from decoder: Decoder) throws {
                        let raw = try decoder.singleValueContainer().decode(Int.self)
                        self = Hash(rawValue: raw) ?? .other
                    }
                }
            }
        }
    }
}

struct ItemTalentGrid: Decodable {
    let talentGridHash: Int
    let nodes: [Node]

    struct Node: Decodable {
        let nodeIndex: Int
        let isActivated: Bool
    }
}
