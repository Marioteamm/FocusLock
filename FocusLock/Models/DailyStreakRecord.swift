import Foundation
import SwiftData

@Model
final class DailyStreakRecord {

    var id: UUID
    var date: Date
    var metGoal: Bool
    var focusMinutes: Int
    var limitsRespected: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Calendar.current.startOfDay(for: Date()),
        metGoal: Bool = false,
        focusMinutes: Int = 0,
        limitsRespected: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date.startOfDay
        self.metGoal = metGoal
        self.focusMinutes = focusMinutes
        self.limitsRespected = limitsRespected
        self.createdAt = createdAt
    }
}
