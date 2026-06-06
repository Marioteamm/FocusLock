// Usage tracking via App Group (written by monitor extension + read by app)
import Foundation

final class UsageTrackingManager: ObservableObject {

    static let shared = UsageTrackingManager()
    private init() {}

    private var groupDefaults: UserDefaults { AppGroupConstants.groupDefaults }

    func saveUsedTime(bundleId: String, seconds: Int, date: Date = Date()) {
        groupDefaults.set(max(0, seconds), forKey: AppGroupConstants.usageKey(bundleId: bundleId, date: date))
    }

    func getUsedTime(bundleId: String, date: Date = Date()) -> Int {
        groupDefaults.integer(forKey: AppGroupConstants.usageKey(bundleId: bundleId, date: date))
    }

    func addUsedTime(bundleId: String, seconds: Int, date: Date = Date()) {
        saveUsedTime(
            bundleId: bundleId,
            seconds: getUsedTime(bundleId: bundleId, date: date) + seconds,
            date: date
        )
    }

    /// Called from Device Activity monitor when a threshold fires.
    func recordThresholdUsage(bundleId: String, minutes: Int, date: Date = Date()) {
        let seconds = max(0, minutes) * 60
        let current = getUsedTime(bundleId: bundleId, date: date)
        if seconds > current {
            saveUsedTime(bundleId: bundleId, seconds: seconds, date: date)
        }
    }

    func incrementBlockCount(bundleId: String, date: Date = Date()) {
        let key = AppGroupConstants.blockCountKey(bundleId: bundleId, date: date)
        groupDefaults.set(groupDefaults.integer(forKey: key) + 1, forKey: key)
    }

    func getBlockCount(bundleId: String, date: Date = Date()) -> Int {
        groupDefaults.integer(forKey: AppGroupConstants.blockCountKey(bundleId: bundleId, date: date))
    }

    func getTotalBlockCountFromMonitor(date: Date = Date()) -> Int {
        groupDefaults.integer(forKey: AppGroupConstants.totalBlocksKey(date: date))
    }

    func usageProgress(bundleId: String, limitMinutes: Int, date: Date = Date()) -> Double {
        let used = getUsedTime(bundleId: bundleId, date: date)
        let limit = limitMinutes * 60
        guard limit > 0 else { return 0 }
        return min(1.0, Double(used) / Double(limit))
    }

    func remainingMinutes(bundleId: String, limitMinutes: Int, date: Date = Date()) -> Int {
        let used = getUsedTime(bundleId: bundleId, date: date)
        return max(0, (limitMinutes * 60 - used) / 60)
    }

    func isLimitReached(bundleId: String, limitMinutes: Int, date: Date = Date()) -> Bool {
        getUsedTime(bundleId: bundleId, date: date) >= limitMinutes * 60
    }

    func clearUsageForToday(bundleIds: [String]) {
        let today = Date()
        for id in bundleIds {
            groupDefaults.removeObject(forKey: AppGroupConstants.usageKey(bundleId: id, date: today))
            groupDefaults.removeObject(forKey: AppGroupConstants.blockCountKey(bundleId: id, date: today))
        }
        groupDefaults.removeObject(forKey: AppGroupConstants.totalBlocksKey(date: today))
        groupDefaults.removeObject(forKey: AppGroupConstants.warningActiveKey)
    }
}
