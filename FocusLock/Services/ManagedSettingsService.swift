// ManagedSettings blocking (live + DEBUG mock delegate)
import Foundation
import FamilyControls
import ManagedSettings

final class ManagedSettingsService: ManagedSettingsServicing {

    static let shared = ManagedSettingsService()

    private let backend: any ManagedSettingsServicing

    private init() {
        #if FOCUSLOCK_MOCK_SCREEN_TIME
        backend = MockManagedSettingsService.shared
        #else
        backend = LiveManagedSettingsService()
        #endif
    }

    func blockApps(selection: FamilyActivitySelection) {
        backend.blockApps(selection: selection)
    }

    func blockApplicationTokens(_ tokens: Set<ApplicationToken>) {
        backend.blockApplicationTokens(tokens)
    }

    func unblockAll() {
        backend.unblockAll()
    }

    var hasActiveBlocks: Bool {
        backend.hasActiveBlocks
    }
}
