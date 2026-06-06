import Foundation
import SwiftData

enum FocusSessionStatus: String, Codable {
    case scheduled
    case active
    case completed
    case cancelled
}

@Model
final class FocusSession {

    var id: UUID
    var plannedMinutes: Int
    var startedAt: Date?
    var endedAt: Date?
    var statusRaw: String
    var sessionGoal: String
    var createdAt: Date

    var status: FocusSessionStatus {
        get { FocusSessionStatus(rawValue: statusRaw) ?? .scheduled }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        plannedMinutes: Int,
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        status: FocusSessionStatus = .scheduled,
        sessionGoal: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.plannedMinutes = plannedMinutes
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.statusRaw = status.rawValue
        self.sessionGoal = sessionGoal
        self.createdAt = createdAt
    }

    var elapsedSeconds: Int {
        guard let start = startedAt else { return 0 }
        let end = endedAt ?? Date()
        return max(0, Int(end.timeIntervalSince(start)))
    }

    var remainingSeconds: Int {
        max(0, plannedMinutes * 60 - elapsedSeconds)
    }

    var progress: Double {
        let total = plannedMinutes * 60
        guard total > 0 else { return 0 }
        return min(1, Double(elapsedSeconds) / Double(total))
    }
}
