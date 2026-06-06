import SwiftUI

/// Mindful pause before impulsive actions.
struct BreathingPauseView: View {

    var title: String = "Зробіть паузу"
    var subtitle: String = "Дофамін впаде за 3 секунди"
    var onComplete: () -> Void
    var onCancel: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase = 0
    @State private var scale: CGFloat = 0.85
    @State private var progress: CGFloat = 0
    @State private var finished = false
    @State private var cycleID = UUID()

    private let phaseDuration: Double = 1.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()

            VStack(spacing: 32) {
                Text(title)
                    .font(FocusFont.title())
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)

                Text(subtitle)
                    .font(FocusFont.caption())
                    .foregroundStyle(Color.focusSecondary)
                    .multilineTextAlignment(.center)

                ZStack {
                    Circle()
                        .stroke(Color.focusDivider.opacity(0.4), lineWidth: 3)
                        .frame(width: 160, height: 160)

                    Circle()
                        .fill(Color.focusAccent.opacity(0.15))
                        .frame(width: 160, height: 160)
                        .scaleEffect(scale)

                    Text(currentPrompt)
                        .font(FocusFont.headline())
                        .foregroundStyle(.white)
                        .contentTransition(.opacity)
                }
                .accessibilityLabel("Дихання: \(currentPrompt)")

                ProgressView(value: progress, total: 1)
                    .tint(Color.focusAccent)
                    .frame(width: 200)
                    .accessibilityLabel("Прогрес паузи")

                if finished {
                    FocusPrimaryButton(title: "Продовжити", icon: "checkmark") {
                        onComplete()
                    }
                    .padding(.horizontal, 40)
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Button("Не зараз") { cancelAndDismiss() }
                        .font(FocusFont.caption())
                        .foregroundStyle(Color.focusSecondary)
                        .accessibilityHint("Скасувати паузу")
                }
            }
            .padding(32)
        }
        .onAppear { startBreathingCycle() }
        .onDisappear { cycleID = UUID() }
    }

    private var currentPrompt: String {
        let prompts = MindfulCopy.breathePrompts
        return prompts[min(phase, prompts.count - 1)]
    }

    private func cancelAndDismiss() {
        cycleID = UUID()
        onCancel()
    }

    private func startBreathingCycle() {
        cycleID = UUID()
        phase = 0
        finished = false
        if reduceMotion {
            finished = true
            progress = 1
            return
        }
        animatePhase()
    }

    private func animatePhase() {
        let token = cycleID
        guard phase < 3 else {
            guard token == cycleID else { return }
            withAnimation(.focusSpring) {
                finished = true
                progress = 1
            }
            HapticFeedback.notification(.success)
            return
        }

        withAnimation(.easeInOut(duration: phaseDuration)) {
            scale = phase == 1 ? 1.15 : (phase == 0 ? 1.0 : 0.85)
            progress = CGFloat(phase + 1) / 4.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + phaseDuration) {
            guard token == cycleID else { return }
            phase += 1
            animatePhase()
        }
    }
}
