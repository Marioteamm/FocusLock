import Foundation
import SwiftData

@MainActor
final class UsageHistoryService {

    static let shared = UsageHistoryService()
    private init() {}

    /// Archives today's usage into `DailyStats` before midnight reset.
    func archiveTodayUsage(limits: [AppLimit], context: ModelContext) {
        let today = Date().startOfDay
        let usage = UsageTrackingManager.shared
        let existing = (try? context.fetch(FetchDescriptor<DailyStats>())) ?? []

        for limit in limits {
            let used = usage.getUsedTime(bundleId: limit.bundleIdentifier)
            let blocks = usage.getBlockCount(bundleId: limit.bundleIdentifier)

            if let row = existing.first(where: {
                $0.bundleIdentifier == limit.bundleIdentifier
                    && Calendar.current.isDate($0.date, inSameDayAs: today)
            }) {
                row.usedSeconds = max(row.usedSeconds, used)
                row.blockCount = max(row.blockCount, blocks)
                row.bonusUsed = limit.bonusUsedToday
            } else {
                context.insert(DailyStats(
                    date: today,
                    bundleIdentifier: limit.bundleIdentifier,
                    appName: limit.appName,
                    usedSeconds: used,
                    blockCount: blocks,
                    bonusUsed: limit.bonusUsedToday
                ))
            }
        }
        try? context.save()
    }

    func totalMinutes(on day: Date, limits: [AppLimit], context: ModelContext) -> Int {
        let start = day.startOfDay
        let stats = (try? context.fetch(FetchDescriptor<DailyStats>())) ?? []
        let dayStats = stats.filter { Calendar.current.isDate($0.date, inSameDayAs: start) }

        if !dayStats.isEmpty {
            return dayStats.reduce(0) { $0 + $1.usedMinutes }
        }

        guard Calendar.current.isDateInToday(start) else { return 0 }

        return limits
            .filter(\.isEnabled)
            .reduce(0) { sum, limit in
                sum + UsageTrackingManager.shared.getUsedTime(bundleId: limit.bundleIdentifier) / 60
            }
    }
}
