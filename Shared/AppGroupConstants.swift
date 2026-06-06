// Shared constants for App Group communication (main app + extensions)
import Foundation

enum AppGroupConstants {
    static let suiteName = "group.com.yourcompany.focuslock"

    static let selectionKey = "focuslock_selection"
    static let lastResetKey = "focuslock_last_reset_date"
    static let warningActiveKey = "focuslock_warning_active"
    static let pendingBonusKey = "focuslock_pending_bonus_extension"
    static let focusSessionActiveKey = "focuslock_focus_session_active"
    static let strictModeKey = "focuslock_strict_mode"
    static let trackedActivitiesKey = "focuslock_tracked_activity_names"
    static let hapticsEnabledKey = "focuslock_haptics_enabled"

    static func limitTokenKey(limitID: UUID) -> String {
        "focuslock_limit_token_\(limitID.uuidString)"
    }

    static func limitBundleKey(limitID: UUID) -> String {
        "focuslock_limit_bundle_\(limitID.uuidString)"
    }

    static func limitMinutesKey(limitID: UUID) -> String {
        "focuslock_limit_minutes_\(limitID.uuidString)"
    }

    static func limitBlockedKey(limitID: UUID) -> String {
        "focuslock_limit_blocked_\(limitID.uuidString)"
    }

    static let managedSettingsStoreName = "focuslock"

    static func dailyBonusKey(for date: Date = Date()) -> String {
        let day = Int(Calendar.current.startOfDay(for: date).timeIntervalSince1970)
        return "focuslock_daily_bonus_\(day)"
    }

    static func usageKey(bundleId: String, date: Date = Date()) -> String {
        let day = Int(Calendar.current.startOfDay(for: date).timeIntervalSince1970)
        return "focuslock_usage_\(bundleId)_\(day)"
    }

    static func blockCountKey(bundleId: String, date: Date = Date()) -> String {
        let day = Int(Calendar.current.startOfDay(for: date).timeIntervalSince1970)
        return "focuslock_blocks_\(bundleId)_\(day)"
    }

    static func totalBlocksKey(date: Date = Date()) -> String {
        let day = Int(Calendar.current.startOfDay(for: date).timeIntervalSince1970)
        return "focuslock_total_blocks_\(day)"
    }

    static var groupDefaults: UserDefaults {
        #if FOCUSLOCK_MOCK_SCREEN_TIME
        return .standard
        #else
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            #if DEBUG
            assertionFailure("FocusLock: App Group \(suiteName) unavailable — check entitlements.")
            #endif
            return .standard
        }
        return defaults
        #endif
    }
}
