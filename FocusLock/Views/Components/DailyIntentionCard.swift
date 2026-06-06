import SwiftUI
import SwiftData

struct DailyIntentionCard: View {

    @Bindable var settings: AppSettings
    var streak: Int
    var dailyProgress: Double

    @State private var showPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: settings.dailyIntention.icon)
                    .foregroundStyle(Color.focusSuccess)
                Text("Намір дня")
                    .font(FocusFont.caption())
                    .foregroundStyle(Color.focusSecondary)
                Spacer()
                Button {
                    withAnimation(.focusSpring) { showPicker.toggle() }
                } label: {
                    Text("Змінити")
                        .font(FocusFont.micro())
                        .foregroundStyle(Color.focusAccent)
                }
            }

            Text(settings.dailyIntention.affirmation)
                .font(FocusFont.headline())
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(MindfulCopy.dailyTip(streak: streak, progress: dailyProgress))
                .font(FocusFont.caption())
                .foregroundStyle(Color.focusSecondary.opacity(0.9))
                .italic()

            if showPicker {
                intentionPicker
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.focusSuccess.opacity(0.08), Color.focusCard],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.focusSuccess.opacity(0.2), lineWidth: 1)
        )
    }

    private var intentionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MindfulCopy.DailyIntention.allCases) { intention in
                    Button {
                        settings.dailyIntentionRaw = intention.rawValue
                        settings.updatedAt = Date()
                        HapticFeedback.selection()
                        withAnimation(.focusSpring) { showPicker = false }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: intention.icon)
                            Text(intention.title)
                                .font(FocusFont.micro())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            settings.dailyIntention == intention
                                ? Color.focusSuccess.opacity(0.25)
                                : Color.focusDivider.opacity(0.5),
                            in: Capsule()
                        )
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
