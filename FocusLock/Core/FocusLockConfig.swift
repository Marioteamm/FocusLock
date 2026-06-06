import Foundation

/// Screen Time build mode (compile-time).
///
/// - **Debug**: `FOCUSLOCK_MOCK_SCREEN_TIME` → mocks, no Family Controls entitlement.
/// - **Release**: flag off → `Live*Service` + FamilyControls / ManagedSettings / DeviceActivity.
enum FocusLockConfig {

    #if FOCUSLOCK_MOCK_SCREEN_TIME
    /// `true` only when `FOCUSLOCK_MOCK_SCREEN_TIME` is in Active Compilation Conditions (Debug).
    static let useMockScreenTime = true
    #else
    static let useMockScreenTime = false
    #endif

    static let demoAppNames = ["Instagram", "TikTok", "Safari", "YouTube", "Telegram"]

    static var isPreviewBuild: Bool { useMockScreenTime }
}
