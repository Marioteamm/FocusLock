// Модель запису сесії використання програми
import Foundation
import SwiftData

@Model
final class AppUsageRecord {

    var id: UUID
    var bundleIdentifier: String
    var sessionStart: Date
    var sessionEnd: Date?
    var recordDate: Date

    init(
        id: UUID = UUID(),
        bundleIdentifier: String,
        sessionStart: Date = Date(),
        sessionEnd: Date? = nil,
        recordDate: Date = Calendar.current.startOfDay(for: Date())
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.sessionStart = sessionStart
        self.sessionEnd = sessionEnd
        self.recordDate = recordDate
    }

    var durationSeconds: Int {
        let end = sessionEnd ?? Date()
        return Int(end.timeIntervalSince(sessionStart))
    }
}
