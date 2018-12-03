import Foundation

// This protocol so that the interfaces of Subclass and Tree may be publicly hidden.
/// The key data points of the `Character.Subclass` and `Character.Subclass.Tree` types.
protocol SubclassRepresentable {

    /// The Subclass object provided for convenience.
    var subclass: Character.Subclass { get }

    /// The common name of the subclass. E.g. "Gunslinger".
    var subclassName: String { get }

    /// The name of the Tree's path for a given a Subclass. E.g. "Way of the Outlaw".
    var subclassPath: String { get }

    /// The relative location of the tree in the in-game UI of the Subclass. E.g. "Top".
    var subclassTree: String { get }

    /// The name of the super associated with the Tree for a given a Subclass. E.g. "Golden Gun".
    var subclassSuper: String { get }

}

public extension Character {

    /// A type representing a Character's subclass.
    public enum Subclass: Decodable, Equatable, Hashable {

        /// A given character's class and subclass combination.
        case solar(Class), arc(Class), void(Class)

        /// Safety case for if/when new subclass combos are created.
        case unknown

        /// The common name of the subclass. E.g. "Gunslinger".
        var name: String {
            switch self {
            case .solar(.hunter):
                return "Gunslinger"
            case .solar(.titan):
                return "Sunbreaker"
            case .solar(.warlock):
                return "Dawnblade"
            case .arc(.hunter):
                return "Arcstrider"
            case .arc(.titan):
                return "Striker"
            case .arc(.warlock):
                return "Stormcaller"
            case .void(.hunter):
                return "Nightstalker"
            case .void(.titan):
                return "Sentinel"
            case .void(.warlock):
                return "Voidwalker"
            default:
                return "It's a mystery…"
            }
        }

        /// A type representing a Character's Subclass tree.
        enum Tree: String, Decodable, Equatable, Hashable {

            /// The location of the tree in the Subclass screen in-game.
            case top = "Top", bottom = "Bottom", middle = "Middle"

            /// Safety case for if/when new subclass trees are created.
            case unknown

            /// The name of the Tree's path for a given a Subclass. E.g. "Way of the Outlaw".
            func path(for subclass: Subclass) -> String {
                switch (subclass, self) {
                case (.solar(.hunter), .top):
                    return "Way of the Outlaw"
                case (.solar(.hunter), .bottom):
                    return "Way of the Sharpshooter"
                case (.solar(.hunter), .middle):
                    return "Way of a Thousand Cuts"
                case (.solar(.titan), .top):
                    return "Code of the Fire-Forged"
                case (.solar(.titan), .bottom):
                    return "Code of the Siegebreaker"
                case (.solar(.titan), .middle):
                    return "Code of the Devastator"
                case (.solar(.warlock), .top):
                    return "Attunement of Sky"
                case (.solar(.warlock), .bottom):
                    return "Attunement of Flame"
                case (.solar(.warlock), .middle):
                    return "Attunement of Grace"
                case (.arc(.hunter), .top):
                    return "Way of the Warrior"
                case (.arc(.hunter), .bottom):
                    return "Way of the Wind"
                case (.arc(.hunter), .middle):
                    return "Way of the Current"
                case (.arc(.titan), .top):
                    return "Code of the Earthshaker"
                case (.arc(.titan), .bottom):
                    return "Code of the Juggernaut"
                case (.arc(.titan), .middle):
                    return "Code of the Missile"
                case (.arc(.warlock), .top):
                    return "Attunement of Conduction"
                case (.arc(.warlock), .bottom):
                    return "Attunement of the Elements"
                case (.arc(.warlock), .middle):
                    return "Attunement of Control"
                case (.void(.hunter), .top):
                    return "Way of the Trapper"
                case (.void(.hunter), .bottom):
                    return "Way of the Pathfinder"
                case (.void(.hunter), .middle):
                    return "Way of the Wraith"
                case (.void(.titan), .top):
                    return "Code of the Protector"
                case (.void(.titan), .bottom):
                    return "Code of the Aggressor"
                case (.void(.titan), .middle):
                    return "Code of the Commander"
                case (.void(.warlock), .top):
                    return "Attunement of Chaos"
                case (.void(.warlock), .bottom):
                    return "Attunement of Hunger"
                case (.void(.warlock), .middle):
                    return "Attunement of Fission"
                default:
                    return "It's a mystery…"
                }
            }

            /// The name of the super associated with the Tree for a given a Subclass. E.g. "Golden Gun".
            func `super`(for subclass: Subclass) -> String {
                switch (self, subclass) {
                case (.middle, .solar(.hunter)):
                    return "Blade Barrage"
                case (_, .solar(.hunter)):
                    return "Golden Gun"
                case (.middle, solar(.titan)):
                    return "Burning Maul"
                case (_, solar(.titan)):
                    return "Hammer of Sol"
                case (.middle, .solar(.warlock)):
                    return "Well of Radiance"
                case (_, .solar(.warlock)):
                    return "Daybreak"
                case (.middle, .arc(.hunter)):
                    return "Whirlwind Guard"
                case (_, .arc(.hunter)):
                    return "Arc Staff"
                case (.middle, .arc(.titan)):
                    return "Thundercrash"
                case (_, .arc(.titan)):
                    return "Fists of Havok"
                case (.middle, .arc(.warlock)):
                    return "Chaos Reach"
                case (_, .arc(.warlock)):
                    return "Stormtrance"
                case (.middle, .void(.hunter)):
                    return "Spectral Blades"
                case (_, .void(.hunter)):
                    return "Shadow Shot"
                case (.middle, .void(.titan)):
                    return "Banner Shield"
                case (_, .void(.titan)):
                    return "Sentinel Shield"
                case (.middle, .void(.warlock)):
                    return "Nova Warp"
                case (_, .void(.warlock)):
                    return "Nova Bomb"
                default:
                    return "It's a mystery…"
                }
            }

            /// Convenience constructor for decoding from JSON.
            internal init(withNodes nodes: [Int]) {
                switch nodes {
                case 11...14:
                    self = .top
                case 15...18:
                    self = .bottom
                case 20...23:
                    self = .middle
                default:
                    self = .unknown
                }
            }

            /// - Warning: `Subclass.Tree`'s declared conformance to `Decodable` is purely for the compiler.
            public init(from decoder: Decoder) throws {
                fatalError("DadKit: `Subclass.Tree` is decoded manually within the custom init of `Character` and should not be allowed to decode automatically.")
            }

        }

        /// Custom decodable implementation
        /// - Note: This is unusable due to the response format of the data requiring custom decodable on `Character`
        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(Int.self)
            self = Subclass(withHash: raw)
        }

        ///Convenience constructor leveraging indirect type
        internal init(withHash hash: Int?) {
            switch SubclassHash(with: hash) {
            case .nightstalker:
                self = .void(.hunter)
            case .arcstrider:
                self = .arc(.hunter)
            case .gunslinger:
                self = .solar(.hunter)
            case .sentinel:
                self = .void(.titan)
            case .striker:
                self = .arc(.titan)
            case .sunbreaker:
                self = .solar(.titan)
            case .voidwalker:
                self = .void(.warlock)
            case .stormcaller:
                self = .arc(.warlock)
            case .dawnblade:
                self = .solar(.warlock)
            default:
                self = .unknown
            }
        }

    }

}

/// Convenience indirect type for construction of the proper type.
enum SubclassHash: Int {
    case nightstalker = 465529128
    case arcstrider = 2682165958
    case gunslinger = 3745224476
    case sentinel = 1694254940
    case striker = 2307176982
    case sunbreaker = 2303449158
    case voidwalker = 3774745298
    case stormcaller = 73217278
    case dawnblade = 213798046
    case other

    typealias RawValue = Int

    init(with rawValue: Int?) {
        guard let raw = rawValue else { self = .other; return }
        self = SubclassHash(rawValue: raw) ?? .other
    }
}

//Used for pattern matching in the `init(withNodes:)` constructor of `Subclass.Tree`.
private func ~= (pattern: ClosedRange<Int>, value: [Int]) -> Bool {
    return value.first(where: pattern.contains) != nil
}
