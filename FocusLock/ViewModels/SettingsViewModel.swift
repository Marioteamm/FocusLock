import Foundation
import SwiftData

@MainActor
final class SettingsViewModel: ObservableObject {

    @Published var loadState: ViewLoadState = .idle

    let availableLimits = [15, 30, 45, 60, 90, 120]

    func settings(context: ModelContext) -> AppSettings {
        SettingsRepository.shared.ensureSettings(context: context)
    }

    func limitLabel(_ minutes: Int) -> String {
        switch minutes {
        case 60: return "1 год"
        case 90: return "1 год 30 хв"
        case 120: return "2 год"
        default: return "\(minutes) хв"
        }
    }

    func updateDefaultLimit(_ minutes: Int, context: ModelContext) {
        let s = settings(context: context)
        s.defaultLimitMinutes = minutes
        s.updatedAt = Date()
        try? context.save()
        HapticFeedback.selection()
    }

    func toggleHaptics(_ enabled: Bool, context: ModelContext) {
        settings(context: context).hapticsEnabled = enabled
        AppGroupConstants.groupDefaults.set(enabled, forKey: AppGroupConstants.hapticsEnabledKey)
        try? context.save()
        if enabled { HapticFeedback.impact(.light) }
    }

    func toggleStrictMode(_ enabled: Bool, context: ModelContext) {
        let s = settings(context: context)
        s.strictModeEnabled = enabled
        s.updatedAt = Date()
        AppGroupConstants.groupDefaults.set(enabled, forKey: AppGroupConstants.strictModeKey)
        try? context.save()
        persistAndRestartMonitoring(context: context)
    }

    func toggleFocusBlocking(_ enabled: Bool, context: ModelContext) {
        settings(context: context).focusSessionBlocksApps = enabled
        try? context.save()
    }

    func updateLimit(for limit: AppLimit, minutes: Int, context: ModelContext) {
        limit.limitMinutes = minutes
        persistAndRestartMonitoring(context: context)
    }

    func deleteLimit(_ limit: AppLimit, context: ModelContext) {
        AppBlockingManager.shared.stopMonitoring(for: limit)
        context.delete(limit)
        persistAndRestartMonitoring(context: context)
    }

    func deleteAllLimits(context: ModelContext) {
        let limits = (try? context.fetch(FetchDescriptor<AppLimit>())) ?? []
        AppBlockingManager.shared.stopAllMonitoring(for: limits)
        limits.forEach { context.delete($0) }
        AppBlockingManager.shared.removeAllBlocking()
        try? context.save()
    }

    func resetOnboarding(context: ModelContext) {
        settings(context: context).hasCompletedOnboarding = false
        try? context.save()
        AppCoordinator.shared.showOnboarding = true
    }

    private func persistAndRestartMonitoring(context: ModelContext) {
        do {
            try context.save()
            let limits = try context.fetch(FetchDescriptor<AppLimit>())
            if limits.isEmpty {
                AppBlockingManager.shared.stopMonitoring()
                AppBlockingManager.shared.removeAllBlocking()
            } else {
                try AppBlockingManager.shared.startMonitoring(limits: limits)
            }
        } catch let error as AppError {
            AppCoordinator.shared.presentError(error)
        } catch {
            AppCoordinator.shared.presentError(.persistenceFailed(error.localizedDescription))
        }
    }
}
