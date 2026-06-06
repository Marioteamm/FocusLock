import Foundation
import FamilyControls
import ManagedSettings

protocol ManagedSettingsServicing: AnyObject {
    func blockApps(selection: FamilyActivitySelection)
    func blockApplicationTokens(_ tokens: Set<ApplicationToken>)
    func unblockAll()
    var hasActiveBlocks: Bool { get }
}
