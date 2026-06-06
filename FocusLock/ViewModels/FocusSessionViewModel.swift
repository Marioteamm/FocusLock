import Foundation
import SwiftData

@MainActor
final class FocusSessionViewModel: ObservableObject {

    @Published var selectedMinutes = 25
    @Published var loadState: ViewLoadState = .idle
    @Published var showCancelConfirm = false

    let presets = [15, 25, 45, 60, 90]

    private let sessionManager = FocusSessionManager.shared

    var isActive: Bool { sessionManager.isSessionActive }
    var remainingSeconds: Int { sessionManager.remainingSeconds }
    var progress: Double { sessionManager.progress }

    var remainingFormatted: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    func bind(context: ModelContext) {
        sessionManager.bind(context: context)
    }

    func startSession(context: ModelContext, blockApps: Bool, goal: String) {
        guard !isActive else {
            AppCoordinator.shared.presentError(.sessionAlreadyActive)
            return
        }

        let selection = AppBlockingManager.shared.currentSelection
        if blockApps && selection.applicationTokens.isEmpty {
            AppCoordinator.shared.presentError(.noAppsSelected)
            return
        }

        loadState = .loading
        do {
            try sessionManager.startSession(
                minutes: selectedMinutes,
                goal: goal,
                context: context,
                blockApps: blockApps
            )
            loadState = .loaded
        } catch let error as AppError {
            loadState = .failed(error)
            AppCoordinator.shared.presentError(error)
        } catch {
            loadState = .failed(.generic(error.localizedDescription))
        }
    }

    func completeEarly(context: ModelContext) {
        sessionManager.completeSession(context: context)
    }

    func cancel(context: ModelContext) {
        sessionManager.cancelSession(context: context)
    }

    func totalMinutesToday(context: ModelContext) -> Int {
        sessionManager.totalFocusMinutesToday(context: context)
    }

    func recentSessions(context: ModelContext) -> [FocusSession] {
        sessionManager.recentSessions(context: context)
    }
}
