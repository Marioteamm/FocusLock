// Модель ліміту часу для програми
import Foundation
import SwiftData

@Model
final class AppLimit {

    var id: UUID
    var appName: String
    /// Stable identifier for usage tracking (token hash or legacy bundle id)
    var bundleIdentifier: String
    /// PropertyList-encoded single-token FamilyActivitySelection
    var tokenData: Data?
    var limitMinutes: Int
    var bonusUsedToday: Bool
    var lastResetDate: Date
    var isCurrentlyBlocked: Bool
    var isEnabled: Bool
    /// Why user limits this app (habit psychology)
    var limitIntentionRaw: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        appName: String,
        bundleIdentifier: String,
        tokenData: Data? = nil,
        limitMinutes: Int = 60,
        bonusUsedToday: Bool = false,
        lastResetDate: Date = Calendar.current.startOfDay(for: Date()),
        isCurrentlyBlocked: Bool = false,
        isEnabled: Bool = true,
        limitIntentionRaw: String = MindfulCopy.LimitIntention.habit.rawValue,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.tokenData = tokenData
        self.limitMinutes = limitMinutes
        self.bonusUsedToday = bonusUsedToday
        self.lastResetDate = lastResetDate
        self.isCurrentlyBlocked = isCurrentlyBlocked
        self.isEnabled = isEnabled
        self.limitIntentionRaw = limitIntentionRaw
        self.createdAt = createdAt
    }

    var limitIntention: MindfulCopy.LimitIntention {
        MindfulCopy.LimitIntention(rawValue: limitIntentionRaw) ?? .habit
    }

    var effectiveLimitMinutes: Int {
        bonusUsedToday ? limitMinutes + 15 : limitMinutes
    }
}
