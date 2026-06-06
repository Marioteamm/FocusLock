import SwiftUI
import SwiftData
import FamilyControls

struct OnboardingContainerView: View {

    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var mockSelectedApps: Set<String> = Set(FocusLockConfig.demoAppNames.prefix(3))

    var body: some View {
        ZStack {
            Color.focusBackgroundGradient.ignoresSafeArea()

            Circle()
                .fill(Color.focusAccent.opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(y: -140)

            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                Group {
                    switch viewModel.currentPage {
                    case 0: welcomePage
                    case 1: psychologyPage
                    case 2: featuresPage
                    case 3: permissionPage
                    case 4: pickerPage
                    case 5: limitPage
                    default: commitmentPage
                    }
                }
                .id(viewModel.currentPage)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
                .animation(.focusSpring, value: viewModel.currentPage)

                bottomBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
        }
        .loadingOverlay(isLoading: viewModel.loadState == .loading)
        .overlay(alignment: .top) {
            if case .failed(let error) = viewModel.loadState {
                ErrorBanner(error: error) {
                    viewModel.loadState = .loaded
                }
                .padding(.top, 8)
            }
        }
    }

    private var headerBar: some View {
        HStack(spacing: 12) {
            if viewModel.currentPage > 0 {
                Button {
                    viewModel.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color.focusSecondary)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Назад")
            } else {
                Color.clear.frame(width: 32, height: 32)
            }

            HStack(spacing: 6) {
                ForEach(0..<viewModel.pageCount, id: \.self) { index in
                    Capsule()
                        .fill(index <= viewModel.currentPage ? Color.focusAccent : Color.focusDivider)
                        .frame(width: index == viewModel.currentPage ? 20 : 6, height: 4)
                }
            }
            .frame(maxWidth: .infinity)

            if viewModel.currentPage >= 1 && viewModel.currentPage <= 2 {
                Button("Пропустити") {
                    withAnimation(.focusSpring) { viewModel.currentPage = 3 }
                }
                .font(FocusFont.caption())
                .foregroundStyle(Color.focusSecondary)
                .accessibilityLabel("Пропустити вступ")
            } else {
                Color.clear.frame(width: 60, height: 32)
            }
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 76))
                .foregroundStyle(Color.focusHeroGradient)
                .symbolEffect(.pulse.byLayer)

            VStack(spacing: 10) {
                Text("Поверніть свою увагу")
                    .font(FocusFont.hero(32))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                Text("Межі, пауза перед імпульсом і фокус — у одному місці.")
                    .font(FocusFont.body())
                    .foregroundStyle(Color.focusSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var psychologyPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Чому це важко?")
                    .font(FocusFont.title())
                    .foregroundStyle(.white)
                    .padding(.top, 20)

                dopamineCard(
                    icon: "bolt.fill",
                    title: "Дофамінова петля",
                    body: "Стрічка навчає мозок очікувати нагороду. Кожен скрол — мікродоза."
                )
                dopamineCard(
                    icon: "hourglass",
                    title: "Втрата часу",
                    body: "Середній користувач втрачає 3+ години на день. Це 45 днів на рік."
                )
                dopamineCard(
                    icon: "leaf.fill",
                    title: "Рішення FocusLock",
                    body: "Межі + пауза + фокус = менше імпульсів, більше життя."
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private func dopamineCard(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.focusAccent)
                .frame(width: 44)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(FocusFont.headline())
                    .foregroundStyle(.white)
                Text(body)
                    .font(FocusFont.caption())
                    .foregroundStyle(Color.focusSecondary)
            }
        }
        .padding(16)
        .focusCard()
    }

    private var featuresPage: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("Ваш інструментарій")
                    .font(FocusFont.title())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)

                featureRow(icon: "wind", title: "Пауза перед імпульсом", subtitle: "3 секунди дихання перед імпульсом")
                featureRow(icon: "tree.fill", title: "Дерево звички", subtitle: "Як Roots — росте з кожним днем")
                featureRow(icon: "flame.fill", title: "Серії та нагороди", subtitle: "Як Jomo — мотивація без провини")
                featureRow(icon: "lock.shield", title: "Розумний Shield", subtitle: "Блокування з повагою до вашого часу")
            }
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.focusAccent)
                .frame(width: 48, height: 48)
                .background(Color.focusAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(FocusFont.headline()).foregroundStyle(.white)
                Text(subtitle).font(FocusFont.caption()).foregroundStyle(Color.focusSecondary)
            }
            Spacer()
        }
        .padding(14)
        .focusCard()
    }

    private var permissionPage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "hourglass.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(Color.focusAccent)
            Text("Screen Time")
                .font(FocusFont.title())
                .foregroundStyle(.white)
            Text("Потрібен для лімітів і блокування. Дані не покидають ваш iPhone.")
                .font(FocusFont.body())
                .foregroundStyle(Color.focusSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            if case .failed(let error) = viewModel.loadState {
                Text(error.localizedDescription)
                    .font(FocusFont.caption())
                    .foregroundStyle(Color.focusDanger)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private var pickerPage: some View {
        VStack(spacing: 10) {
            FocusSectionHeader(
                title: "Що відволікає вас?",
                subtitle: "Чесно оберіть додатки — без осуду"
            )
            .padding(.horizontal, 20)
            .padding(.top, 12)

            if FocusLockConfig.useMockScreenTime {
                if !mockSelectedApps.isEmpty {
                    Text("\(mockSelectedApps.count) обрано ✓")
                        .font(FocusFont.caption())
                        .foregroundStyle(Color.focusSuccess)
                }
                MockAppPickerView(selectedNames: $mockSelectedApps)
            } else {
                if !viewModel.selection.applicationTokens.isEmpty {
                    Text("\(viewModel.selection.applicationTokens.count) обрано ✓")
                        .font(FocusFont.caption())
                        .foregroundStyle(Color.focusSuccess)
                }
                FamilyActivityPicker(selection: $viewModel.selection)
            }
        }
    }

    private var limitPage: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Стартовий ліміт")
                .font(FocusFont.title())
                .foregroundStyle(.white)
            Text("Можна змінити для кожного додатку")
                .font(FocusFont.caption())
                .foregroundStyle(Color.focusSecondary)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(viewModel.defaultLimitMinutes)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.focusAccent)
                Text("хв/день")
                    .font(FocusFont.headline())
                    .foregroundStyle(Color.focusSecondary)
            }

            LimitPresetChips(selectedMinutes: $viewModel.defaultLimitMinutes)
                .padding(.horizontal, 20)
            Spacer()
        }
    }

    private var commitmentPage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.focusSuccess)

            Text("Ваша обіцянка")
                .font(FocusFont.title())
                .foregroundStyle(.white)

            Text("Я обіцяю берегти свою увагу. FocusLock допоможе мені, але рішення — за мною.")
                .font(FocusFont.body())
                .foregroundStyle(Color.focusSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                withAnimation(.focusSpring) {
                    viewModel.commitmentAccepted.toggle()
                }
                HapticFeedback.impact(.medium)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.commitmentAccepted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(viewModel.commitmentAccepted ? Color.focusSuccess : Color.focusSecondary)
                    Text("Я приймаю обіцянку")
                        .font(FocusFont.headline())
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(18)
                .background(Color.focusCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(viewModel.commitmentAccepted ? Color.focusSuccess : Color.focusDivider, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private var bottomBar: some View {
        FocusPrimaryButton(
            title: primaryButtonTitle,
            icon: primaryIcon,
            isLoading: viewModel.loadState == .loading
        ) {
            Task { await handlePrimaryAction() }
        }
        .opacity(canProceed ? 1 : 0.45)
        .disabled(!canProceed)
    }

    private var canProceed: Bool {
        if viewModel.currentPage == 6 { return viewModel.commitmentAccepted }
        if viewModel.currentPage == 4 {
            if FocusLockConfig.useMockScreenTime {
                return !mockSelectedApps.isEmpty
            }
            return !viewModel.selection.applicationTokens.isEmpty
        }
        return true
    }

    private var primaryButtonTitle: String {
        switch viewModel.currentPage {
        case 0: return "Розпочати"
        case 1, 2: return "Далі"
        case 3: return "Надати дозвіл"
        case 4: return "Далі: ліміти"
        case 5: return "Майже готово"
        default: return "Увійти в FocusLock"
        }
    }

    private var primaryIcon: String? {
        viewModel.currentPage == 6 ? "sparkles" : "arrow.right"
    }

    private func handlePrimaryAction() async {
        switch viewModel.currentPage {
        case 0, 1, 2:
            viewModel.advance()
        case 3:
            if await viewModel.requestAuthorization() { viewModel.advance() }
        case 4:
            if FocusLockConfig.useMockScreenTime {
                guard !mockSelectedApps.isEmpty else {
                    AppCoordinator.shared.presentError(.noAppsSelected)
                    return
                }
            } else {
                guard !viewModel.selection.applicationTokens.isEmpty else {
                    AppCoordinator.shared.presentError(.noAppsSelected)
                    return
                }
            }
            viewModel.advance()
        case 5:
            viewModel.advance()
        default:
            await viewModel.finish(
                context: modelContext,
                mockAppNames: FocusLockConfig.useMockScreenTime ? Array(mockSelectedApps) : []
            )
        }
    }
}
