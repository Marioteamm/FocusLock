import Foundation
import SwiftData
import SwiftUI

@MainActor
final class MotivationManager: ObservableObject {

    static let shared = MotivationManager()

    @Published var celebrationMilestone: HabitMilestone?
    @Published var showCelebration = false

    private init() {}

    func checkMilestone(
        previousStreak: Int,
        newStreak: Int,
        settings: AppSettings,
        context: ModelContext
    ) {
        guard let milestone = HabitMilestone.newlyReached(previous: previousStreak, current: newStreak) else {
            return
        }
        guard settings.lastCelebratedMilestone < milestone.rawValue else { return }

        celebrationMilestone = milestone
        showCelebration = true
        settings.lastCelebratedMilestone = milestone.rawValue
        settings.updatedAt = Date()
        try? context.save()
        HapticFeedback.notification(.success)
    }

    func dismissCelebration() {
        withAnimation(.focusSpring) {
            showCelebration = false
            celebrationMilestone = nil
        }
    }

    func wellnessScore(
        limits: [AppLimit],
        streak: Int,
        focusMinutes: Int,
        progress: Double
    ) -> Int {
        var score = 50
        if progress < 0.7 { score += 20 }
        if progress < 0.5 { score += 10 }
        score += min(20, streak * 2)
        score += min(10, focusMinutes / 3)
        if limits.allSatisfy({ !$0.isCurrentlyBlocked }) { score += 5 }
        return min(100, max(0, score))
    }

    func estimatedMinutesReclaimedToday(limits: [AppLimit]) -> Int {
        let usage = UsageTrackingManager.shared
        return limits.filter(\.isEnabled).reduce(0) { total, limit in
            let usedMin = usage.getUsedTime(bundleId: limit.bundleIdentifier) / 60
            let cap = limit.effectiveLimitMinutes
            return total + max(0, cap - usedMin)
        }
    }
}
