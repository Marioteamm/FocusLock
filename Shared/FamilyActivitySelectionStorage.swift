// Codable persistence for FamilyActivitySelection via App Group
import Foundation
import FamilyControls
import ManagedSettings

enum FamilyActivitySelectionStorage {

    @discardableResult
    static func save(
        _ selection: FamilyActivitySelection,
        to defaults: UserDefaults = AppGroupConstants.groupDefaults
    ) -> Bool {
        do {
            let data = try PropertyListEncoder().encode(selection)
            defaults.set(data, forKey: AppGroupConstants.selectionKey)
            return true
        } catch {
            return false
        }
    }

    static func load(from defaults: UserDefaults = AppGroupConstants.groupDefaults) -> FamilyActivitySelection? {
        guard let data = defaults.data(forKey: AppGroupConstants.selectionKey) else {
            return nil
        }

        if let decoded = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
            return decoded
        }

        return nil
    }

    /// Encodes a single application token as a one-app FamilyActivitySelection.
    static func encodeSingleToken(_ token: ApplicationToken) -> Data? {
        var selection = FamilyActivitySelection()
        selection.applicationTokens = [token]
        return try? PropertyListEncoder().encode(selection)
    }

    static func decodeSingleToken(from data: Data) -> ApplicationToken? {
        guard let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return nil
        }
        return selection.applicationTokens.first
    }
}
