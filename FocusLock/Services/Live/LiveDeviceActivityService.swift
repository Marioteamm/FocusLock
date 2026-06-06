import Foundation
import DeviceActivity
import FamilyControls

@MainActor
final class LiveDeviceActivityService: DeviceActivityServicing {

    private let center = DeviceActivityCenter()
    private var groupDefaults: UserDefaults { AppGroupConstants.groupDefaults }

    private var dailySchedule: DeviceActivitySchedule {
        DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
    }

    func stopAllMonitoring(activityNames: [String]) {
        var names = activityNames
        if let tracked = groupDefaults.stringArray(forKey: AppGroupConstants.trackedActivitiesKey) {
            names.append(contentsOf: tracked)
        }
        let unique = Array(Set(names)).map { DeviceActivityName($0) }
        guard !unique.isEmpty else { return }
        center.stopMonitoring(unique)
        groupDefaults.removeObject(forKey: AppGroupConstants.trackedActivitiesKey)
    }

    func stopMonitoring(limitID: UUID) {
        let name = FocusLockActivity.perLimitName(limitID: limitID)
        center.stopMonitoring([name])
        removeTrackedActivity(name.rawValue)
        clearLimitMetadata(limitID: limitID)
    }

    func startMonitoring(configs: [LimitMonitoringConfig]) throws {
        stopAllMonitoring(activityNames: [FocusLockActivity.dailyMonitoringRaw])

        guard !configs.isEmpty else { return }

        var tracked: [String] = []

        for config in configs {
            guard let selection = try? PropertyListDecoder().decode(
                FamilyActivitySelection.self,
                from: config.tokenData
            ) else { continue }

            let apps = selection.applicationTokens
            let categories = selection.categoryTokens
            guard !apps.isEmpty || !categories.isEmpty else { continue }

            let limitMinutes = max(1, config.limitMinutes)
            let warningMinutes = max(1, limitMinutes - 5)

            groupDefaults.set(config.tokenData, forKey: AppGroupConstants.limitTokenKey(limitID: config.limitID))
            groupDefaults.set(config.bundleIdentifier, forKey: AppGroupConstants.limitBundleKey(limitID: config.limitID))
            groupDefaults.set(limitMinutes, forKey: AppGroupConstants.limitMinutesKey(limitID: config.limitID))
            groupDefaults.set(false, forKey: AppGroupConstants.limitBlockedKey(limitID: config.limitID))

            var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
                FocusLockDeviceActivityEvents.warning: DeviceActivityEvent(
                    applications: apps,
                    categories: categories,
                    threshold: DateComponents(minute: warningMinutes)
                ),
                FocusLockDeviceActivityEvents.limit: DeviceActivityEvent(
                    applications: apps,
                    categories: categories,
                    threshold: DateComponents(minute: limitMinutes)
                ),
            ]

            if config.includesBonus {
                events[FocusLockDeviceActivityEvents.bonusLimit] = DeviceActivityEvent(
                    applications: apps,
                    categories: categories,
                    threshold: DateComponents(minute: limitMinutes + 15)
                )
            }

            let activityName = FocusLockActivity.perLimitName(limitID: config.limitID)
            try center.startMonitoring(activityName, during: dailySchedule, events: events)
            tracked.append(activityName.rawValue)
        }

        groupDefaults.set(tracked, forKey: AppGroupConstants.trackedActivitiesKey)
    }

    func startMonitoring(
        selectionData: Data,
        limitMinutes: Int,
        includesBonus: Bool = false
    ) throws {
        let limitID = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()

        try startMonitoring(configs: [
            LimitMonitoringConfig(
                limitID: limitID,
                bundleIdentifier: "focuslock.fallback.selection",
                tokenData: selectionData,
                limitMinutes: limitMinutes,
                includesBonus: includesBonus
            ),
        ])
    }

    func stopMonitoring() {
        stopAllMonitoring(activityNames: [FocusLockActivity.dailyMonitoringRaw])
    }

    private func removeTrackedActivity(_ rawValue: String) {
        var tracked = groupDefaults.stringArray(forKey: AppGroupConstants.trackedActivitiesKey) ?? []
        tracked.removeAll { $0 == rawValue }
        if tracked.isEmpty {
            groupDefaults.removeObject(forKey: AppGroupConstants.trackedActivitiesKey)
        } else {
            groupDefaults.set(tracked, forKey: AppGroupConstants.trackedActivitiesKey)
        }
    }

    private func clearLimitMetadata(limitID: UUID) {
        groupDefaults.removeObject(forKey: AppGroupConstants.limitTokenKey(limitID: limitID))
        groupDefaults.removeObject(forKey: AppGroupConstants.limitBundleKey(limitID: limitID))
        groupDefaults.removeObject(forKey: AppGroupConstants.limitMinutesKey(limitID: limitID))
        groupDefaults.removeObject(forKey: AppGroupConstants.limitBlockedKey(limitID: limitID))
    }
}
