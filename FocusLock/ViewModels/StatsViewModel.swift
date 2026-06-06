import Foundation
import SwiftData

@MainActor
final class StatsViewModel: ObservableObject {

    @Published var totalUsedSeconds: Int = 0
    @Published var totalBlockCount: Int = 0
    @Published var totalBonusCount: Int = 0
    @Published var totalFocusMinutes: Int = 0
    @Published var weeklyChart: [DayUsageSummary] = []
    @Published var insightMessage: String = ""
    @Published var loadState: ViewLoadState = .idle

    private let usageManager = UsageTrackingManager.shared
    private let history = UsageHistoryService.shared

    struct DayUsageSummary: Identifiable {
        let id = UUID()
        let weekday: String
        let minutes: Int
        let metGoal: Bool
        let isToday: Bool
    }

    func refresh(limits: [AppLimit], context: ModelContext) {
        loadState = .loading

        let active = limits.filter(\.isEnabled)
        var seconds = 0
        var blocks = 0

        for limit in active {
            seconds += usageManager.getUsedTime(bundleId: limit.bundleIdentifier)
            blocks += usageManager.getBlockCount(bundleId: limit.bundleIdentifier)
        }

        let monitorBlocks = usageManager.getTotalBlockCountFromMonitor()
        if monitorBlocks > blocks { blocks = monitorBlocks }

        totalUsedSeconds = seconds
        totalBlockCount = blocks
        totalBonusCount = AppBlockingManager.shared.isDailyBonusUsed() ? 1 : 0
        totalFocusMinutes = FocusSessionManager.shared.totalFocusMinutesToday(context: context)
        weeklyChart = buildWeeklyChart(context: context, limits: active)
        insightMessage = buildInsight(limits: active)

        StreakManager.shared.recordTodayProgress(
            context: context,
            limits: active,
            focusMinutes: totalFocusMinutes
        )

        loadState = .loaded
    }

    var formattedTotalTime: String {
        let hours = totalUsedSeconds / 3600
        let minutes = (totalUsedSeconds % 3600) / 60
        if hours > 0 { return "\(hours) год \(minutes) хв" }
        return "\(minutes) хв"
    }

    var timeUntilReset: String {
        Date().formattedTimeUntilReset
    }

    func usedTimeString(for limit: AppLimit) -> String {
        let minutes = usageManager.getUsedTime(bundleId: limit.bundleIdentifier) / 60
        return "\(minutes) хв"
    }

    func usageProgress(for limit: AppLimit) -> Double {
        let used = usageManager.getUsedTime(bundleId: limit.bundleIdentifier)
        let total = limit.effectiveLimitMinutes * 60
        guard total > 0 else { return 0 }
        return min(1.0, Double(used) / Double(total))
    }

    private func buildInsight(limits: [AppLimit]) -> String {
        guard !limits.isEmpty else {
            return "Додайте додатки, щоб отримувати персональні поради."
        }

        let overLimit = limits.filter { usageProgress(for: $0) >= 1 }.count
        if overLimit > 0 {
            return "Сьогодні \(overLimit) додатків досягли ліміту. Спробуйте 25-хвилинну фокус-сесію завтра."
        }

        if totalFocusMinutes >= 25 {
            return "Чудова робота! Ви вже провели \(totalFocusMinutes) хв у фокусі — серія зростає."
        }

        let avgProgress = limits.map { usageProgress(for: $0) }.reduce(0, +) / Double(limits.count)
        if avgProgress < 0.5 {
            return "Ви використали менше половини лімітів — чудовий баланс."
        }
        return "Ви на \(Int(avgProgress * 100))% денного бюджету. Ще трохи — і варто зробити паузу."
    }

    private func buildWeeklyChart(context: ModelContext, limits: [AppLimit]) -> [DayUsageSummary] {
        let records = (try? context.fetch(FetchDescriptor<DailyStreakRecord>())) ?? []
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "EE"

        return (0..<7).reversed().compactMap { offset -> DayUsageSummary? in
            guard let day = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let start = day.startOfDay
            let record = records.first { Calendar.current.isDate($0.date, inSameDayAs: start) }
            let minutes = history.totalMinutes(on: start, limits: limits, context: context)

            return DayUsageSummary(
                weekday: formatter.string(from: start),
                minutes: minutes,
                metGoal: record?.metGoal ?? false,
                isToday: Calendar.current.isDateInToday(start)
            )
        }
    }
}
