import Foundation

struct LimitMonitoringConfig: Sendable {
    let limitID: UUID
    let bundleIdentifier: String
    let tokenData: Data
    let limitMinutes: Int
    let includesBonus: Bool
}

@MainActor
protocol DeviceActivityServicing: AnyObject {
    func stopAllMonitoring(activityNames: [String])
    func stopMonitoring(limitID: UUID)
    func startMonitoring(configs: [LimitMonitoringConfig]) throws
    func startMonitoring(
        selectionData: Data,
        limitMinutes: Int,
        includesBonus: Bool
    ) throws
    func stopMonitoring()
}
