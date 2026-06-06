import SwiftUI
import SwiftData

struct StatsView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \AppLimit.createdAt, order: .forward)
    private var limits: [AppLimit]

    @StateObject private var viewModel = StatsViewModel()
    @ObservedObject private var streakManager = StreakManager.shared

    private var wellnessScore: Int {
        MotivationManager.shared.wellnessScore(
            limits: limits.filter(\.isEnabled),
            streak: streakManager.currentStreak,
            focusMinutes: viewModel.totalFocusMinutes,
            progress: averageProgress
        )
    }

    private var averageProgress: Double {
        let active = limits.filter(\.isEnabled)
        guard !active.isEmpty else { return 0 }
        return active.map { viewModel.usageProgress(for: $0) }.reduce(0, +) / Double(active.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    streakHero
                        .focusAppear()

                    if limits.isEmpty {
                        statsEmptyState
                    } else {
                        WellnessScoreCard(
                            score: wellnessScore,
                            minutesReclaimed: MotivationManager.shared.estimatedMinutesReclaimedToday(limits: limits),
                            focusMinutes: viewModel.totalFocusMinutes
                        )
                        .focusAppear(delay: 0.02)
                        HabitGrowthTreeView(
                            streak: streakManager.currentStreak,
                            longestStreak: streakManager.longestStreak
                        )
                        .focusAppear(delay: 0.04)
                    }

                    if !limits.isEmpty {
                        insightCard
                            .focusAppear(delay: 0.06)
                        summaryGrid
                            .focusAppear(delay: 0.08)
                    }
                    weeklyChartSection
                    appsBreakdown
                    resetSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .focusScreenBackground()
            .navigationTitle("Статистика")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.refresh(limits: limits, context: modelContext)
            }
        }
        .onAppear { viewModel.refresh(limits: limits, context: modelContext) }
        .onChange(of: limits.count) { _, _ in
            viewModel.refresh(limits: limits, context: modelContext)
        }
        .loadingOverlay(isLoading: viewModel.loadState == .loading)
    }

    private var statsEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 44))
                .foregroundStyle(Color.focusAccent.opacity(0.5))
            Text("Додайте ліміти на головній")
                .font(FocusFont.headline())
                .foregroundStyle(.white)
            Text("Тоді з’являться індекс уваги, дерево звички та тижневий графік.")
                .font(FocusFont.caption())
                .foregroundStyle(Color.focusSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .focusCard()
    }

    private var streakHero: some View {
        HStack(spacing: 20) {
            StreakBadgeView(streak: streakManager.currentStreak)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Рекорд")
                            .font(FocusFont.micro())
                            .foregroundStyle(Color.focusSecondary)
                        Text("\(streakManager.longestStreak) днів")
                            .font(FocusFont.headline())
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Фокус")
                            .font(FocusFont.micro())
                            .foregroundStyle(Color.focusSecondary)
                        Text("\(viewModel.totalFocusMinutes) хв")
                            .font(FocusFont.headline())
                            .foregroundStyle(Color.focusSuccess)
                    }
                }

                ProgressView(value: streakProgress)
                    .tint(Color.focusStreak)
            }
        }
        .padding(20)
        .focusGlassCard()
    }

    private var streakProgress: Double {
        let goal = 7.0
        return min(1, Double(streakManager.currentStreak) / goal)
    }

    private var insightCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(Color.focusAccent)

            VStack(alignment: .leading, spacing: 6) {
                Text("Порада дня")
                    .font(FocusFont.caption())
                    .foregroundStyle(Color.focusAccent)
                Text(viewModel.insightMessage)
                    .font(FocusFont.body())
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.focusAccent.opacity(0.12), Color.focusCard],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.focusAccent.opacity(0.2), lineWidth: 1)
        )
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCardView(title: "Екранний час", value: viewModel.formattedTotalTime, icon: "clock.fill", color: .focusAccent)
            StatCardView(title: "Блокування", value: "\(viewModel.totalBlockCount)", icon: "lock.fill", color: .focusDanger)
            StatCardView(title: "Бонус +15", value: viewModel.totalBonusCount > 0 ? "Використано" : "Доступно", icon: "plus.circle.fill", color: .focusWarning)
            StatCardView(title: "Під контролем", value: "\(limits.filter(\.isEnabled).count)", icon: "app.badge.checkmark", color: .focusSuccess)
        }
    }

    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FocusSectionHeader(title: "Тижневий огляд", subtitle: "Хвилини використання по днях")

            if limits.isEmpty {
                emptyChartPlaceholder
            } else {
                WeeklyChartView(data: viewModel.weeklyChart)
                    .padding(16)
                    .focusCard()
            }
        }
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis.ascending")
                .font(.largeTitle)
                .foregroundStyle(Color.focusSecondary.opacity(0.4))
            Text("Додайте додатки для статистики")
                .font(FocusFont.caption())
                .foregroundStyle(Color.focusSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .focusCard()
    }

    @ViewBuilder
    private var appsBreakdown: some View {
        if limits.isEmpty {
            ContentUnavailableView(
                "Немає даних",
                systemImage: "chart.bar.xaxis",
                description: Text("Оберіть додатки на головному екрані")
            )
        } else {
            VStack(alignment: .leading, spacing: 12) {
                FocusSectionHeader(title: "Деталі по додатках")

                ForEach(limits) { limit in
                    appStatRow(limit: limit)
                }
            }
        }
    }

    private func appStatRow(limit: AppLimit) -> some View {
        let progress = viewModel.usageProgress(for: limit)
        let color: Color = {
            if !limit.isEnabled { return .focusSecondary }
            switch progress {
            case 0..<0.6: return .focusSuccess
            case 0.6..<0.85: return .focusWarning
            default: return .focusDanger
            }
        }()

        return VStack(spacing: 14) {
            HStack(spacing: 12) {
                AppTokenIconView(tokenData: limit.tokenData, size: 40)
                AppTokenLabelView(tokenData: limit.tokenData, fallbackName: limit.appName)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(FocusFont.headline())
                    .foregroundStyle(color)
            }

            ProgressRingView(progress: limit.isEnabled ? progress : 0, color: color, height: 6)

            HStack {
                Text(viewModel.usedTimeString(for: limit))
                Text("з \(limit.effectiveLimitMinutes) хв")
                Spacer()
                if !limit.isEnabled {
                    Text("Пауза").font(FocusFont.micro()).foregroundStyle(Color.focusSecondary)
                } else if limit.bonusUsedToday {
                    Label("Бонус", systemImage: "plus.circle.fill")
                        .font(FocusFont.micro())
                        .foregroundStyle(Color.focusWarning)
                }
            }
            .font(FocusFont.caption())
            .foregroundStyle(Color.focusSecondary)
        }
        .padding(16)
        .focusCard()
        .opacity(limit.isEnabled ? 1 : 0.65)
    }

    private var resetSection: some View {
        HStack(spacing: 14) {
            Image(systemName: "moon.stars.fill")
                .font(.title2)
                .foregroundStyle(Color.focusAccent)

            VStack(alignment: .leading, spacing: 4) {
                Text("Скидання о півночі")
                    .font(FocusFont.caption())
                    .foregroundStyle(Color.focusSecondary)
                Text(viewModel.timeUntilReset)
                    .font(FocusFont.headline())
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(18)
        .focusCard()
    }
}
