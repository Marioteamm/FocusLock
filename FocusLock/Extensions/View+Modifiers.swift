import SwiftUI

extension View {

    func focusCard() -> some View {
        self
            .background(Color.focusCard)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.focusDivider.opacity(0.6), lineWidth: 0.5)
            )
    }

    func focusGlassCard() -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }

    func primaryButton() -> some View {
        self
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.focusHeroGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func secondaryButton() -> some View {
        self
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(Color.focusAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.focusCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.focusAccent.opacity(0.35), lineWidth: 1)
            )
    }

    func focusScreenBackground() -> some View {
        self.background {
            Color.focusBackgroundGradient.ignoresSafeArea()
        }
    }

    @ViewBuilder
    func loadingOverlay(isLoading: Bool) -> some View {
        overlay {
            if isLoading {
                LoadingOverlay()
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isLoading)
    }
}
