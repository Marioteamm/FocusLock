import Foundation
import FamilyControls
import ManagedSettings

/// DEBUG: shields are not applied — UI-only blocking state.
final class MockManagedSettingsService: ManagedSettingsServicing {

    static let shared = MockManagedSettingsService()

    private(set) var hasActiveBlocks = false

    private init() {}

    func blockApps(selection: FamilyActivitySelection) {
        hasActiveBlocks = !selection.applicationTokens.isEmpty
    }

    func blockApplicationTokens(_ tokens: Set<ApplicationToken>) {
        hasActiveBlocks = !tokens.isEmpty
    }

    func unblockAll() {
        hasActiveBlocks = false
    }
}
