import Foundation
import FamilyControls
import Combine

@MainActor
protocol FamilyControlsServicing: AnyObject, ObservableObject {
    var authorizationStatus: AuthorizationStatus { get }
    var isAuthorized: Bool { get }
    func refreshAuthorizationStatus()
    func requestAuthorization() async throws
}
