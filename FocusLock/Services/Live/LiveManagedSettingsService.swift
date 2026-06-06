import Foundation
import FamilyControls
import ManagedSettings

final class LiveManagedSettingsService: ManagedSettingsServicing {

    func blockApps(selection: FamilyActivitySelection) {
        FocusLockManagedSettings.applyShield(selection: selection)
    }

    func blockApplicationTokens(_ tokens: Set<ApplicationToken>) {
        guard !tokens.isEmpty else { return }
        var selection = FamilyActivitySelection()
        selection.applicationTokens = tokens
        FocusLockManagedSettings.applyShield(selection: selection)
    }

    func unblockAll() {
        FocusLockManagedSettings.clearAllShields()
    }

    var hasActiveBlocks: Bool {
        let apps = FocusLockManagedSettings.store.shield.applications
        guard let apps else { return false }
        return !apps.isEmpty
    }
}
