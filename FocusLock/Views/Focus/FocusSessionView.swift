import SwiftUI
import SwiftData

struct FocusSessionView: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [AppSettings]

    @StateObject private var viewModel = FocusSessionViewModel()
    @ObservedObject private var sessionManager = FocusSessionManager.shared

    @State private var sessionGoal: String = ""
    @State private var showPreSessionBreath = false

    private let intentions = ["Робота", "Навчання", "Читання", "Відпочинок без екрану"]

    private var remainingFormatted: String {
        let s = sessionManager.remainingSeconds
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    private var settings: AppSettings? { settingsQuery.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    if sessionManager.isSessionActive {
                        activeSessionCard
                    } else {
                        intentionPicker
                        presetPicker
                        blockingToggle
                        startButton
                    }

                    todaySummary
                    recentSessionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .focusScreenBackground()
            .navigationTitle("Фокус")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog(
                "Скасувати сесію?",
                isPresented: $viewModel.showCancelConfirm,
                titleVisibility: .visible
            ) {
                Button("Скасувати сесію", role: .destructive) {
                    viewModel.cancel(context: modelContext)
                }
                Button("Продовжити", role: .cancel) {}
            }
        }
        .onAppear { viewModel.bind(context: modelContext) }
        .loadingOverlay(isLoading: viewModel.loadState == .loading)
        .overlay(alignment: .top) {
            if case .failed(let error) = viewModel.loadState {
                ErrorBanner(error: error) {
                    viewModel.loadState = .loaded
                }
                .padding(.top, 8)
            }
        }
        .fullScreenCover(isPresented: $showPreSessionBreath) {
            BreathingPauseView(
                title: "Підготуйтесь",
                subtitle: MindfulCopy.focusSessionStartMessage(minutes: viewModel.selectedMinutes),
                onComplete: {
                    showPreSessionBreath = false
                    if settings?.mindfulPauseEnabled == true {
                        recordMindfulPause()
                    }
                    beginSession()
                },
                onCancel: { showPreSessionBreath = false }
            )
        }
    }

    private func beginSession() {
        viewModel.startSession(
            context: modelContext,
            blockApps: settings?.focusSessionBlocksApps ?? true,
            goal: sessionGoal
        )
    }

    private func recordMindfulPause() {
        let s = settings ?? SettingsRepository.shared.ensureSettings(context: modelContext)
        s.totalMindfulPauses += 1
        s.updatedAt = Date()
        try? modelContext.save()
    }

    private var activeSessionCard: some View {
        VStack(spacing: 28) {
            Text(sessionGoal.isEmpty ? "Фокус-сесія" : sessionGoal)
                .font(FocusFont.caption())
                .foregroundStyle(Color.focusSecondary)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.focusAccent.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)

                Circle()
                    .stroke(Color.focusDivider.opacity(0.4), lineWidth: 12)
                    .frame(width: 220, height: 220)

                Circle()
                    .trim(from: 0, to: sessionManager.progress)
                    .stroke(
                        Color.focusHeroGradient,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .animation(.focusQuick, value: sessionManager.progress)

                VStack(spacing: 8) {
                    Text(remainingFormatted)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    Text("залишилось")
                        .font(FocusFont.caption())
                        .foregroundStyle(Color.focusSecondary)

                    Text("Залишайтесь у Flow")
                        .font(FocusFont.micro())
                        .foregroundStyle(Color.focusAccent.opacity(0.8))
                        .padding(.top, 4)
                }
            }
            .pulseWhenActive(true)

            HStack(spacing: 12) {
                Button("Скасувати") { viewModel.showCancelConfirm = true }
                    .secondaryButton()
                Button("Завершити") { viewModel.completeEarly(context: modelContext) }
                    .primaryButton()
            }
        }
        .padding(28)
        .focusGlassCard()
    }

    private var intentionPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            FocusSectionHeader(title: "Намір сесії", subtitle: "Що ви робите зараз?")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(intentions, id: \.self) { item in
                        Button {
                            sessionGoal = item
                            HapticFeedback.selection()
                        } label: {
                            Text(item)
                                .font(FocusFont.caption())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    sessionGoal == item
                                        ? Color.focusAccent.opacity(0.25)
                                        : Color.focusCard,
                                    in: Capsule()
                                )
                                .overlay(
                                    Capsule().stroke(
                                        sessionGoal == item ? Color.focusAccent : Color.clear,
                                        lineWidth: 1.5
                                    )
                                )
                        }
                        .foregroundStyle(.white)
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .focusCard()
    }

    private var presetPicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            FocusSectionHeader(title: "Тривалість", subtitle: "Рекомендовано: 25 хв (Pomodoro)")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 10)], spacing: 10) {
                ForEach(viewModel.presets, id: \.self) { minutes in
                    Button {
                        viewModel.selectedMinutes = minutes
                        HapticFeedback.selection()
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(minutes)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                            Text("хв")
                                .font(FocusFont.micro())
                        }
                        .foregroundStyle(viewModel.selectedMinutes == minutes ? .white : Color.focusSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            if viewModel.selectedMinutes == minutes {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.focusHeroGradient)
                            } else {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.focusCardElevated)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .focusCard()
    }

    private var blockingToggle: some View {
        Toggle(isOn: Binding(
            get: { settings?.focusSessionBlocksApps ?? true },
            set: { newValue in
                if let s = settings {
                    s.focusSessionBlocksApps = newValue
                    try? modelContext.save()
                }
            }
        )) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Блокувати обрані додатки")
                    .font(FocusFont.headline())
                    .foregroundStyle(.white)
                Text("Рекомендовано для глибокого фокусу")
                    .font(FocusFont.caption())
                    .foregroundStyle(Color.focusSecondary)
            }
        }
        .tint(Color.focusAccent)
        .padding(18)
        .focusCard()
    }

    private var startButton: some View {
        FocusPrimaryButton(title: "Почати \(viewModel.selectedMinutes) хв фокусу", icon: "play.fill") {
            if settings?.mindfulPauseEnabled ?? true {
                showPreSessionBreath = true
            } else {
                beginSession()
            }
        }
    }

    private var todaySummary: some View {
        HStack(spacing: 12) {
            StatCardView(
                title: "Фокус сьогодні",
                value: "\(viewModel.totalMinutesToday(context: modelContext)) хв",
                icon: "brain.head.profile",
                color: .focusAccent
            )
            StatCardView(
                title: "Серія",
                value: "\(StreakManager.shared.currentStreak) дн.",
                icon: "flame.fill",
                color: .focusStreak
            )
        }
    }

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FocusSectionHeader(title: "Історія", subtitle: "Останні завершені сесії")

            let sessions = viewModel.recentSessions(context: modelContext)
                .filter { $0.status == .completed }
                .prefix(5)

            if sessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.largeTitle)
                        .foregroundStyle(Color.focusSecondary.opacity(0.5))
                    Text("Завершіть першу сесію — тут з’явиться історія")
                        .font(FocusFont.caption())
                        .foregroundStyle(Color.focusSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .focusCard()
            } else {
                ForEach(Array(sessions), id: \.id) { session in
                    HStack(spacing: 14) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Color.focusSuccess)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.sessionGoal.isEmpty ? "Фокус-сесія" : session.sessionGoal)
                                .font(FocusFont.headline())
                                .foregroundStyle(.white)
                            Text("\(max(1, session.elapsedSeconds / 60)) хв з \(session.plannedMinutes)")
                                .font(FocusFont.micro())
                                .foregroundStyle(Color.focusSecondary)
                            if let end = session.endedAt {
                                Text(end, style: .relative)
                                    .font(FocusFont.micro())
                                    .foregroundStyle(Color.focusSecondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(14)
                    .focusCard()
                }
            }
        }
    }
}
