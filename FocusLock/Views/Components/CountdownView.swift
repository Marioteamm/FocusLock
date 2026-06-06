import SwiftUI

struct CountdownView: View {

    @State private var timeRemaining = Date().formattedTimeUntilReset
    @State private var pulse = false
    @State private var timer: Timer?

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("До скидання")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.focusSecondary)

            Text(timeRemaining)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.focusAccent)
                .contentTransition(.numericText())
                .scaleEffect(pulse ? 1.02 : 1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.focusAccent.opacity(0.1), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("До скидання лімітів: \(timeRemaining)")
        .onAppear { startTimer() }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func startTimer() {
        timer?.invalidate()
        updateTime()
        let t = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.focusQuick) {
                    pulse.toggle()
                    updateTime()
                }
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func updateTime() {
        timeRemaining = Date().formattedTimeUntilReset
    }
}
