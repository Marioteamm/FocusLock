import SwiftUI
import SwiftData

struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var coordinator = AppCoordinator.shared
    @ObservedObject private var motivation = MotivationManager.shared

    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            if FocusLockConfig.useMockScreenTime {
                previewModeBanner
            }

            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Головна", systemImage: selectedTab == 0 ? "house.fill" : "house")
                    }
                    .tag(0)
                    .accessibilityLabel("Головна")

                FocusSessionView()
                    .tabItem {
                        Label("Фокус", systemImage: "brain.head.profile")
                    }
                    .tag(1)
                    .accessibilityLabel("Фокус")

                StatsView()
                    .tabItem {
                        Label("Статистика", systemImage: selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
                    }
                    .tag(2)
                    .accessibilityLabel("Статистика")

                SettingsView()
                    .tabItem {
                        Label("Налаштування", systemImage: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                    }
                    .tag(3)
                    .accessibilityLabel("Налаштування")
            }
            .tint(Color.focusAccent)
            .preferredColorScheme(.dark)
            .onAppear {
                FocusTabBarStyle.apply()
                coordinator.bootstrap(modelContext: modelContext)
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    coordinator.refreshOnForeground(modelContext: modelContext)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .focusLockOpenFocusTab)) { _ in
                withAnimation(.focusQuick) { selectedTab = 1 }
            }
            .fullScreenCover(isPresented: $coordinator.showOnboarding) {
                OnboardingContainerView()
            }

            if let error = coordinator.globalError {
                VStack {
                    ErrorBanner(error: error) { coordinator.clearError() }
                        .padding(.top, 8)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(50)
            }

            if motivation.showCelebration, let milestone = motivation.celebrationMilestone {
                StreakCelebrationOverlay(milestone: milestone) {
                    motivation.dismissCelebration()
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(.focusSpring, value: motivation.showCelebration)
        .animation(.focusQuick, value: coordinator.globalError != nil)
    }

    private var previewModeBanner: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "eye.fill")
                Text("UI Preview — Screen Time вимкнено (DEBUG)")
                    .font(FocusFont.micro())
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.focusWarning, in: Capsule())
            .padding(.top, 6)
            Spacer()
        }
        .allowsHitTesting(false)
        .zIndex(20)
    }
}
