import SwiftUI

/// Roots-style habit growth visualization.
struct HabitGrowthTreeView: View {

    let streak: Int
    let longestStreak: Int

    private var growthLevel: Int {
        min(5, streak / 7 + (streak > 0 ? 1 : 0))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            FocusSectionHeader(
                title: "Ваше дерево звички",
                subtitle: "Кожен день поливає коріння"
            )

            HStack(alignment: .bottom, spacing: 0) {
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.focusDivider.opacity(0.5))
                        .frame(width: 8, height: 80)

                    treeGraphic
                }
                .frame(width: 100, height: 100)

                VStack(alignment: .leading, spacing: 10) {
                    growthRow(label: "Поточна серія", value: "\(streak) дн.", highlight: true)
                    growthRow(label: "Рекорд", value: "\(longestStreak) дн.")
                    growthRow(label: "Рівень росту", value: levelName)

                    if let next = nextMilestone {
                        Text("До «\(next.title)»: \(next.rawValue - streak) дн.")
                            .font(FocusFont.micro())
                            .foregroundStyle(Color.focusAccent)
                    }
                }
                .padding(.leading, 8)
            }
        }
        .padding(18)
        .focusCard()
    }

    @ViewBuilder
    private var treeGraphic: some View {
        VStack(spacing: 0) {
            if growthLevel >= 3 {
                Image(systemName: "leaf.fill")
                    .font(.title)
                    .foregroundStyle(Color.focusSuccess)
                    .offset(x: -12, y: 4)
                Image(systemName: "leaf.fill")
                    .font(.title2)
                    .foregroundStyle(Color.focusSuccess.opacity(0.8))
                    .offset(x: 14, y: -8)
            }
            if growthLevel >= 2 {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.brown.opacity(0.6))
                    .frame(width: 10, height: 36)
            }
            Circle()
                .fill(Color.brown.opacity(0.4))
                .frame(width: 24, height: 8)
        }
    }

    private var levelName: String {
        switch growthLevel {
        case 0: return "Насіння"
        case 1: return "Паросток"
        case 2: return "Молоде"
        case 3: return "Кущ"
        case 4: return "Дерево"
        default: return "Ліс"
        }
    }

    private var nextMilestone: HabitMilestone? {
        HabitMilestone.allCases.first { $0.rawValue > streak }
    }

    private func growthRow(label: String, value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(FocusFont.caption())
                .foregroundStyle(Color.focusSecondary)
            Spacer()
            Text(value)
                .font(FocusFont.headline())
                .foregroundStyle(highlight ? Color.focusStreak : .white)
        }
    }
}
