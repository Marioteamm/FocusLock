import SwiftUI

struct WeeklyChartView: View {
    let data: [StatsViewModel.DayUsageSummary]

    private var maxMinutes: Int {
        max(data.map(\.minutes).max() ?? 1, 1)
    }

    private var chartAccessibilitySummary: String {
        data.map { "\($0.weekday): \($0.minutes) хвилин" }.joined(separator: ", ")
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(data) { day in
                VStack(spacing: 8) {
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.focusDivider.opacity(0.35))
                            .frame(height: 100)

                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(barGradient(for: day))
                            .frame(height: barHeight(for: day.minutes))
                    }
                    .frame(height: 100)
                    .accessibilityHidden(true)

                    Text(day.weekday)
                        .font(FocusFont.micro())
                        .foregroundStyle(day.isToday ? Color.focusAccent : Color.focusSecondary)

                    if day.minutes > 0 {
                        Text("\(day.minutes)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.focusSecondary.opacity(0.9))
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(day.weekday), \(day.minutes) хвилин\(day.metGoal ? ", ціль досягнута" : "")")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Тижневий графік")
        .accessibilityValue(chartAccessibilitySummary)
        .animation(.focusSpring, value: data.map(\.minutes))
    }

    private func barHeight(for minutes: Int) -> CGFloat {
        let ratio = CGFloat(minutes) / CGFloat(maxMinutes)
        return max(6, ratio * 100)
    }

    private func barGradient(for day: StatsViewModel.DayUsageSummary) -> LinearGradient {
        if day.metGoal {
            return LinearGradient(colors: [.focusSuccess, .focusSuccess.opacity(0.7)], startPoint: .top, endPoint: .bottom)
        }
        if day.isToday {
            return LinearGradient(colors: [.focusAccent, .focusAccentSecondary], startPoint: .top, endPoint: .bottom)
        }
        return LinearGradient(colors: [.focusAccent.opacity(0.6), .focusAccent.opacity(0.3)], startPoint: .top, endPoint: .bottom)
    }
}
