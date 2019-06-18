import Foundation
import PMKFoundation

public struct Item {

    /// Abstract definition of an exotic armor piece for comparison during initialization.
    internal typealias ExoticArmorComparitor = ([Item.Slot], Item.Tier)

    /// Abstract definition of an exotic armor piece for comparison during initialization.
    internal static let exoticArmor: ExoticArmorComparitor = (Item.Slot.armor, Item.Tier.exotic)

    /// The display name of this item.
    public let name: String

    /// The URL where the icon for this item may be retreived.
    public let icon: URL

    /// The damage type of this item, e.g. Kinectic, Solar, etc.
    public let damageType: Item.DamageType

    /// The power level of this item.
    public let power: Int

    /// The rarity tier of this item, e.g. Legendary.
    public let tier: Tier

    /// A flag that inidicates whether this item is fully masterworked and should be displayed accordingly.
    public let isFullyMasterworked: Bool

    /// The inventory slot in which this item resides, e.g. Kinetic, Helmet, etc.
    public let slot: Slot

    /// A type representing the various types of damage that a weapon can deal.
    public enum DamageType: Int, Decodable {
        case none, kinetic, arc, solar, void, raid
    }

    /// A type representing the levels of rarity associated with items.
    public enum Tier: Int, Decodable {
        case uncommon //unknown
        case common = 2395677314
        case rare = 2127292149
        case legendary = 4008398120
        case exotic = 2759499571
        /// One of these represents uncommon. Regardless, we don't really care.
        case basic0 = 3772930460, basic1 = 3340296461, basic6 = 1801258597
    }

    /// A type representing the inventory slots in which items may reside.
    public enum Slot: Int, Decodable {
        case subclass = 3284755031
        case kinetic = 1498876634
        case energy = 2465295065
        case heavy = 953998645
        case helmet = 3448274439
        case arms = 3551918588
        case chest = 14239492
        case legs = 20886954
        case classArmor = 1585787867
        /// Consumables, cosmetics, and other items we're currently ignoring.
        case other

        internal static var armor: [Slot] { return [.helmet, .arms, .chest, .legs] }
        internal static var weapons: [Slot] { return  [.kinetic, .energy, .heavy] }
        internal static var weaponsAndArmor: [Slot] { return armor + weapons }

        /// Custom Decodable conformance
        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(Int.self)
            self = Slot(rawValue: raw) ?? .other
        }
    }

    /// Builds the fully constructed `Item` from its various components across the API.
    fileprivate init?(from rawItem: RawItem, equip: CharacterEquipment.Equipment.Item, instance: ItemComponents.Instances.Item) {
        guard let powerLevel = instance.primaryStat?.value else { return nil }

        name = rawItem.displayProperties.name
        icon = URL(string: "https://bungie.net" + rawItem.displayProperties.icon)!
        damageType = instance.damageType
        power = powerLevel
        tier = rawItem.inventory.tierTypeHash
        isFullyMasterworked = equip.state.contains(.masterwork)
        slot = rawItem.inventory.bucketTypeHash
    }
}

extension Item: Equatable
{}

extension Item: Hashable
{}

//MARK: API Request

extension Bungie {
    /// Gets a `RawItem` given an item hash.
    private static func getItem(with id: Int) -> Promise<RawItem> {
        let req = API.getItem(withId: String(id)).request

        return firstly {
            URLSession.shared.dataTask(.promise, with: req).validate()
        }.map(on: .global()) { data, _ in
            try JSONDecoder().decode(MetaItemResponse.self, from: data).Response
        }
    }

    /// Retrieves the complete `Loadout` for a given `character`. This function is only necessary when using
    /// `Bungie.getCurrentCharacterWithoutLoadout(for:)`.
    /// - SeeAlso: `Bungie.getCurrentCharacterWithoutLoadout(for:)`
    public static func getLoadout(for character: Character) -> Promise<Character.Loadout> {
        let itemPromises = character.equipment.map({ $0.itemHash }).map(Bungie.getItem)

        return firstly {
            when(fulfilled: itemPromises)
        }.map(on: .global()) { rawItems in
            //FIXME: Needs test. Should always return all 3 weapons types and an exotic armor.
            rawItems.filter { $0.isWeapon || $0.isExoticArmor }.enumerated()
        }.mapValues(on: .global()) { offset, rawItem in
            //FIXME: Precondition: Elements of `equipment` and `instances` must be parallel, a condition supplied by Character.init(from:)
            (rawItem, character.equipment[offset], character.itemInstances[offset])
        }.compactMapValues(on: .global()) {
            Item(from: $0, equip: $1, instance: $2)
        }.map(on: .global()) { items in
            Character.Loadout(with: items)
        }
    }
}

/// Comparitor for checking if an item is exotic armor
func ==(lhs: (Item.Slot, Item.Tier), rhs: Item.ExoticArmorComparitor) -> Bool {
    return rhs.0.contains(lhs.0) && lhs.1 == rhs.1
}

//MARK: API Response

struct MetaItemResponse: Decodable {
    let Response: RawItem
}

struct RawItem: Decodable {
    let hash: Int
    let displayProperties: DisplayProperties
    let inventory: Inventory

    var isExoticArmor: Bool {
        return (inventory.bucketTypeHash, inventory.tierTypeHash) == Item.exoticArmor
    }

    var isWeapon: Bool {
        return Item.Slot.weapons.contains(inventory.bucketTypeHash)
    }

    struct DisplayProperties: Decodable {
        let name: String
        let icon: String
    }

    struct Inventory: Decodable {
        let tierTypeHash: Item.Tier
        let bucketTypeHash: Item.Slot
    }
}
