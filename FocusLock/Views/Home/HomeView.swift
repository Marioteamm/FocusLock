import SwiftUI
import SwiftData
import FamilyControls

struct HomeView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \AppLimit.createdAt, order: .forward)
    private var limits: [AppLimit]

    @Query private var settingsQuery: [AppSettings]

    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var streakManager = StreakManager.shared

    private var activeLimits: [AppLimit] { limits.filter(\.isEnabled) }

    private var settings: AppSettings {
        settingsQuery.first ?? SettingsRepository.shared.ensureSettings(context: modelContext)
    }

    private var warningActive: Bool {
        AppGroupConstants.groupDefaults.bool(forKey: AppGroupConstants.warningActiveKey)
    }

    private var dailyProgress: (used: Int, limit: Int, progress: Double) {
        let usage = UsageTrackingManager.shared
        let used = activeLimits.reduce(0) {
            $0 + usage.getUsedTime(bundleId: $1.bundleIdentifier) / 60
        }
        let limit = max(1, activeLimits.reduce(0) { $0 + $1.limitMinutes })
        let progress = min(1, Double(used) / Double(limit))
        return (used, limit, progress)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.focusBackgroundGradient.ignoresSafeArea()

                if limits.isEmpty {
                    EmptyStateView {
                        Task { await viewModel.requestAuthorizationAndShowPicker() }
                    }
                } else {
                    mainContent
                }

            }
            .navigationTitle("FocusLock")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .sheet(isPresented: $viewModel.showingActivityPicker) {
                AppSelectionFlowView(
                    selection: $viewModel.activitySelection,
                    defaultLimitMinutes: settings.defaultLimitMinutes
                ) { selection, _ in
                    viewModel.saveSelection(selection, context: modelContext)
                    viewModel.startMonitoringAfterSelection(selection, context: modelContext)
                }
            }
            .sheet(isPresented: $viewModel.showingLimitsManager) {
                NavigationStack { AppLimitsManagementView() }
            }
            .sheet(item: $viewModel.selectedLimit) { limit in
                EditAppLimitSheet(
                    limit: limit,
                    onSave: { minutes in
                        SettingsViewModel().updateLimit(for: limit, minutes: minutes, context: modelContext)
                        viewModel.selectedLimit = nil
                    },
                    onCancel: { viewModel.selectedLimit = nil }
                )
            }
            .alert("Помилка авторизації", isPresented: $viewModel.showAuthError) {
                Button("Зрозуміло", role: .cancel) {}
                Button("Налаштування") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .loadingOverlay(isLoading: viewModel.loadState == .loading)
        .onAppear {
            FocusSessionManager.shared.bind(context: modelContext)
            viewModel.syncFromExtensions(context: modelContext)
            UsageHistoryService.shared.archiveTodayUsage(limits: limits, context: modelContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            viewModel.syncFromExtensions(context: modelContext)
        }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                dailyHero
                    .focusAppear()

                DailyIntentionCard(
                    settings: settings,
                    streak: streakManager.currentStreak,
                    dailyProgress: dailyProgress.progress
                )
                .focusAppear(delay: 0.03)
                .onChange(of: settings.dailyIntentionRaw) { _, _ in
                    try? modelContext.save()
                }

                focusQuickStart
                    .focusAppear(delay: 0.04)

                if warningActive {
                    warningBanner.focusAppear(delay: 0.06)
                }

                quickActions.focusAppear(delay: 0.08)

                if activeLimits.isEmpty && !limits.isEmpty {
                    pausedLimitsBanner
                }

                LazyVStack(spacing: 14) {
                    ForEach(Array(limits.enumerated()), id: \.element.id) { index, limit in
                        AppLimitCard(
                            limit: limit,
                            onEditLimit: { selected in
                                viewModel.selectedLimit = selected
                            },
                            onBonusTime: { bonusLimit in
                                viewModel.useBonusTime(for: bonusLimit, context: modelContext)
                            },
                            onToggleEnabled: { lim, enabled in
                                lim.isEnabled = enabled
                                try? modelContext.save()
                                let active = limits.filter { $0.id == lim.id ? enabled : $0.isEnabled }
                                do {
                                    try AppBlockingManager.shared.startMonitoring(limits: active)
                                } catch let error as AppError {
                                    AppCoordinator.shared.presentError(error)
                                } catch {
                                    AppCoordinator.shared.presentError(.monitoringFailed(error.localizedDescription))
                                }
                            }
                        )
                        .focusAppear(delay: 0.04 * Double(index + 3))
                        .id("\(limit.id)-\(viewModel.refreshTrigger)")
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
    }

    private var dailyHero: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(FocusFont.caption())
                        .foregroundStyle(Color.focusSecondary)
                    Text(formattedDate)
                        .font(FocusFont.headline())
                        .foregroundStyle(.white)
                }
                Spacer()
                CountdownView()
            }

            DailyScoreRing(
                progress: dailyProgress.progress,
                usedMinutes: dailyProgress.used,
                limitMinutes: dailyProgress.limit
            )

            HStack {
                StreakBadgeView(streak: streakManager.currentStreak, compact: true)
                Spacer()
                Label("\(activeLimits.count) активних", systemImage: "app.badge.checkmark")
                    .font(FocusFont.caption())
                    .foregroundStyle(Color.focusSecondary)
            }
        }
        .padding(20)
        .focusGlassCard()
    }

    private var focusQuickStart: some View {
        Button {
            NotificationCenter.default.post(name: .focusLockOpenFocusTab, object: nil)
            HapticFeedback.selection()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.focusHeroGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Почати фокус-сесію")
                        .font(FocusFont.headline())
                        .foregroundStyle(.white)
                    Text("25 хв глибокої роботи")
                        .font(FocusFont.caption())
                        .foregroundStyle(Color.focusSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.focusSecondary)
            }
            .padding(16)
            .focusCard()
        }
        .buttonStyle(.plain)
    }

    private var warningBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.badge.fill")
                .foregroundStyle(Color.focusWarning)
            VStack(alignment: .leading, spacing: 2) {
                Text("Майже ліміт")
                    .font(FocusFont.headline())
                    .foregroundStyle(.white)
                Text("Залишилось менше 5 хвилин на одному з додатків")
                    .font(FocusFont.caption())
                    .foregroundStyle(Color.focusSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.focusWarning.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.focusWarning.opacity(0.3), lineWidth: 1)
        )
    }

    private var pausedLimitsBanner: some View {
        HStack {
            Image(systemName: "pause.circle.fill")
                .foregroundStyle(Color.focusSecondary)
            Text("Усі ліміти призупинено")
                .font(FocusFont.caption())
                .foregroundStyle(Color.focusSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .focusCard()
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            quickAction(title: "Ліміти", icon: "slider.horizontal.3") {
                viewModel.showingLimitsManager = true
            }
            quickAction(title: "Додати", icon: "plus", accent: true) {
                Task { await viewModel.requestAuthorizationAndShowPicker() }
            }
        }
    }

    private func quickAction(title: String, icon: String, accent: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(FocusFont.caption())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    accent ? Color.focusAccent.opacity(0.18) : Color.focusCard,
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
        }
        .foregroundStyle(accent ? Color.focusAccent : .white)
        .buttonStyle(.plain)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Task { await viewModel.requestAuthorizationAndShowPicker() }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.focusAccent)
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Доброго ранку"
        case 12..<17: return "Доброго дня"
        case 17..<22: return "Доброго вечора"
        default: return "Доброї ночі"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "d MMMM, EEEE"
        return formatter.string(from: Date())
    }
}

extension Notification.Name {
    static let focusLockOpenFocusTab = Notification.Name("focusLockOpenFocusTab")
}
