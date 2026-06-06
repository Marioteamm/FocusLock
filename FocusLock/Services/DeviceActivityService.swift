// Device Activity monitoring orchestration (live + DEBUG mock delegate)
import Foundation
import FamilyControls

@MainActor
final class DeviceActivityService: DeviceActivityServicing {

    static let shared = DeviceActivityService()

    private let backend: any DeviceActivityServicing

    private init() {
        #if FOCUSLOCK_MOCK_SCREEN_TIME
        backend = MockDeviceActivityService.shared
        #else
        backend = LiveDeviceActivityService()
        #endif
    }

    func stopAllMonitoring(activityNames: [String]) {
        backend.stopAllMonitoring(activityNames: activityNames)
    }

    func stopMonitoring(limitID: UUID) {
        backend.stopMonitoring(limitID: limitID)
    }

    func startMonitoring(configs: [LimitMonitoringConfig]) throws {
        try backend.startMonitoring(configs: configs)
    }

    func startMonitoring(
        selectionData: Data,
        limitMinutes: Int,
        includesBonus: Bool = false
    ) throws {
        try backend.startMonitoring(
            selectionData: selectionData,
            limitMinutes: limitMinutes,
            includesBonus: includesBonus
        )
    }

    func stopMonitoring() {
        backend.stopMonitoring()
    }
}

extension DeviceActivityService {
    func startMonitoring(
        selection: FamilyActivitySelection,
        limitMinutes: Int,
        includesBonus: Bool = false
    ) throws {
        guard let data = try? PropertyListEncoder().encode(selection) else {
            throw AppError.monitoringFailed("Не вдалося зберегти вибір додатків.")
        }
        try startMonitoring(
            selectionData: data,
            limitMinutes: limitMinutes,
            includesBonus: includesBonus
        )
    }
}
