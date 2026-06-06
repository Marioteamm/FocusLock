import Foundation
import SwiftData
import FamilyControls
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {

    @Published var showingActivityPicker = false
    @Published var showingLimitsManager = false
    @Published var activitySelection = FamilyActivitySelection()
    @Published var showAuthError = false
    @Published var errorMessage = ""
    @Published var loadState: ViewLoadState = .idle
    @Published var selectedLimit: AppLimit?
    @Published var refreshTrigger = false

    private let screenTimeService = ScreenTimeService.shared
    private let blockingManager = AppBlockingManager.shared
    private let usageManager = UsageTrackingManager.shared
    private var refreshTimer: Timer?

    var currentStreak: Int { StreakManager.shared.currentStreak }

    init() {
        activitySelection = blockingManager.currentSelection
        startRefreshTimer()
    }

    deinit { refreshTimer?.invalidate() }

    private func startRefreshTimer() {
        refreshTimer?.invalidate()
        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshTrigger.toggle()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }

    func requestAuthorizationAndShowPicker() async {
        loadState = .loading
        defer { if case .loading = loadState { loadState = .loaded } }

        do {
            try await screenTimeService.requestAuthorization()
            screenTimeService.refreshAuthorizationStatus()
            if screenTimeService.isAuthorized {
                showingActivityPicker = true
                HapticFeedback.notification(.success)
            } else {
                errorMessage = AppError.authorizationDenied.localizedDescription ?? ""
                showAuthError = true
                AppCoordinator.shared.presentError(.authorizationDenied)
            }
        } catch {
            errorMessage = error.localizedDescription
            showAuthError = true
            AppCoordinator.shared.presentError(.authorizationFailed(error.localizedDescription))
        }
    }

    func saveSelection(_ selection: FamilyActivitySelection, context: ModelContext) {
        activitySelection = selection
        blockingManager.saveSelection(selection)
        do {
            let settings = SettingsRepository.shared.settings(context: context)
            try blockingManager.syncLimits(
                from: selection,
                context: context,
                defaultMinutes: settings.defaultLimitMinutes
            )
        } catch {
            AppCoordinator.shared.presentError(.persistenceFailed(error.localizedDescription))
        }
    }

    func startMonitoringAfterSelection(_ selection: FamilyActivitySelection, context: ModelContext) {
        let limits = (try? context.fetch(FetchDescriptor<AppLimit>())) ?? []
        do {
            try blockingManager.startMonitoring(limits: limits)
            StreakManager.shared.recordTodayProgress(
                context: context,
                limits: limits,
                focusMinutes: FocusSessionManager.shared.totalFocusMinutesToday(context: context)
            )
        } catch let error as AppError {
            AppCoordinator.shared.presentError(error)
        } catch {
            AppCoordinator.shared.presentError(.monitoringFailed(error.localizedDescription))
        }
    }

    func syncFromExtensions(context: ModelContext) {
        blockingManager.syncExtensionState(context: context)
        do {
            try blockingManager.applyPendingBonusToLimits(context: context)
        } catch {
            AppCoordinator.shared.presentError(.persistenceFailed(error.localizedDescription))
        }
        refreshTrigger.toggle()
    }

    func useBonusTime(for limit: AppLimit, context: ModelContext) {
        if blockingManager.isStrictModeEnabled {
            AppCoordinator.shared.presentError(.generic("Суворий режим: бонус +15 хв вимкнено."))
            return
        }
        guard !blockingManager.isDailyBonusUsed() else {
            AppCoordinator.shared.presentError(.generic("Бонус +15 хв уже використано сьогодні."))
            return
        }

        blockingManager.markDailyBonusUsed()
        let limits = (try? context.fetch(FetchDescriptor<AppLimit>())) ?? [limit]
        for item in limits {
            item.bonusUsedToday = true
            item.isCurrentlyBlocked = false
            AppGroupConstants.groupDefaults.set(
                false,
                forKey: AppGroupConstants.limitBlockedKey(limitID: item.id)
            )
        }

        blockingManager.removeAllBlocking()
        do {
            try context.save()
            try blockingManager.startMonitoring(limits: limits)
            HapticFeedback.notification(.success)
        } catch {
            AppCoordinator.shared.presentError(.monitoringFailed(error.localizedDescription))
        }
    }

    func usedMinutes(for bundleId: String) -> Int {
        usageManager.getUsedTime(bundleId: bundleId) / 60
    }

    func usageProgress(for bundleId: String, limitMinutes: Int) -> Double {
        usageManager.usageProgress(bundleId: bundleId, limitMinutes: limitMinutes)
    }

    func progressColor(for progress: Double) -> Color {
        switch progress {
        case 0..<0.6: return .focusSuccess
        case 0.6..<0.85: return .focusWarning
        default: return .focusDanger
        }
    }
}
