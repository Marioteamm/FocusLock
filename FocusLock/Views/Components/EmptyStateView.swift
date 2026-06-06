import SwiftUI

struct EmptyStateView: View {

    var onSelectApps: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                ZStack {
                    ForEach(0..<3, id: \.self) { ring in
                        Circle()
                            .stroke(Color.focusAccent.opacity(0.08 - Double(ring) * 0.02), lineWidth: 1)
                            .frame(width: 140 + CGFloat(ring * 36), height: 140 + CGFloat(ring * 36))
                            .scaleEffect(appeared ? 1 : 0.9)
                            .animation(.focusSpring.delay(Double(ring) * 0.05), value: appeared)
                    }

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.focusHeroGradient)
                        .symbolEffect(.pulse.byLayer)
                }

                VStack(spacing: 14) {
                    Text("Перший крок до\nсвідомого екрану")
                        .font(FocusFont.title())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)

                    Text("Спочатку межі, потім пауза перед імпульсом, потім фокус.")
                        .font(FocusFont.body())
                        .foregroundStyle(Color.focusSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                VStack(spacing: 12) {
                    featurePill(icon: "wind", text: "Пауза 3 сек перед бонусом")
                    featurePill(icon: "brain.head.profile", text: "Фокус-сесії без відволікань")
                    featurePill(icon: "tree.fill", text: "Серії та «дерево» звички")
                }

                FocusPrimaryButton(title: "Обрати додатки", icon: "plus.circle.fill", action: onSelectApps)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    .pressableScale()
            }
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()
        }
        .onAppear {
            withAnimation(.focusSpring) { appeared = true }
        }
    }

    private func featurePill(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
            Text(text)
                .font(FocusFont.caption())
        }
        .foregroundStyle(Color.focusSecondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.focusCard, in: Capsule())
    }
}
