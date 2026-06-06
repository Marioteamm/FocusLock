// Сервіс авторизації Screen Time (live + DEBUG mock delegate)
import Foundation
import FamilyControls
import Combine

@MainActor
final class ScreenTimeService: ObservableObject, FamilyControlsServicing {

    static let shared = ScreenTimeService()

    @Published private(set) var authorizationStatus: AuthorizationStatus = .notDetermined

    private let backend: any FamilyControlsServicing

    private init() {
        #if FOCUSLOCK_MOCK_SCREEN_TIME
        backend = MockFamilyControlsService.shared
        #else
        backend = LiveFamilyControlsService()
        #endif
        authorizationStatus = backend.authorizationStatus
    }

    func refreshAuthorizationStatus() {
        backend.refreshAuthorizationStatus()
        authorizationStatus = backend.authorizationStatus
    }

    func requestAuthorization() async throws {
        try await backend.requestAuthorization()
        authorizationStatus = backend.authorizationStatus
    }

    var isAuthorized: Bool {
        backend.isAuthorized
    }
}
