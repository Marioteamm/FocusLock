import SwiftUI

struct StreakBadgeView: View {
    let streak: Int
    var compact: Bool = false

    var body: some View {
        HStack(spacing: compact ? 6 : 10) {
            Image(systemName: "flame.fill")
                .font(compact ? .body : .title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.focusStreak, .focusWarning],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .symbolEffect(.bounce, value: streak)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak)")
                    .font(.system(size: compact ? 20 : 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                if !compact {
                    Text(streak == 1 ? "день поспіль" : "днів поспіль")
                        .font(.caption)
                        .foregroundStyle(Color.focusSecondary)
                }
            }
        }
        .padding(.horizontal, compact ? 12 : 16)
        .padding(.vertical, compact ? 8 : 12)
        .background(
            Color.focusStreak.opacity(0.12),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }
}
