// Розширення для роботи з датами
import Foundation

extension Date {

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var startOfNextDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: self.startOfDay) ?? self
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var secondsUntilEndOfDay: Int {
        max(0, Int(startOfNextDay.timeIntervalSince(self)))
    }

    var formattedTimeUntilReset: String {
        let seconds = secondsUntilEndOfDay
        let hours   = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return "\(hours) год \(minutes) хв"
    }

    func needsReset(lastReset: Date) -> Bool {
        !Calendar.current.isDate(self, inSameDayAs: lastReset)
    }
}
