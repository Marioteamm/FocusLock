import SwiftUI
import SwiftData

struct SettingsView: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [AppSettings]
    @Query(sort: \AppLimit.createdAt) private var limits: [AppLimit]

    @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject private var streakManager = StreakManager.shared
    @State private var showDeleteAllConfirm = false

    private var settings: AppSettings {
        settingsQuery.first ?? SettingsRepository.shared.ensureSettings(context: modelContext)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    SettingsProfileHeader(
                        streak: streakManager.currentStreak,
                        longestStreak: streakManager.longestStreak,
                        appsCount: limits.filter(\.isEnabled).count
                    )
                    .padding(.horizontal, 4)

                    settingsGroup(title: "Ліміти") {
                        NavigationLink {
                            AppLimitsManagementView()
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "slider.horizontal.3")
                                    .foregroundStyle(Color.focusAccent)
                                    .frame(width: 28)
                                Text("Керування додатками")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(limits.count)")
                                    .font(FocusFont.caption())
                                    .foregroundStyle(Color.focusSecondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.focusSecondary.opacity(0.5))
                            }
                            .padding(.vertical, 6)
                        }
                        settingsRow(icon: "clock", title: "Ліміт за замовчуванням", value: viewModel.limitLabel(settings.defaultLimitMinutes))
                    }

                    settingsGroup(title: "За замовчуванням") {
                        VStack(alignment: .leading, spacing: 12) {
                            LimitPresetChips(selectedMinutes: defaultLimitBinding)
                        }
                        .padding(.vertical, 4)
                    }

                    if settings.hasSignedCommitment {
                        commitmentCard
                    }

                    settingsGroup(title: "Поведінка") {
                        toggleRow(
                            title: "Пауза перед імпульсом",
                            subtitle: "3 сек дихання перед бонусом +15 хв",
                            isOn: mindfulPauseBinding
                        )
                        toggleRow(title: "Вібрація", subtitle: "Тактильний відгук на дії", isOn: hapticsBinding)
                        toggleRow(title: "Суворий режим", subtitle: "Миттєве блокування при ліміті", isOn: strictBinding)
                        toggleRow(title: "Блок під час фокусу", subtitle: "Shield на обрані додатки", isOn: focusBlockBinding)
                    }

                    settingsGroup(title: "Увага") {
                        settingsRow(
                            icon: "wind",
                            title: "Свідомі паузи",
                            value: "\(settings.totalMindfulPauses)",
                            valueColor: .focusSuccess
                        )
                        settingsRow(
                            icon: "target",
                            title: "Намір дня",
                            value: settings.dailyIntention.title
                        )
                    }

                    settingsGroup(title: "Дозволи") {
                        settingsRow(
                            icon: "hourglass",
                            title: "Screen Time",
                            value: ScreenTimeService.shared.isAuthorized ? "Активно" : "Вимкнено",
                            valueColor: ScreenTimeService.shared.isAuthorized ? .focusSuccess : .focusDanger
                        )
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            settingsRow(icon: "gear", title: "Налаштування iOS", value: "Відкрити")
                        }
                        .buttonStyle(.plain)
                    }

                    settingsGroup(title: "Дані") {
                        Button { viewModel.resetOnboarding(context: modelContext) } label: {
                            settingsRow(icon: "arrow.counterclockwise", title: "Показати онбординг", value: "")
                        }
                        .buttonStyle(.plain)

                        Button { showDeleteAllConfirm = true } label: {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundStyle(Color.focusDanger)
                                    .frame(width: 28)
                                Text("Видалити всі ліміти")
                                    .foregroundStyle(Color.focusDanger)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }

                    Text("FocusLock 1.0 · Зроблено для здорового цифрового життя")
                        .font(FocusFont.micro())
                        .foregroundStyle(Color.focusSecondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .focusScreenBackground()
            .navigationTitle("Налаштування")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                _ = SettingsRepository.shared.ensureSettings(context: modelContext)
            }
            .confirmationDialog("Видалити всі ліміти?", isPresented: $showDeleteAllConfirm, titleVisibility: .visible) {
                Button("Видалити все", role: .destructive) {
                    viewModel.deleteAllLimits(context: modelContext)
                }
                Button("Скасувати", role: .cancel) {}
            }
        }
    }

    private var commitmentCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(Color.focusSuccess)
            VStack(alignment: .leading, spacing: 6) {
                Text("Ви дали обіцянку собі")
                    .font(FocusFont.headline())
                    .foregroundStyle(.white)
                Text("«\(settings.dailyIntention.affirmation)»")
                    .font(FocusFont.caption())
                    .foregroundStyle(Color.focusSecondary)
                    .italic()
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.focusSuccess.opacity(0.1), Color.focusCard],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }

    private func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(FocusFont.micro())
                .foregroundStyle(Color.focusSecondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .padding(16)
            .focusCard()
        }
    }

    private func settingsRow(icon: String, title: String, value: String, valueColor: Color = .focusSecondary) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(Color.focusAccent)
                .frame(width: 28)
            Text(title)
                .foregroundStyle(.white)
            Spacer()
            if !value.isEmpty {
                Text(value)
                    .font(FocusFont.caption())
                    .foregroundStyle(valueColor)
            }
            if value.isEmpty == false && icon != "gear" {
                EmptyView()
            }
        }
        .padding(.vertical, 6)
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).foregroundStyle(.white)
                Text(subtitle)
                    .font(FocusFont.caption())
                    .foregroundStyle(Color.focusSecondary)
            }
        }
        .tint(Color.focusAccent)
        .padding(.vertical, 4)
    }

    private var defaultLimitBinding: Binding<Int> {
        Binding(
            get: { settings.defaultLimitMinutes },
            set: { viewModel.updateDefaultLimit($0, context: modelContext) }
        )
    }

    private var hapticsBinding: Binding<Bool> {
        Binding(get: { settings.hapticsEnabled }, set: { viewModel.toggleHaptics($0, context: modelContext) })
    }

    private var strictBinding: Binding<Bool> {
        Binding(get: { settings.strictModeEnabled }, set: { viewModel.toggleStrictMode($0, context: modelContext) })
    }

    private var focusBlockBinding: Binding<Bool> {
        Binding(get: { settings.focusSessionBlocksApps }, set: { viewModel.toggleFocusBlocking($0, context: modelContext) })
    }

    private var mindfulPauseBinding: Binding<Bool> {
        Binding(
            get: { settings.mindfulPauseEnabled },
            set: { newValue in
                settings.mindfulPauseEnabled = newValue
                try? modelContext.save()
            }
        )
    }
}
