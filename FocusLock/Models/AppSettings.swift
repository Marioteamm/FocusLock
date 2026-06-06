import Foundation
import SwiftData

@Model
final class AppSettings {

    var id: UUID
    var hasCompletedOnboarding: Bool
    var defaultLimitMinutes: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastStreakUpdate: Date?
    var hapticsEnabled: Bool
    var strictModeEnabled: Bool
    var focusSessionBlocksApps: Bool
    var mindfulPauseEnabled: Bool
    var dailyIntentionRaw: String
    var hasSignedCommitment: Bool
    var lastCelebratedMilestone: Int
    var totalMindfulPauses: Int
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        hasCompletedOnboarding: Bool = false,
        defaultLimitMinutes: Int = 60,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastStreakUpdate: Date? = nil,
        hapticsEnabled: Bool = true,
        strictModeEnabled: Bool = false,
        focusSessionBlocksApps: Bool = true,
        mindfulPauseEnabled: Bool = true,
        dailyIntentionRaw: String = MindfulCopy.DailyIntention.calm.rawValue,
        hasSignedCommitment: Bool = false,
        lastCelebratedMilestone: Int = 0,
        totalMindfulPauses: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.defaultLimitMinutes = defaultLimitMinutes
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastStreakUpdate = lastStreakUpdate
        self.hapticsEnabled = hapticsEnabled
        self.strictModeEnabled = strictModeEnabled
        self.focusSessionBlocksApps = focusSessionBlocksApps
        self.mindfulPauseEnabled = mindfulPauseEnabled
        self.dailyIntentionRaw = dailyIntentionRaw
        self.hasSignedCommitment = hasSignedCommitment
        self.lastCelebratedMilestone = lastCelebratedMilestone
        self.totalMindfulPauses = totalMindfulPauses
        self.updatedAt = updatedAt
    }

    var dailyIntention: MindfulCopy.DailyIntention {
        MindfulCopy.DailyIntention(rawValue: dailyIntentionRaw) ?? .calm
    }
}
