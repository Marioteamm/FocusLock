import Foundation

/// String activity IDs — safe for Debug (no DeviceActivity import).
enum FocusLockActivity {
    static let dailyMonitoringRaw = "FocusLock.DailyMonitoring"

    static func perLimitRaw(limitID: UUID) -> String {
        "FocusLock.Limit.\(limitID.uuidString)"
    }
}

enum FocusLockDeviceActivityEvents {
    static let warningRaw = "FocusLock.Warning"
    static let limitRaw = "FocusLock.Limit"
    static let bonusLimitRaw = "FocusLock.BonusLimit"
}

#if !FOCUSLOCK_MOCK_SCREEN_TIME
import DeviceActivity

extension FocusLockActivity {
    static var dailyMonitoring: DeviceActivityName {
        DeviceActivityName(dailyMonitoringRaw)
    }

    static func perLimitName(limitID: UUID) -> DeviceActivityName {
        DeviceActivityName(perLimitRaw(limitID: limitID))
    }
}

extension FocusLockDeviceActivityEvents {
    static var warning: DeviceActivityEvent.Name { DeviceActivityEvent.Name(warningRaw) }
    static var limit: DeviceActivityEvent.Name { DeviceActivityEvent.Name(limitRaw) }
    static var bonusLimit: DeviceActivityEvent.Name { DeviceActivityEvent.Name(bonusLimitRaw) }
}
#endif
