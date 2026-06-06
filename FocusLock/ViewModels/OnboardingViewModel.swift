import Foundation
import FamilyControls
import SwiftData
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {

    @Published var currentPage = 0
    @Published var selection = FamilyActivitySelection()
    @Published var defaultLimitMinutes = 60
    @Published var commitmentAccepted = false
    @Published var loadState: ViewLoadState = .idle

    /// welcome → psychology → features → permission → picker → limit → commitment
    let pageCount = 7

    private let screenTime = ScreenTimeService.shared
    private let blockingManager = AppBlockingManager.shared

    func advance() {
        guard currentPage < pageCount - 1 else { return }
        withAnimation(.focusSpring) { currentPage += 1 }
        HapticFeedback.selection()
    }

    func goBack() {
        guard currentPage > 0 else { return }
        withAnimation(.focusSpring) { currentPage -= 1 }
    }

    func requestAuthorization() async -> Bool {
        loadState = .loading
        defer { if case .loading = loadState { loadState = .loaded } }

        do {
            try await screenTime.requestAuthorization()
            if screenTime.isAuthorized {
                loadState = .loaded
                HapticFeedback.notification(.success)
                return true
            }
            loadState = .failed(.authorizationDenied)
            return false
        } catch {
            loadState = .failed(.authorizationFailed(error.localizedDescription))
            return false
        }
    }

    func finish(context: ModelContext, mockAppNames: [String] = []) async {
        guard commitmentAccepted else {
            AppCoordinator.shared.presentError(.generic("Підтвердіть обіцянку, щоб продовжити"))
            return
        }

        loadState = .loading

        do {
            if FocusLockConfig.useMockScreenTime, !mockAppNames.isEmpty {
                try blockingManager.injectDemoLimits(
                    context: context,
                    appNames: mockAppNames,
                    defaultMinutes: defaultLimitMinutes
                )
                let limits = try context.fetch(FetchDescriptor<AppLimit>())
                try blockingManager.startMonitoring(limits: limits)
            } else if !selection.applicationTokens.isEmpty {
                guard screenTime.isAuthorized else {
                    loadState = .failed(.authorizationDenied)
                    AppCoordinator.shared.presentError(.authorizationDenied)
                    return
                }
                blockingManager.saveSelection(selection)
                try blockingManager.syncLimits(
                    from: selection,
                    context: context,
                    defaultMinutes: defaultLimitMinutes
                )
                let limits = try context.fetch(FetchDescriptor<AppLimit>())
                try blockingManager.startMonitoring(limits: limits)
            }

            let settings = SettingsRepository.shared.ensureSettings(context: context)
            settings.defaultLimitMinutes = defaultLimitMinutes
            settings.hasSignedCommitment = true
            settings.dailyIntentionRaw = MindfulCopy.DailyIntention.calm.rawValue
            settings.mindfulPauseEnabled = true
            settings.updatedAt = Date()
            try context.save()

            loadState = .loaded
            AppCoordinator.shared.completeOnboarding(context: context)
        } catch {
            loadState = .failed(.persistenceFailed(error.localizedDescription))
            AppCoordinator.shared.presentError(.persistenceFailed(error.localizedDescription))
        }
    }
}
