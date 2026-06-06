import Foundation
import SwiftData
import Combine

@MainActor
final class FocusSessionManager: ObservableObject {

    static let shared = FocusSessionManager()

    @Published private(set) var activeSession: FocusSession?
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var progress: Double = 0

    private var timer: Timer?
    private var modelContext: ModelContext?

    private init() {}

    var isSessionActive: Bool { activeSession?.status == .active }

    func bind(context: ModelContext) {
        modelContext = context
        reconcileActiveSession(context: context)
    }

    func reconcileActiveSession(context: ModelContext) {
        let sessions = (try? context.fetch(FetchDescriptor<FocusSession>())) ?? []
        let active = sessions.filter { $0.status == .active }

        if active.count > 1 {
            for orphan in active.dropFirst() {
                orphan.status = .cancelled
                orphan.endedAt = Date()
            }
            try? context.save()
        }

        if let session = active.first {
            activeSession = session
            AppGroupConstants.groupDefaults.set(true, forKey: AppGroupConstants.focusSessionActiveKey)
            tick()
            startTimer()
        } else {
            activeSession = nil
            AppGroupConstants.groupDefaults.set(false, forKey: AppGroupConstants.focusSessionActiveKey)
            stopTimer()
        }
    }

    func startSession(
        minutes: Int,
        goal: String,
        context: ModelContext,
        blockApps: Bool
    ) throws {
        guard !isSessionActive else {
            throw AppError.sessionAlreadyActive
        }

        let session = FocusSession(
            plannedMinutes: minutes,
            startedAt: Date(),
            status: .active,
            sessionGoal: goal
        )
        context.insert(session)
        try context.save()

        activeSession = session
        if blockApps {
            let selection = AppBlockingManager.shared.currentSelection
            if FocusLockConfig.useMockScreenTime {
                AppBlockingManager.shared.hasBlockedApps = !selection.applicationTokens.isEmpty
                AppGroupConstants.groupDefaults.set(
                    !selection.applicationTokens.isEmpty,
                    forKey: AppGroupConstants.focusSessionActiveKey
                )
            } else if !selection.applicationTokens.isEmpty {
                AppBlockingManager.shared.applyBlocking(for: selection)
            }
        }

        tick()
        startTimer()
        HapticFeedback.notification(.success)
    }

    func completeSession(context: ModelContext) {
        guard let session = activeSession else { return }
        session.status = .completed
        session.endedAt = Date()
        try? context.save()

        AppBlockingManager.shared.removeAllBlocking()
        stopTimer()
        activeSession = nil

        let elapsedMinutes = max(1, session.elapsedSeconds / 60)
        let limits = (try? context.fetch(FetchDescriptor<AppLimit>())) ?? []
        StreakManager.shared.recordTodayProgress(
            context: context,
            limits: limits,
            focusMinutes: elapsedMinutes
        )
        HapticFeedback.notification(.success)
    }

    func cancelSession(context: ModelContext) {
        guard let session = activeSession else { return }
        session.status = .cancelled
        session.endedAt = Date()
        try? context.save()

        AppBlockingManager.shared.removeAllBlocking()
        stopTimer()
        activeSession = nil
        HapticFeedback.impact(.light)
    }

    private func startTimer() {
        stopTimer()
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard let session = activeSession, session.status == .active else {
            stopTimer()
            return
        }

        remainingSeconds = session.remainingSeconds
        progress = session.progress
        objectWillChange.send()

        if remainingSeconds <= 0, let context = modelContext {
            completeSession(context: context)
        }
    }

    func recentSessions(context: ModelContext, limit: Int = 10) -> [FocusSession] {
        var descriptor = FetchDescriptor<FocusSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }

    func totalFocusMinutesToday(context: ModelContext) -> Int {
        let sessions = (try? context.fetch(FetchDescriptor<FocusSession>())) ?? []
        return sessions
            .filter { $0.status == .completed && ($0.endedAt.map { Calendar.current.isDateInToday($0) } ?? false) }
            .reduce(0) { $0 + $1.elapsedSeconds } / 60
    }
}
