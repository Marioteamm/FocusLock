// Named ManagedSettingsStore shared across app and extensions
import FamilyControls
import ManagedSettings

enum FocusLockManagedSettings {
    static let storeName = ManagedSettingsStore.Name(AppGroupConstants.managedSettingsStoreName)

    static var store: ManagedSettingsStore {
        ManagedSettingsStore(named: storeName)
    }

    static func clearAllShields() {
        let store = store
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    static func applyShield(selection: FamilyActivitySelection) {
        let store = store

        store.shield.applications = selection.applicationTokens.isEmpty
            ? nil
            : selection.applicationTokens

        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(
                selection.categoryTokens,
                except: []
            )
        } else {
            store.shield.applicationCategories = nil
        }

        store.shield.webDomains = selection.webDomainTokens.isEmpty
            ? nil
            : selection.webDomainTokens
    }
}
