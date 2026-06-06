import SwiftUI

/// DEBUG-only substitute for FamilyActivityPicker (no entitlement).
struct MockAppPickerView: View {

    @Binding var selectedNames: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "eye.trianglebadge.exclamationmark")
                    .foregroundStyle(Color.focusWarning)
                Text("Режим перегляду UI — демо-додатки без Screen Time API")
                    .font(FocusFont.caption())
                    .foregroundStyle(Color.focusSecondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.focusWarning.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            ForEach(FocusLockConfig.demoAppNames, id: \.self) { name in
                Button {
                    if selectedNames.contains(name) {
                        selectedNames.remove(name)
                    } else {
                        selectedNames.insert(name)
                    }
                    HapticFeedback.selection()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: icon(for: name))
                            .font(.title2)
                            .foregroundStyle(Color.focusAccent)
                            .frame(width: 36)

                        Text(name)
                            .font(FocusFont.headline())
                            .foregroundStyle(.white)

                        Spacer()

                        Image(systemName: selectedNames.contains(name) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(
                                selectedNames.contains(name) ? Color.focusSuccess : Color.focusSecondary
                            )
                    }
                    .padding(14)
                    .background(Color.focusCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    private func icon(for name: String) -> String {
        switch name {
        case "Instagram": return "camera.fill"
        case "TikTok": return "music.note"
        case "Safari": return "safari.fill"
        case "YouTube": return "play.rectangle.fill"
        case "Telegram": return "paperplane.fill"
        default: return "app.fill"
        }
    }
}
