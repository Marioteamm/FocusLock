import Foundation
import FamilyControls
import Combine

@MainActor
final class LiveFamilyControlsService: FamilyControlsServicing {

    @Published private(set) var authorizationStatus: AuthorizationStatus = .notDetermined

    init() {
        refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }

    func requestAuthorization() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        refreshAuthorizationStatus()
    }

    var isAuthorized: Bool {
        authorizationStatus == .approved
    }
}
