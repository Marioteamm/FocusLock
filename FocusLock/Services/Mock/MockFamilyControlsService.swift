import Foundation
import FamilyControls
import Combine

/// DEBUG / Simulator: no Family Controls entitlement required.
@MainActor
final class MockFamilyControlsService: FamilyControlsServicing {

    static let shared = MockFamilyControlsService()

    @Published private(set) var authorizationStatus: AuthorizationStatus = .approved

    private init() {}

    func refreshAuthorizationStatus() {
        authorizationStatus = .approved
    }

    func requestAuthorization() async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
        authorizationStatus = .approved
    }

    var isAuthorized: Bool { true }
}
