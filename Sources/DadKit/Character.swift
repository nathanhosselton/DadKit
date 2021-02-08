import Foundation
import PromiseKit
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

    /// The RaidDad-relevant gear equipped on the character.
    /// - Note: This will be empty when using `Bungie.getCurrentCharacterWithoutLoadout(for:)`, requiring manual retreival and loadout tracking with `Bungie.getLoadout(for:)`.
    public internal(set) var loadout = Loadout(with: [])

    //This character's unique identifier
    internal let id: String
    //The last date this character was online
    internal let dateLastPlayed: Date
    //This character's active tree for their `Subclass`.
    internal let tree: Subclass.Tree
    //Meta information for the currently euipped items to be used to construct the `loadout`.
    internal let equipment: [Int: CharacterEquipment.Equipment.Item]
    //Instance information for the currently equipped items to be used to construct the `loadout`.
    internal let itemInstances: [Int: ItemComponents.Instances.Item]
}

public extension Character {
    /// A type that represents a `Character`'s class.
    enum Class: Int, Decodable {
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

extension Character: Equatable {
    public static func == (lhs: Character, rhs: Character) -> Bool {
        return lhs.id == rhs.id && lhs.subclass == rhs.subclass
    }
}

//MARK: Loadout

public extension Character {

    /// A type representing the Raid Dad loadout of a `Character`.
    struct Loadout {

        /// The weapon equipped in the kinetic slot.
        public let kinetic: Item?

        /// The weapon equipped in the energy slot.
        public let energy: Item?

        /// The weapon equipped in the heavy slot.
        public let heavy: Item?

        /// The exotic armor piece equipped, if any.
        public let exoticArmor: Item?

        /// Returns `true` if the loadout contains an exotic armor piece (i.e. `exoticArmor` is non-nil).
        public var hasExoticArmor: Bool {
            return exoticArmor != nil
        }

//        public typealias Iterator = LoadoutIterator
//
//        public typealias Element = Item
//
//        public func makeIterator() -> Iterator {
//            return LoadoutIterator(self)
//        }

        /// Initializes a new `Loadout` object using an array of `Item`s, mapping to properties from the corresponding item slots.
        init(with items: [Item]) {
            kinetic = items.first(where: { $0.slot == .kinetic })
            energy = items.first(where: { $0.slot == .energy })
            heavy = items.first(where: { $0.slot == .heavy })
            exoticArmor = items.first(where: { ($0.slot, $0.tier) == Item.exoticArmor })
        }
    }

//    /// The iterator for traversing a `Loadout`.
//    public struct LoadoutIterator: IteratorProtocol {
//        private let loadout: Loadout
//        private var position = 0
//
//        public typealias Element = Item
//
//        fileprivate init(_ loadout: Loadout) {
//            self.loadout = loadout
//        }
//
//        mutating public func next() -> Element? {
//            defer { position += 1}
//
//            switch position {
//            case 0:
//                return loadout.kinetic
//            case 1:
//                return loadout.energy
//            case 2:
//                return loadout.heavy
//            case 3:
//                return loadout.exoticArmor
//            default:
//                return nil
//            }
//        }
//    }

}

//MARK: API Request

public extension Bungie {
    /// Retrieves the given `player`'s most recently used `Character` without making the requests for the `loadout`.
    /// When using this function, the `Loadout` will need to be requested using `Bungie.getLoadout(for:)` and tracked separately.
    static func getCurrentCharacterWithoutLoadout(for player: Player) -> Promise<Character> {
        let request = API.getPlayer(withId: player.membershipId, onPlatform: player.platform).request

        return firstly {
            Bungie.send(request)
        }.map(on: .global()) { data, _ in
            try Bungie.decoder.decode(PlayerMetaResponse.self, from: data).Response
        }
    }

    /// Retrieves the given `player`'s most recently used `Character`, fully formed, including all `loadout` data.
    static func getCurrentCharacter(for player: Player) -> Promise<Character> {
        return firstly {
            Bungie.getCurrentCharacterWithoutLoadout(for: player)
        }.then(on: .global()) { character in
            Bungie.getLoadout(for: character).map { (character, $0) }
        }.map(on: .global()) { character, loadout in
            var character = character
            character.loadout = loadout
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

                static let none         = State(rawValue: 0)
                static let locked       = State(rawValue: 1 << 0)
                static let tracked      = State(rawValue: 1 << 1)
                static let masterwork   = State(rawValue: 1 << 2)
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
