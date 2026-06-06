import SwiftUI

struct LoadingOverlay: View {
    var message: String = "Завантаження…"

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Color.focusAccent)

                Text(message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.focusSecondary)
            }
            .padding(28)
            .focusGlassCard()
        }
    }
}
