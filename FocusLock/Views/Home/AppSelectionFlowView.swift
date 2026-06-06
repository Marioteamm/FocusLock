import SwiftUI
import SwiftData
import FamilyControls
import ManagedSettings

/// Premium unified flow: pick apps → set limits → confirm.
struct AppSelectionFlowView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Binding var selection: FamilyActivitySelection
    var defaultLimitMinutes: Int
    var onComplete: (FamilyActivitySelection, Int) -> Void

    @State private var step: Step = .select
    @State private var limitMinutes: Int
    @State private var perAppLimits: [String: Int] = [:]
    @State private var perAppIntentions: [String: String] = [:]
    @State private var isSaving = false
    @State private var mockSelectedApps: Set<String> = []

    private enum Step { case select, configure }

    init(
        selection: Binding<FamilyActivitySelection>,
        defaultLimitMinutes: Int,
        onComplete: @escaping (FamilyActivitySelection, Int) -> Void
    ) {
        _selection = selection
        self.defaultLimitMinutes = defaultLimitMinutes
        self.onComplete = onComplete
        _limitMinutes = State(initialValue: defaultLimitMinutes)
    }

    private var appCount: Int {
        if FocusLockConfig.useMockScreenTime {
            return mockSelectedApps.count
        }
        return selection.applicationTokens.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.focusBackgroundGradient.ignoresSafeArea()

                switch step {
                case .select: selectStep
                case .configure: configureStep
                }
            }
            .navigationTitle(step == .select ? "Обрати додатки" : "Ліміти часу")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") { dismiss() }
                        .foregroundStyle(Color.focusSecondary)
                }
            }
        }
    }

    // MARK: - Step 1: Picker

    private var selectStep: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundStyle(Color.focusAccent)
                    Text("Приватність")
                        .font(FocusFont.caption())
                        .foregroundStyle(Color.focusSecondary)
                }
                Text("Apple не передає назви додатків назовні. Ви бачите лише те, що обрали.")
                    .font(FocusFont.caption())
                    .foregroundStyle(Color.focusSecondary.opacity(0.9))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.focusCard.opacity(0.6))

            if appCount > 0 {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.focusSuccess)
                    Text("Обрано: \(appCount) \(appCount == 1 ? "додаток" : "додатки")")
                        .font(FocusFont.headline())
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }

            if FocusLockConfig.useMockScreenTime {
                MockAppPickerView(selectedNames: $mockSelectedApps)
            } else {
                FamilyActivityPicker(selection: $selection)
                    .padding(.horizontal, 4)
            }

            VStack(spacing: 12) {
                FocusPrimaryButton(
                    title: appCount == 0 ? "Оберіть хоча б один додаток" : "Далі: встановити ліміти",
                    icon: "arrow.right",
                    isLoading: false
                ) {
                    guard appCount > 0 else {
                        AppCoordinator.shared.presentError(.noAppsSelected)
                        return
                    }
                    bootstrapPerAppLimits()
                    withAnimation(.focusSpring) { step = .configure }
                }
                .disabled(appCount == 0)
                .opacity(appCount == 0 ? 0.5 : 1)
            }
            .padding(20)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Step 2: Limits

    private var configureStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "brain.head.profile")
                            .foregroundStyle(Color.focusAccent)
                        Text("Назвіть причину — це знижує імпульс відкрити додаток (як Jomo).")
                            .font(FocusFont.caption())
                            .foregroundStyle(Color.focusSecondary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.focusAccent.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    if appCount == 1, let token = selection.applicationTokens.first {
                        perAppRow(token: token, index: 0)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        FocusSectionHeader(
                            title: "Ліміт для всіх",
                            subtitle: "Застосується до кожного нового додатку"
                        )
                        LimitPresetChips(selectedMinutes: $limitMinutes)
                        Button {
                            applyLimitToAll(limitMinutes)
                            HapticFeedback.notification(.success)
                        } label: {
                            Label("Застосувати \(limitMinutes) хв до всіх", systemImage: "square.on.square")
                                .font(FocusFont.caption())
                                .foregroundStyle(Color.focusAccent)
                        }
                    }

                    if appCount > 1 {
                        FocusSectionHeader(
                            title: "Окремо для кожного",
                            subtitle: "Точний контроль часу"
                        )

                        VStack(spacing: 10) {
                            ForEach(Array(selection.applicationTokens.enumerated()), id: \.offset) { index, token in
                                perAppRow(token: token, index: index)
                            }
                        }
                        .onAppear { bootstrapPerAppLimits() }
                    }
                }
                .padding(20)
            }

            VStack(spacing: 12) {
                FocusPrimaryButton(
                    title: "Зберегти та увімкнути",
                    icon: "checkmark.shield.fill",
                    isLoading: isSaving
                ) {
                    Task { await saveAndFinish() }
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
        }
    }

    private func perAppRow(token: ApplicationToken, index: Int) -> some View {
        let key = tokenKey(token, index: index)
        let minutes = perAppLimits[key] ?? limitMinutes
        let intentionRaw = perAppIntentions[key] ?? MindfulCopy.LimitIntention.habit.rawValue
        let intention = MindfulCopy.LimitIntention(rawValue: intentionRaw) ?? .habit

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                AppTokenIconView(
                    tokenData: FamilyActivitySelectionStorage.encodeSingleToken(token),
                    size: 40
                )

                VStack(alignment: .leading, spacing: 2) {
                    if let data = FamilyActivitySelectionStorage.encodeSingleToken(token) {
                        AppTokenLabelView(tokenData: data, fallbackName: "Додаток \(index + 1)")
                            .font(FocusFont.headline())
                    }
                }

                Spacer()

                Menu {
                    ForEach([15, 30, 45, 60, 90, 120], id: \.self) { m in
                        Button("\(m) хв") { perAppLimits[key] = m }
                    }
                } label: {
                    Text("\(minutes) хв")
                        .font(FocusFont.headline())
                        .foregroundStyle(Color.focusAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.focusAccent.opacity(0.12), in: Capsule())
                }
            }

            Menu {
                ForEach(MindfulCopy.LimitIntention.allCases) { item in
                    Button {
                        perAppIntentions[key] = item.rawValue
                    } label: {
                        Label(item.title, systemImage: item.icon)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: intention.icon)
                    Text("Чому: \(intention.title)")
                        .font(FocusFont.micro())
                }
                .foregroundStyle(Color.focusSecondary)
            }
        }
        .padding(14)
        .focusCard()
    }

    private func bootstrapPerAppLimits() {
        for (index, token) in selection.applicationTokens.enumerated() {
            let key = tokenKey(token, index: index)
            perAppLimits[key] = limitMinutes
            if perAppIntentions[key] == nil {
                perAppIntentions[key] = MindfulCopy.LimitIntention.habit.rawValue
            }
        }
    }

    private func applyLimitToAll(_ minutes: Int) {
        for key in perAppLimits.keys {
            perAppLimits[key] = minutes
        }
        for (index, token) in selection.applicationTokens.enumerated() {
            perAppLimits[tokenKey(token, index: index)] = minutes
        }
    }

    private func tokenKey(_ token: ApplicationToken, index: Int) -> String {
        if let data = FamilyActivitySelectionStorage.encodeSingleToken(token) {
            return AppBlockingManager.bundleIdentifier(forTokenData: data)
        }
        return "app.\(index)"
    }

    @MainActor
    private func saveAndFinish() async {
        isSaving = true
        defer { isSaving = false }

        do {
            if FocusLockConfig.useMockScreenTime {
                try AppBlockingManager.shared.injectDemoLimits(
                    context: modelContext,
                    appNames: Array(mockSelectedApps),
                    defaultMinutes: limitMinutes
                )
                applyDemoPerAppOverrides()
            } else {
                AppBlockingManager.shared.saveSelection(selection)
                try syncLimitsWithPerAppOverrides()
            }
            onComplete(selection, limitMinutes)
            HapticFeedback.notification(.success)
            dismiss()
        } catch {
            AppCoordinator.shared.presentError(.persistenceFailed(error.localizedDescription))
        }
    }

    private func applyDemoPerAppOverrides() {
        let limits = (try? modelContext.fetch(FetchDescriptor<AppLimit>())) ?? []
        for limit in limits {
            if let minutes = perAppLimits[limit.bundleIdentifier] {
                limit.limitMinutes = minutes
            }
            if let intention = perAppIntentions[limit.bundleIdentifier] {
                limit.limitIntentionRaw = intention
            }
            limit.isEnabled = true
        }
        try? modelContext.save()
    }

    private func syncLimitsWithPerAppOverrides() throws {
        try AppBlockingManager.shared.syncLimits(
            from: selection,
            context: modelContext,
            defaultMinutes: limitMinutes
        )

        let limits = try modelContext.fetch(FetchDescriptor<AppLimit>())
        for limit in limits {
            if let minutes = perAppLimits[limit.bundleIdentifier] {
                limit.limitMinutes = minutes
            }
            if let intention = perAppIntentions[limit.bundleIdentifier] {
                limit.limitIntentionRaw = intention
            }
            limit.isEnabled = true
        }
        try modelContext.save()
    }
}
