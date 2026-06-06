// Monitor Extension — invoked when usage thresholds are reached
import DeviceActivity
import FamilyControls
import Foundation

class DeviceActivityMonitorExtension: DeviceActivity.DeviceActivityMonitor {

    private var sharedDefaults: UserDefaults { AppGroupConstants.groupDefaults }

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        let focusActive = sharedDefaults.bool(forKey: AppGroupConstants.focusSessionActiveKey)
        if !focusActive {
            FocusLockManagedSettings.clearAllShields()
        }

        sharedDefaults.removeObject(forKey: AppGroupConstants.warningActiveKey)
        clearExpiredBonusKeys()
        clearBlockedFlagsForNewDay()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        if !sharedDefaults.bool(forKey: AppGroupConstants.focusSessionActiveKey) {
            FocusLockManagedSettings.clearAllShields()
        }
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)

        let limitID = limitID(from: activity)
        let bundleId = bundleId(for: limitID)
        let limitMinutes = limitMinutes(for: limitID)

        switch event.rawValue {
        case FocusLockDeviceActivityEvents.warningRaw:
            sharedDefaults.set(true, forKey: AppGroupConstants.warningActiveKey)
            if let bundleId, limitMinutes > 0 {
                let warningMinutes = max(1, limitMinutes - 5)
                recordThresholdUsage(bundleId: bundleId, minutes: warningMinutes)
            }

        case FocusLockDeviceActivityEvents.limitRaw:
            sharedDefaults.removeObject(forKey: AppGroupConstants.warningActiveKey)
            if let bundleId, limitMinutes > 0 {
                recordThresholdUsage(bundleId: bundleId, minutes: limitMinutes)
            }
            if let limitID {
                sharedDefaults.set(true, forKey: AppGroupConstants.limitBlockedKey(limitID: limitID))
            }
            applyShield(for: activity)
            incrementBlockCount(bundleId: bundleId)

        case FocusLockDeviceActivityEvents.bonusLimitRaw:
            if let bundleId, limitMinutes > 0 {
                recordThresholdUsage(bundleId: bundleId, minutes: limitMinutes + 15)
            }
            if let limitID {
                sharedDefaults.set(true, forKey: AppGroupConstants.limitBlockedKey(limitID: limitID))
            }
            applyShield(for: activity)
            incrementBlockCount(bundleId: bundleId)

        default:
            break
        }
    }

    private func limitID(from activity: DeviceActivityName) -> UUID? {
        let prefix = "FocusLock.Limit."
        let id = activity.rawValue
        guard id.hasPrefix(prefix) else { return nil }
        return UUID(uuidString: String(id.dropFirst(prefix.count)))
    }

    private func bundleId(for limitID: UUID?) -> String? {
        guard let limitID else { return nil }
        return sharedDefaults.string(forKey: AppGroupConstants.limitBundleKey(limitID: limitID))
    }

    private func limitMinutes(for limitID: UUID?) -> Int {
        guard let limitID else { return 0 }
        let stored = sharedDefaults.integer(forKey: AppGroupConstants.limitMinutesKey(limitID: limitID))
        return stored > 0 ? stored : 60
    }

    private func applyShield(for activity: DeviceActivityName) {
        let activityID = activity.rawValue

        if activityID.hasPrefix("FocusLock.Limit."),
           let limitUUID = UUID(uuidString: String(activityID.dropFirst("FocusLock.Limit.".count))),
           let tokenData = sharedDefaults.data(forKey: AppGroupConstants.limitTokenKey(limitID: limitUUID)),
           let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: tokenData) {
            FocusLockManagedSettings.applyShield(selection: selection)
            return
        }

        guard let selection = FamilyActivitySelectionStorage.load() else { return }
        FocusLockManagedSettings.applyShield(selection: selection)
    }

    private func incrementBlockCount(bundleId: String?) {
        let totalKey = AppGroupConstants.totalBlocksKey()
        sharedDefaults.set(sharedDefaults.integer(forKey: totalKey) + 1, forKey: totalKey)
        if let bundleId {
            let blockKey = AppGroupConstants.blockCountKey(bundleId: bundleId)
            sharedDefaults.set(sharedDefaults.integer(forKey: blockKey) + 1, forKey: blockKey)
        }
    }

    private func recordThresholdUsage(bundleId: String, minutes: Int) {
        let key = AppGroupConstants.usageKey(bundleId: bundleId)
        let seconds = max(0, minutes) * 60
        let current = sharedDefaults.integer(forKey: key)
        if seconds > current {
            sharedDefaults.set(seconds, forKey: key)
        }
    }

    private func clearExpiredBonusKeys() {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else { return }
        sharedDefaults.removeObject(forKey: AppGroupConstants.dailyBonusKey(for: yesterday))
    }

    private func clearBlockedFlagsForNewDay() {
        guard let names = sharedDefaults.stringArray(forKey: AppGroupConstants.trackedActivitiesKey) else { return }
        for name in names where name.hasPrefix("FocusLock.Limit.") {
            let suffix = String(name.dropFirst("FocusLock.Limit.".count))
            if let uuid = UUID(uuidString: suffix) {
                sharedDefaults.removeObject(forKey: AppGroupConstants.limitBlockedKey(limitID: uuid))
            }
        }
    }
}
