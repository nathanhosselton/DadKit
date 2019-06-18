import Foundation

public extension Bungie {
    enum Error: Swift.Error, CustomStringConvertible, LocalizedError {

        /// Occurs when downloading and forming a `Character.loadout` fails. This is usually due to the character being new,
        /// or in a glitched or transient state resulting in empty weapon slots.
        case characterLoadoutIsInTransientState

        /// Occurs when there are no characters associated with a `Player`.
        case noCharactersAssociatedWithPlayer

        /// Occurs when one or more of the character's emblem image paths come back missing or malformed.
        case emblemImageUrlsMissingOrMalformed

        /// Occurs when at least one of the requested character's sets of equipment fields is returned incomplete or
        /// otherwise conflictory to its counterparts. This is a Bungie.net API issue.
        ///
        /// This is possible because the API splits information related to a character's loadout across mulitple endpoints,
        /// requiring consumers to manually stitch together the pieces they need. However, ensuring that these discete
        /// counterparts are always reflective of each other is the responsibility of the API provider and is beyond the
        /// consumer's control.
        ///
        /// This error relates solely to this specific case and is not indicative of a "stitching error"
        /// on the part of this framework.
        case apiReturnedIncongruousCharacterLoadoutInformation

        public var description: String {
            switch self {
            case .characterLoadoutIsInTransientState:
                return "DadKit: The requested Character's `loadout` could not be formed because it is missing expected items. This is usually due to the character being new, or in a glitched or transient state resulting in empty weapon slots."
            case .noCharactersAssociatedWithPlayer:
                return "DadKit: The Player requested has not yet created any characters."
            case .emblemImageUrlsMissingOrMalformed:
                return "DadKit: One or more of the character's emblem image paths came back missing or malformed."
            case .apiReturnedIncongruousCharacterLoadoutInformation:
                return "DadKit: At least one of the requested character's sets of equipment fields was returned incomplete or otherwise conflictory to its counterparts. This is a Bungie.net API issue."
            }
        }

        public var errorDescription: String? {
            //Drop "DadKit: " from the description for presentation to the user.
            return String(description.dropFirst(8))
        }
    }
}
