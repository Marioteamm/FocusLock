import Foundation
import SwiftData

@MainActor
final class StreakManager: ObservableObject {

    static let shared = StreakManager()

    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var longestStreak: Int = 0

    private init() {}

    func evaluateOnLaunch(context: ModelContext) {
        let settings = SettingsRepository.shared.ensureSettings(context: context)
        currentStreak = settings.currentStreak
        longestStreak = settings.longestStreak
        finalizeYesterdayIfNeeded(context: context)
    }

    func recordTodayProgress(
        context: ModelContext,
        limits: [AppLimit],
        focusMinutes: Int
    ) {
        let active = limits.filter(\.isEnabled)
        let limitsRespected = checkLimitsRespected(limits: active, on: Date())
        let metGoal = limitsRespected || focusMinutes >= 25
        upsertTodayRecord(
            context: context,
            metGoal: metGoal,
            focusMinutes: focusMinutes,
            limitsRespected: limitsRespected
        )
        refreshStreak(context: context)
    }

    func finalizeYesterdayIfNeeded(context: ModelContext) {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else { return }
        let dayStart = yesterday.startOfDay

        if record(for: dayStart, context: context) != nil { return }

        let limits = (try? context.fetch(FetchDescriptor<AppLimit>())) ?? []
        let active = limits.filter(\.isEnabled)
        let focusMinutes = focusMinutes(on: dayStart, context: context)
        let respected = checkLimitsRespected(limits: active, on: dayStart)
        let metGoal = respected || focusMinutes >= 25

        let record = DailyStreakRecord(
            date: dayStart,
            metGoal: metGoal,
            focusMinutes: focusMinutes,
            limitsRespected: respected
        )
        context.insert(record)
        try? context.save()
        refreshStreak(context: context)
    }

    private func refreshStreak(context: ModelContext) {
        let settings = SettingsRepository.shared.ensureSettings(context: context)
        let records = (try? context.fetch(
            FetchDescriptor<DailyStreakRecord>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
        )) ?? []

        var streak = 0
        var cursor = Date().startOfDay

        for _ in 0..<365 {
            guard let dayRecord = records.first(where: { Calendar.current.isDate($0.date, inSameDayAs: cursor) }) else {
                if Calendar.current.isDateInToday(cursor) { break }
                break
            }
            guard dayRecord.metGoal else { break }
            streak += 1
            guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev.startOfDay
        }

        let previousStreak = settings.currentStreak
        settings.currentStreak = streak
        settings.longestStreak = max(settings.longestStreak, streak)
        settings.lastStreakUpdate = Date()
        settings.updatedAt = Date()
        try? context.save()

        currentStreak = streak
        longestStreak = settings.longestStreak

        MotivationManager.shared.checkMilestone(
            previousStreak: previousStreak,
            newStreak: streak,
            settings: settings,
            context: context
        )
    }

    private func upsertTodayRecord(
        context: ModelContext,
        metGoal: Bool,
        focusMinutes: Int,
        limitsRespected: Bool
    ) {
        let today = Date().startOfDay
        if let existing = record(for: today, context: context) {
            existing.metGoal = existing.metGoal || metGoal
            existing.focusMinutes = max(existing.focusMinutes, focusMinutes)
            existing.limitsRespected = existing.limitsRespected || limitsRespected
        } else {
            context.insert(DailyStreakRecord(
                date: today,
                metGoal: metGoal,
                focusMinutes: focusMinutes,
                limitsRespected: limitsRespected
            ))
        }
        try? context.save()
    }

    private func record(for day: Date, context: ModelContext) -> DailyStreakRecord? {
        let records = (try? context.fetch(FetchDescriptor<DailyStreakRecord>())) ?? []
        return records.first { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    private func focusMinutes(on day: Date, context: ModelContext) -> Int {
        let sessions = (try? context.fetch(FetchDescriptor<FocusSession>())) ?? []
        let totalSeconds = sessions
            .filter { $0.status == .completed }
            .filter { session in
                guard let end = session.endedAt else { return false }
                return Calendar.current.isDate(end, inSameDayAs: day)
            }
            .reduce(0) { $0 + $1.elapsedSeconds }
        return totalSeconds / 60
    }

    private func checkLimitsRespected(limits: [AppLimit], on day: Date) -> Bool {
        guard !limits.isEmpty else { return false }
        let usage = UsageTrackingManager.shared
        return limits.allSatisfy { limit in
            let capMinutes = limit.bonusUsedToday ? limit.effectiveLimitMinutes : limit.limitMinutes
            let used = usage.getUsedTime(bundleId: limit.bundleIdentifier, date: day)
            return used < capMinutes * 60
        }
    }
}
