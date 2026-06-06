import SwiftUI

struct StreakCelebrationOverlay: View {

    let milestone: HabitMilestone
    var onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var show = false
    @State private var ringScale: CGFloat = 0.3

    var body: some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea()

            if !reduceMotion {
                ConfettiView()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 28) {
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Color.focusStreak.opacity(0.2 - Double(i) * 0.05), lineWidth: 2)
                            .frame(width: 120 + CGFloat(i * 40), height: 120 + CGFloat(i * 40))
                            .scaleEffect(ringScale)
                    }

                    Image(systemName: milestone.icon)
                        .font(.system(size: 56))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.focusStreak, .focusWarning],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .symbolEffect(.bounce, value: show)
                }

                VStack(spacing: 10) {
                    Text(milestone.title)
                        .font(FocusFont.hero(28))
                        .foregroundStyle(.white)

                    Text(milestone.subtitle)
                        .font(FocusFont.body())
                        .foregroundStyle(Color.focusSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                FocusPrimaryButton(title: "Чудово!", icon: "sparkles") {
                    onDismiss()
                }
                .padding(.horizontal, 48)
            }
            .scaleEffect(show ? 1 : 0.8)
            .opacity(show ? 1 : 0)
        }
        .onAppear {
            withAnimation(.focusSpring) {
                show = true
                ringScale = 1
            }
            HapticFeedback.notification(.success)
        }
    }
}

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = (0..<24).map { _ in ConfettiParticle() }

    var body: some View {
        GeometryReader { geo in
            ForEach(particles.indices, id: \.self) { i in
                Circle()
                    .fill(particles[i].color)
                    .frame(width: particles[i].size, height: particles[i].size)
                    .position(particles[i].position(in: geo.size))
                    .opacity(particles[i].opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2)) {
                particles = particles.map { p in
                    var copy = p
                    copy.fallen = true
                    return copy
                }
            }
        }
    }
}

private struct ConfettiParticle {
    var xRatio: CGFloat = .random(in: 0...1)
    var yStart: CGFloat = .random(in: -0.1...0.2)
    var size: CGFloat = .random(in: 4...9)
    var color: Color = [.focusAccent, .focusStreak, .focusSuccess, .focusWarning].randomElement()!
    var opacity: Double = .random(in: 0.6...1)
    var fallen = false

    func position(in size: CGSize) -> CGPoint {
        let y = fallen ? size.height + 20 : size.height * yStart
        return CGPoint(x: size.width * xRatio, y: y)
    }
}
