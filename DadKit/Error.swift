import Foundation

public extension Bungie {
    enum Error: Swift.Error, CustomStringConvertible {

        /// Occurs when downloading and forming a `Character.loadout` fails. See `description` for reasons.
        case characterLoadoutIsInTransientState

        /// Occurs when there are no characters associated with a `Player`.
        case noCharactersAssociatedWithPlayer

        public var description: String {
            switch self {
            case .characterLoadoutIsInTransientState:
                return "DadKit: The requested Character's `loadout` could not be formed because it is missing expected items. This is usually due to the character being new, or in a glitched or transient state resulting in empty weapon slots."
            case .noCharactersAssociatedWithPlayer:
                return "DadKit: The Player requested has not yet created any characters."
            }
        }
    }
}
