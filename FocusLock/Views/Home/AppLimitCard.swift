import SwiftUI
import SwiftData

struct AppLimitCard: View {

    let limit: AppLimit
    var onEditLimit: (AppLimit) -> Void
    var onBonusTime: (AppLimit) -> Void
    var onToggleEnabled: ((AppLimit, Bool) -> Void)?

    @Environment(\.modelContext) private var modelContext
    @State private var showMindfulPause = false
    @Query private var settingsQuery: [AppSettings]

    private let usageManager = UsageTrackingManager.shared

    private var mindfulPauseEnabled: Bool {
        settingsQuery.first?.mindfulPauseEnabled ?? true
    }

    private var usedSeconds: Int {
        usageManager.getUsedTime(bundleId: limit.bundleIdentifier)
    }
    private var usedMinutes: Int { usedSeconds / 60 }
    private var effectiveLimit: Int { limit.effectiveLimitMinutes }

    private var progress: Double {
        guard effectiveLimit > 0, limit.isEnabled else { return 0 }
        return min(1.0, Double(usedSeconds) / Double(effectiveLimit * 60))
    }

    private var isLimitReached: Bool {
        guard limit.isEnabled else { return false }
        return limit.isCurrentlyBlocked
            || AppGroupConstants.groupDefaults.bool(forKey: AppGroupConstants.limitBlockedKey(limitID: limit.id))
            || usedSeconds >= effectiveLimit * 60
    }

    private var remainingMinutes: Int {
        max(0, effectiveLimit - usedMinutes)
    }

    private var progressColor: Color {
        if !limit.isEnabled { return .focusSecondary }
        switch progress {
        case 0..<0.6: return .focusSuccess
        case 0.6..<0.85: return .focusWarning
        default: return .focusDanger
        }
    }

    private var dailyBonusUsed: Bool {
        AppBlockingManager.shared.isDailyBonusUsed()
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                AppTokenIconView(tokenData: limit.tokenData, size: 48)
                    .opacity(limit.isEnabled ? 1 : 0.45)

                VStack(alignment: .leading, spacing: 6) {
                    AppTokenLabelView(tokenData: limit.tokenData, fallbackName: limit.appName)

                    Label(limit.limitIntention.title, systemImage: limit.limitIntention.icon)
                        .font(FocusFont.micro())
                        .foregroundStyle(Color.focusSecondary.opacity(0.85))

                    statusChip
                }

                Spacer()

                if let onToggleEnabled {
                    Toggle(isOn: Binding(
                        get: { limit.isEnabled },
                        set: { onToggleEnabled(limit, $0) }
                    )) {
                        Text("Увімкнути ліміт")
                            .font(FocusFont.micro())
                            .foregroundStyle(.clear)
                            .frame(width: 0, height: 0)
                    }
                    .accessibilityLabel("Увімкнути ліміт для \(limit.appName)")
                    .tint(Color.focusAccent)
                }
            }

            if limit.isEnabled {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(usedMinutes)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text("/ \(effectiveLimit) хв")
                        .font(FocusFont.caption())
                        .foregroundStyle(Color.focusSecondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(FocusFont.headline())
                        .foregroundStyle(progressColor)
                }

                ProgressRingView(progress: progress, color: progressColor)
                    .animation(.focusQuick, value: progress)

                HStack {
                    Button { onEditLimit(limit) } label: {
                        Label("Змінити ліміт", systemImage: "clock")
                            .font(FocusFont.caption())
                    }
                    .foregroundStyle(Color.focusAccent)

                    Spacer()

                    if !isLimitReached {
                        Text("\(remainingMinutes) хв залишилось")
                            .font(FocusFont.micro())
                            .foregroundStyle(Color.focusSecondary)
                    }
                }

                if isLimitReached {
                    bonusButton
                }
            } else {
                Text("Ліміт призупинено")
                    .font(FocusFont.caption())
                    .foregroundStyle(Color.focusSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .focusCard()
        .opacity(limit.isEnabled ? 1 : 0.72)
        .fullScreenCover(isPresented: $showMindfulPause) {
            BreathingPauseView(
                title: "Перед +15 хвилинами",
                subtitle: limit.limitIntention.intervention,
                onComplete: {
                    showMindfulPause = false
                    if let s = settingsQuery.first {
                        s.totalMindfulPauses += 1
                        s.updatedAt = Date()
                        try? modelContext.save()
                    }
                    onBonusTime(limit)
                },
                onCancel: { showMindfulPause = false }
            )
        }
    }

    @ViewBuilder
    private var statusChip: some View {
        if !limit.isEnabled {
            Label("Пауза", systemImage: "pause.fill")
                .font(FocusFont.micro())
                .foregroundStyle(Color.focusSecondary)
        } else if isLimitReached {
            Label("Заблоковано", systemImage: "lock.fill")
                .font(FocusFont.micro())
                .foregroundStyle(Color.focusDanger)
        } else if progress >= 0.85 {
            Label("Майже ліміт", systemImage: "exclamationmark.circle.fill")
                .font(FocusFont.micro())
                .foregroundStyle(Color.focusWarning)
        } else {
            EmptyView()
        }
    }

    private var bonusButton: some View {
        let strict = settingsQuery.first?.strictModeEnabled ?? AppBlockingManager.shared.isStrictModeEnabled
        return Button {
            guard !strict else { return }
            if mindfulPauseEnabled {
                showMindfulPause = true
            } else {
                onBonusTime(limit)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: dailyBonusUsed ? "checkmark.circle.fill" : "plus.circle.fill")
                Text(dailyBonusUsed ? "Бонус використано сьогодні" : "+15 хвилин (1 раз/день)")
                    .font(FocusFont.caption())
            }
            .foregroundStyle(dailyBonusUsed ? Color.focusSecondary : Color.focusAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                dailyBonusUsed ? Color.focusDivider : Color.focusAccent.opacity(0.12),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }
        .disabled(dailyBonusUsed || strict)
        .accessibilityHint(strict ? "Суворий режим вимикає бонус" : "Один раз на день")
    }
}
