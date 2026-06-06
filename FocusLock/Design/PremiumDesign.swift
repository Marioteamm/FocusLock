import SwiftUI

// MARK: - Typography

enum FocusFont {
    static func hero(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func title() -> Font { .system(size: 22, weight: .bold, design: .rounded) }
    static func headline() -> Font { .system(size: 17, weight: .semibold) }
    static func body() -> Font { .system(size: 16, weight: .regular) }
    static func caption() -> Font { .system(size: 13, weight: .medium) }
    static func micro() -> Font { .system(size: 11, weight: .semibold) }
}

// MARK: - Section header

struct FocusSectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(FocusFont.headline())
                .foregroundStyle(.white)
            if let subtitle {
                Text(subtitle)
                    .font(FocusFont.caption())
                    .foregroundStyle(Color.focusSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Limit preset chips

struct LimitPresetChips: View {
    @Binding var selectedMinutes: Int
    var options: [Int] = [15, 30, 45, 60, 90, 120]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(options, id: \.self) { minutes in
                    Button {
                        withAnimation(.focusQuick) { selectedMinutes = minutes }
                        HapticFeedback.selection()
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(minutes)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                            Text("хв")
                                .font(FocusFont.micro())
                                .opacity(0.8)
                        }
                        .foregroundStyle(selectedMinutes == minutes ? .white : Color.focusSecondary)
                        .frame(width: 64, height: 64)
                        .background {
                            if selectedMinutes == minutes {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.focusHeroGradient)
                            } else {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.focusCard)
                            }
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    selectedMinutes == minutes ? Color.clear : Color.focusDivider,
                                    lineWidth: 1
                                )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

// MARK: - Primary CTA

struct FocusPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().tint(.white)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(Color.focusHeroGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.focusAccent.opacity(0.35), radius: 16, y: 8)
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
        .pressableScale()
    }
}

// MARK: - Daily score ring

struct DailyScoreRing: View {
    let progress: Double
    let usedMinutes: Int
    let limitMinutes: Int
    var label: String = "Сьогодні"

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.focusDivider.opacity(0.5), lineWidth: 8)
                    .frame(width: 88, height: 88)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [.focusAccent, .focusAccentSecondary, .focusSuccess],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 88, height: 88)
                    .rotationEffect(.degrees(-90))
                    .animation(.focusSpring, value: progress)

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(FocusFont.caption())
                    .foregroundStyle(Color.focusSecondary)
                Text("\(usedMinutes) / \(limitMinutes) хв")
                    .font(FocusFont.title())
                    .foregroundStyle(.white)
                Text(statusText)
                    .font(FocusFont.micro())
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15), in: Capsule())
            }

            Spacer()
        }
    }

    private var statusText: String {
        switch progress {
        case 0..<0.6: return "Відмінно"
        case 0.6..<0.85: return "Обережно"
        default: return progress >= 1 ? "Ліміт" : "Майже ліміт"
        }
    }

    private var statusColor: Color {
        switch progress {
        case 0..<0.6: return .focusSuccess
        case 0..<0.85: return .focusWarning
        default: return .focusDanger
        }
    }
}

// MARK: - Tab bar appearance

enum FocusTabBarStyle {
    static func apply() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.09, alpha: 1)

        let normal = UIColor(red: 0.45, green: 0.46, blue: 0.52, alpha: 1)
        let selected = UIColor(red: 0.45, green: 0.55, blue: 1.0, alpha: 1)

        appearance.stackedLayoutAppearance.normal.iconColor = normal
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normal]
        appearance.stackedLayoutAppearance.selected.iconColor = selected
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selected]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Settings profile header

struct SettingsProfileHeader: View {
    let streak: Int
    let longestStreak: Int
    let appsCount: Int

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.focusHeroGradient)
                    .frame(width: 72, height: 72)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 4) {
                Text("FocusLock")
                    .font(FocusFont.title())
                    .foregroundStyle(.white)
                Text("Преміум контроль екранного часу")
                    .font(FocusFont.caption())
                    .foregroundStyle(Color.focusSecondary)
            }

            HStack(spacing: 0) {
                profileStat(value: "\(streak)", label: "Серія")
                Divider().frame(height: 32).background(Color.focusDivider)
                profileStat(value: "\(longestStreak)", label: "Рекорд")
                Divider().frame(height: 32).background(Color.focusDivider)
                profileStat(value: "\(appsCount)", label: "Додатки")
            }
            .padding(.vertical, 12)
            .background(Color.focusCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(.vertical, 8)
    }

    private func profileStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(FocusFont.micro())
                .foregroundStyle(Color.focusSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
