import Foundation
import SwiftData
import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {

    @Published var showOnboarding = false
    @Published var globalError: AppError?
    @Published var loadState: ViewLoadState = .idle

    static let shared = AppCoordinator()

    private init() {}

    func bootstrap(modelContext: ModelContext) {
        loadState = .loading
        defer { loadState = .loaded }

        #if FOCUSLOCK_MOCK_SCREEN_TIME
        if FocusLockConfig.useMockScreenTime {
            ScreenTimeService.shared.refreshAuthorizationStatus()
            let settings = SettingsRepository.shared.ensureSettings(context: modelContext)
            showOnboarding = !settings.hasCompletedOnboarding
            DailyResetManager.shared.start(modelContext: modelContext)
            FocusSessionManager.shared.bind(context: modelContext)
            if settings.hasCompletedOnboarding {
                restoreMonitoringIfNeeded(context: modelContext)
            }
            return
        }
        #endif

        ScreenTimeService.shared.refreshAuthorizationStatus()

        let settings = SettingsRepository.shared.ensureSettings(context: modelContext)
        showOnboarding = !settings.hasCompletedOnboarding

        let defaults = AppGroupConstants.groupDefaults
        defaults.set(settings.hapticsEnabled, forKey: AppGroupConstants.hapticsEnabledKey)
        defaults.set(settings.strictModeEnabled, forKey: AppGroupConstants.strictModeKey)

        DailyResetManager.shared.start(modelContext: modelContext)

        AppBlockingManager.shared.loadSavedSelection()
        do {
            try AppBlockingManager.shared.applyPendingBonusToLimits(context: modelContext)
        } catch {
            presentError(.persistenceFailed(error.localizedDescription))
        }
        AppBlockingManager.shared.syncExtensionState(context: modelContext)

        StreakManager.shared.evaluateOnLaunch(context: modelContext)
        FocusSessionManager.shared.bind(context: modelContext)

        if settings.hasCompletedOnboarding {
            restoreMonitoringIfNeeded(context: modelContext)
        }
    }

    func refreshOnForeground(modelContext: ModelContext) {
        ScreenTimeService.shared.refreshAuthorizationStatus()
        AppBlockingManager.shared.syncExtensionState(context: modelContext)
        do {
            try AppBlockingManager.shared.applyPendingBonusToLimits(context: modelContext)
        } catch {
            presentError(.persistenceFailed(error.localizedDescription))
        }
        DailyResetManager.shared.performResetIfNeeded(modelContext: modelContext)
    }

    private func restoreMonitoringIfNeeded(context: ModelContext) {
        guard ScreenTimeService.shared.isAuthorized else { return }
        let limits = (try? context.fetch(FetchDescriptor<AppLimit>())) ?? []
        guard !limits.isEmpty else { return }
        do {
            try AppBlockingManager.shared.startMonitoring(limits: limits)
        } catch {
            presentError(.monitoringFailed(error.localizedDescription))
        }
    }

    func completeOnboarding(context: ModelContext) {
        let settings = SettingsRepository.shared.ensureSettings(context: context)
        settings.hasCompletedOnboarding = true
        settings.updatedAt = Date()
        do {
            try context.save()
        } catch {
            presentError(.persistenceFailed(error.localizedDescription))
        }
        withAnimation(.focusSpring) {
            showOnboarding = false
        }
        restoreMonitoringIfNeeded(context: context)
        HapticFeedback.notification(.success)
    }

    func presentError(_ error: AppError) {
        globalError = error
        HapticFeedback.notification(.error)
    }

    func clearError() {
        globalError = nil
    }
}
