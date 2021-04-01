import Foundation
import PromiseKit
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

    /// The ammo type used by this item if it is a weapon, i.e. primary, special, heavy.
    public let ammoType: AmmoType

    /// The power level of this item.
    public let power: Int

    /// The rarity tier of this item, e.g. Legendary.
    public let tier: Tier

    /// A flag that inidicates whether this item is fully masterworked and should be displayed accordingly.
    public let isFullyMasterworked: Bool

    /// The inventory slot in which this item resides, e.g. Kinetic, Helmet, etc.
    public let slot: Slot

    internal(set) public var mods: [Mod]? = nil
    internal let socketIndexes: [RawItem.SocketMeta.SocketCategory: [Int]]?

    public let itemHash: Int
    public let itemInstanceId: Int

    /// Indicates that the item's manifest information is not yet in the public API. All fields on the item will
    /// still be present, but are not guaranteed to contain useful information. Display the item accordingly.
    public let isRedacted: Bool

    /// A type representing the various types of damage that a weapon can deal.
    public enum DamageType: Int, Decodable {
        case none, kinetic, arc, solar, void, raid, stasis
    }

    /// A type representing the levels of rarity associated with items.
    public enum Tier: Int, Decodable {
        /// Irrelevant tier. Exists for `Decodable` conformance.
        case unknown, currency
        /// Item rarity signifier.
        case common, uncommon, rare, legendary, exotic
    }

    /// A type representing the inventory slots in which items may reside.
    public enum Slot: Int, Decodable {
        /// The slot which represents the chosen subclass.
        case subclass = 3284755031

        /// Weapon slot.
        case kinetic = 1498876634, energy = 2465295065, heavy = 953998645

        /// Armor slot.
        case helmet = 3448274439, arms = 3551918588, chest = 14239492, legs = 20886954, classArmor = 1585787867

        /// Consumables, cosmetics, and other items we're currently ignoring.
        case other

        internal static var armor: [Slot] { return [.helmet, .arms, .chest, .legs, .classArmor] }
        internal static var weapons: [Slot] { return  [.kinetic, .energy, .heavy] }
        internal static var weaponsAndArmor: [Slot] { return armor + weapons }

        /// Custom Decodable conformance
        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(Int.self)
            self = Slot(rawValue: raw) ?? .other
        }
    }

    public enum AmmoType: Int, Decodable {
        /// Used when the item is not a weapon.
        case none
        /// Indicates the weapon uses primary (white) ammo.
        case primary
        /// Indicates the weapon uses special (green) ammo.
        case special
        /// Indicates the weapon uses heavy (purple) ammo.
        case heavy
    }

    /// Builds the fully constructed `Item` from its various components across the API.
    fileprivate init?(from rawItem: RawItem, equip: CharacterEquipment.Equipment.Item, instance: ItemComponents.Instances.Item) {
        // I'm assuming this will never actually be `nil` by the time the item instance arrives at this point
        guard let powerLevel = instance.primaryStat?.value else { return nil }

        name = rawItem.displayProperties.name
        icon = URL(string: "https://bungie.net" + rawItem.displayProperties.icon)!
        damageType = instance.damageType
        ammoType = rawItem.equippingBlock?.ammoType ?? .none //This will be nil if item is redacted
        power = powerLevel
        tier = rawItem.inventory.tierType
        isFullyMasterworked = equip.state.contains(.masterwork)
        slot = rawItem.inventory.bucketTypeHash
        isRedacted = rawItem.redacted
        itemHash = rawItem.hash
        itemInstanceId = Int(equip.itemInstanceId) ?? 0

        if let armorSocketCategory = rawItem.sockets?.socketCategories.first(where: { $0.socketCategoryHash == .armorMods }) {
            socketIndexes = [
                .armorMods: armorSocketCategory.socketIndexes
            ]
        } else {
            socketIndexes = nil
        }
    }

}

extension Item: Equatable
{}

extension Item: Hashable
{}

public struct Mod {

    public let name: String
    public let icon: URL

    /// Builds the fully constructed `Item` from its various components across the API.
    fileprivate init?(rawItem: RawItem) {
        name = rawItem.displayProperties.name
        icon = URL(string: "https://bungie.net" + rawItem.displayProperties.icon)!
    }

}

extension Mod: Equatable, Hashable {}

//MARK: API Request

extension Bungie {
    /// Gets a `RawItem` representing static item information from Destiny item manifest with the provided item hash.
    private static func getItem(with id: Int) -> Promise<(Int, RawItem)> {
        let request = API.getItem(withId: String(id)).request

        return firstly {
            Bungie.send(request)
        }.map(on: .global()) { data, _ in
            (id, try JSONDecoder().decode(MetaItemResponse.self, from: data).Response)
        }
    }

    /// Retrieves the complete `Loadout` for a given `character`. This function is only necessary when using
    /// `Bungie.getCurrentCharacterWithoutLoadout(for:)`.
    /// - SeeAlso: `Bungie.getCurrentCharacterWithoutLoadout(for:)`
    public static func getLoadout(for character: Character) -> Promise<Character.Loadout> {
        let itemPromises = character.equipment.keys.map(Bungie.getItem)

        return firstly {
            when(fulfilled: itemPromises)
        }.map { rawItems in
            rawItems.filter { $1.isWeapon || $1.isArmor }
        }.compactMapValues { itemHash, rawItem in
            guard let equip = character.equipment[itemHash],
                let instance = character.itemInstances[itemHash]
                else { throw Bungie.Error.apiReturnedIncongruousCharacterLoadoutInformation }
            return Item(from: rawItem, equip: equip, instance: instance)
        }.then { items in
            getArmorMods(for: character, items: items)
        }.map(on: .global()) { items in
            Character.Loadout(with: items)
        }
    }

    /// Retrieves the armor mods for each armor item supplied and returns them. This function is only necessary when using
    /// `Bungie.getCurrentCharacterWithoutLoadout(for:)`.
    /// - SeeAlso: `Bungie.getCurrentCharacterWithoutLoadout(for:)`
    internal static func getArmorMods(for character: Character, items: [Item]) -> Promise<[Item]> {
        let armorItems = items.filter { Item.Slot.armor.contains($0.slot) }

        // For each of the sockets on the item instance, get all the equipped mods.
        let armorModItemPromises = armorItems.compactMap { armorItem -> Promise<(Int, [Mod])>? in
            guard let sockets = character.sockets[armorItem.itemInstanceId], let armorModSocketIndexes = armorItem.socketIndexes?[.armorMods] else { return nil }

            let armorModSockets = armorModSocketIndexes.compactMap { sockets[$0] }
            let itemPromises = armorModSockets.filter { $0.isEnabled && $0.isVisible }.compactMap { $0.plugHash }.map(Bungie.getItem)

            return
                when(fulfilled: itemPromises)
                .compactMap { rawModItems in
                    return (armorItem.itemInstanceId, rawModItems.compactMap { Mod(rawItem: $0.1) })
                }
        }

        return firstly {
            when(fulfilled: armorModItemPromises)
        }.map { armorItemModItemsPairs in
            var updatedItems = items
            // Update each item with the available armor mods for it.
            for armorItemModItemsPair in armorItemModItemsPairs {
                if let itemToUpdateIndex = updatedItems.firstIndex(where: { $0.itemInstanceId == armorItemModItemsPair.0 }) {
                    var updatedItem = updatedItems[itemToUpdateIndex]
                    updatedItem.mods = armorItemModItemsPair.1
                    updatedItems[itemToUpdateIndex] = updatedItem
                }
            }

            return updatedItems
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
    let equippingBlock: EquippingBlock?
    let redacted: Bool
    let talentGrid: TalentGrid?
    let sockets: SocketMeta?

    var isExoticArmor: Bool {
        return (inventory.bucketTypeHash, inventory.tierType) == Item.exoticArmor
    }

    var isArmor: Bool {
        return Item.Slot.armor.contains(inventory.bucketTypeHash)
    }

    var isWeapon: Bool {
        return Item.Slot.weapons.contains(inventory.bucketTypeHash)
    }

    var isSubclass: Bool {
        return Item.Slot.subclass == inventory.bucketTypeHash
    }

    struct DisplayProperties: Decodable {
        let name: String
        let icon: String
    }

    struct Inventory: Decodable {
        let tierType: Item.Tier
        let bucketTypeHash: Item.Slot
    }

    struct EquippingBlock: Decodable {
        let ammoType: Item.AmmoType
    }

    struct TalentGrid: Decodable {
        let talentGridHash: Int
        let buildName: String?
        let hudDamageType: Item.DamageType
    }

    struct SocketMeta: Decodable {
        enum SocketCategory: Int, Decodable {
            case armorMods = 590099826
            case unknown = 9999999999

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let value = try container.decode(Int.self)
                self = SocketCategory(rawValue: value) ?? .unknown
            }
        }

        let socketEntries: [Socket]
        let socketCategories: [SocketCategoryMeta]

        var armorModSocketEntries: [Socket] {
            guard let armorModsSocketDescription = socketCategories.first(where: { $0.socketCategoryHash == .armorMods }) else {
                return [Socket]()
            }

            return armorModsSocketDescription.socketIndexes.compactMap { i in
                return socketEntries[i]
            }
        }

        struct Socket: Decodable {
            let socketTypeHash: Int
            let singleInitialItemHash: Int
        }

        struct SocketCategoryMeta: Decodable {
            let socketCategoryHash: SocketCategory
            let socketIndexes: [Int]
        }
    }

}
