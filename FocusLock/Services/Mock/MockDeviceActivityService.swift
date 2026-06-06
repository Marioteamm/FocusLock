import Foundation

/// DEBUG: no DeviceActivityCenter — simulates usage via App Group for UI demos.
@MainActor
final class MockDeviceActivityService: DeviceActivityServicing {

    static let shared = MockDeviceActivityService()

    private var groupDefaults: UserDefaults { AppGroupConstants.groupDefaults }

    private init() {}

    func stopAllMonitoring(activityNames: [String]) {
        _ = activityNames
        groupDefaults.removeObject(forKey: AppGroupConstants.trackedActivitiesKey)
    }

    func stopMonitoring(limitID: UUID) {
        groupDefaults.removeObject(forKey: AppGroupConstants.limitBlockedKey(limitID: limitID))
    }

    func startMonitoring(configs: [LimitMonitoringConfig]) throws {
        var tracked: [String] = []
        for config in configs {
            groupDefaults.set(config.tokenData, forKey: AppGroupConstants.limitTokenKey(limitID: config.limitID))
            groupDefaults.set(config.bundleIdentifier, forKey: AppGroupConstants.limitBundleKey(limitID: config.limitID))
            groupDefaults.set(config.limitMinutes, forKey: AppGroupConstants.limitMinutesKey(limitID: config.limitID))
            groupDefaults.set(false, forKey: AppGroupConstants.limitBlockedKey(limitID: config.limitID))
            tracked.append(FocusLockActivity.perLimitRaw(limitID: config.limitID))
        }
        groupDefaults.set(tracked, forKey: AppGroupConstants.trackedActivitiesKey)
    }

    func startMonitoring(
        selectionData: Data,
        limitMinutes: Int,
        includesBonus: Bool = false
    ) throws {
        _ = includesBonus
        try startMonitoring(configs: [
            LimitMonitoringConfig(
                limitID: UUID(),
                bundleIdentifier: "focuslock.demo.selection",
                tokenData: selectionData,
                limitMinutes: limitMinutes,
                includesBonus: false
            ),
        ])
    }

    func stopMonitoring() {
        stopAllMonitoring(activityNames: [FocusLockActivity.dailyMonitoringRaw])
    }

    /// Demo helper: push sample usage so rings and stats move.
    func simulateUsage(bundleId: String, minutes: Int) {
        let key = AppGroupConstants.usageKey(bundleId: bundleId)
        groupDefaults.set(max(0, minutes) * 60, forKey: key)
    }
}
