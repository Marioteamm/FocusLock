// Модель щоденної статистики
import Foundation
import SwiftData

@Model
final class DailyStats {

    var id: UUID
    var date: Date
    var bundleIdentifier: String
    var appName: String
    var usedSeconds: Int
    var blockCount: Int
    var bonusUsed: Bool

    init(
        id: UUID = UUID(),
        date: Date = Calendar.current.startOfDay(for: Date()),
        bundleIdentifier: String,
        appName: String,
        usedSeconds: Int = 0,
        blockCount: Int = 0,
        bonusUsed: Bool = false
    ) {
        self.id = id
        self.date = date
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.usedSeconds = usedSeconds
        self.blockCount = blockCount
        self.bonusUsed = bonusUsed
    }

    var usedMinutes: Int { usedSeconds / 60 }

    var formattedUsedTime: String {
        let hours = usedSeconds / 3600
        let minutes = (usedSeconds % 3600) / 60
        if hours > 0 { return "\(hours) год \(minutes) хв" }
        return "\(minutes) хв"
    }
}
