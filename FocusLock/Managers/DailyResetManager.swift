// Менеджер щоденного скидання лімітів о 00:00
import Foundation
import SwiftData

@MainActor
final class DailyResetManager: ObservableObject {

    static let shared = DailyResetManager()

    private var timer: Timer?
    private var groupDefaults: UserDefaults { AppGroupConstants.groupDefaults }
    private var isStarted = false

    private init() {}

    func start(modelContext: ModelContext) {
        performResetIfNeeded(modelContext: modelContext)

        guard !isStarted else { return }
        isStarted = true

        timer?.invalidate()
        let newTimer = Timer(timeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.performResetIfNeeded(modelContext: modelContext)
            }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isStarted = false
    }

    func performResetIfNeeded(modelContext: ModelContext) {
        let now = Date()
        let lastReset = getLastResetDate()
        guard !Calendar.current.isDate(now, inSameDayAs: lastReset) else { return }
        performDailyReset(modelContext: modelContext)
    }

    private func performDailyReset(modelContext: ModelContext) {
        do {
            let limits = try modelContext.fetch(FetchDescriptor<AppLimit>())
            UsageHistoryService.shared.archiveTodayUsage(limits: limits, context: modelContext)

            let bundleIds = limits.map(\.bundleIdentifier)
            UsageTrackingManager.shared.clearUsageForToday(bundleIds: bundleIds)

            for limit in limits {
                limit.bonusUsedToday = false
                limit.isCurrentlyBlocked = false
                limit.lastResetDate = Calendar.current.startOfDay(for: Date())
                groupDefaults.set(false, forKey: AppGroupConstants.limitBlockedKey(limitID: limit.id))
            }
            try modelContext.save()

            ManagedSettingsService.shared.unblockAll()
            groupDefaults.removeObject(forKey: AppGroupConstants.warningActiveKey)
            groupDefaults.removeObject(forKey: AppGroupConstants.pendingBonusKey)

            let blockingManager = AppBlockingManager.shared
            blockingManager.loadSavedSelection()
            if !blockingManager.currentSelection.applicationTokens.isEmpty, !limits.isEmpty {
                try blockingManager.startMonitoring(limits: limits)
            }

            saveLastResetDate(Date())
            StreakManager.shared.finalizeYesterdayIfNeeded(context: modelContext)
            StreakManager.shared.evaluateOnLaunch(context: modelContext)
        } catch {
            AppCoordinator.shared.presentError(.monitoringFailed(error.localizedDescription))
        }
    }

    private func getLastResetDate() -> Date {
        let ts = groupDefaults.double(forKey: AppGroupConstants.lastResetKey)
        guard ts > 0 else { return .distantPast }
        return Date(timeIntervalSince1970: ts)
    }

    private func saveLastResetDate(_ date: Date) {
        groupDefaults.set(date.timeIntervalSince1970, forKey: AppGroupConstants.lastResetKey)
    }
}
