import SwiftUI

extension Color {
    static let focusAccent = Color(red: 0.45, green: 0.55, blue: 1.0)
    static let focusAccentSecondary = Color(red: 0.35, green: 0.75, blue: 0.95)
    static let focusCard = Color(red: 0.11, green: 0.11, blue: 0.14)
    static let focusCardElevated = Color(red: 0.14, green: 0.14, blue: 0.18)
    static let focusBackground = Color(red: 0.05, green: 0.05, blue: 0.07)
    static let focusWarning = Color(red: 1.0, green: 0.78, blue: 0.2)
    static let focusDanger = Color(red: 1.0, green: 0.38, blue: 0.42)
    static let focusSuccess = Color(red: 0.25, green: 0.88, blue: 0.55)
    static let focusSecondary = Color(red: 0.55, green: 0.56, blue: 0.62)
    static let focusDivider = Color(red: 0.2, green: 0.21, blue: 0.26)
    static let focusStreak = Color(red: 1.0, green: 0.55, blue: 0.2)

    static var focusHeroGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.35, green: 0.45, blue: 0.95),
                Color(red: 0.2, green: 0.65, blue: 0.9),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var focusBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.07, blue: 0.12),
                Color(red: 0.04, green: 0.04, blue: 0.06),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
