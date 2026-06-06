import SwiftUI

struct WellnessScoreCard: View {

    let score: Int
    let minutesReclaimed: Int
    let focusMinutes: Int

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.focusDivider.opacity(0.4), lineWidth: 6)
                    .frame(width: 72, height: 72)

                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))

                Text("\(score)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Індекс уваги")
                    .font(FocusFont.caption())
                    .foregroundStyle(Color.focusSecondary)
                Text(scoreLabel)
                    .font(FocusFont.headline())
                    .foregroundStyle(scoreColor)

                HStack(spacing: 16) {
                    miniStat(icon: "arrow.uturn.backward.circle", value: "\(minutesReclaimed) хв", label: "в межах")
                    miniStat(icon: "brain", value: "\(focusMinutes) хв", label: "фокус")
                }
            }
        }
        .padding(18)
        .focusGlassCard()
    }

    private var scoreColor: Color {
        switch score {
        case 80...: return .focusSuccess
        case 60..<80: return .focusAccent
        case 40..<60: return .focusWarning
        default: return .focusDanger
        }
    }

    private var scoreLabel: String {
        switch score {
        case 80...: return "Відмінний баланс"
        case 60..<80: return "Добре"
        case 40..<60: return "Потрібна увага"
        default: return "Перевантаження"
        }
    }

    private func miniStat(icon: String, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(value, systemImage: icon)
                .font(FocusFont.micro())
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.focusSecondary)
        }
    }
}
