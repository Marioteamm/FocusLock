import SwiftUI
import SwiftData
import FamilyControls

struct AppLimitsManagementView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AppLimit.createdAt) private var limits: [AppLimit]
    @Query private var settingsQuery: [AppSettings]

    @State private var showingActivityPicker = false
    @State private var activitySelection = FamilyActivitySelection()
    @State private var limitToEdit: AppLimit?
    @State private var limitToDelete: AppLimit?

    private var settings: AppSettings {
        settingsQuery.first ?? SettingsRepository.shared.ensureSettings(context: modelContext)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if limits.isEmpty {
                    emptyState
                } else {
                    ForEach(limits) { limit in
                        limitCard(limit)
                    }
                }

                addAppsButton
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .focusScreenBackground()
        .navigationTitle("Додатки")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            activitySelection = AppBlockingManager.shared.currentSelection
        }
        .sheet(isPresented: $showingActivityPicker) {
            AppSelectionFlowView(
                selection: $activitySelection,
                defaultLimitMinutes: settings.defaultLimitMinutes
            ) { selection, _ in
                saveSelectionAndStartMonitoring(selection)
            }
        }
        .sheet(item: $limitToEdit) { limit in
            EditAppLimitSheet(
                limit: limit,
                onSave: { minutes in
                    SettingsViewModel().updateLimit(for: limit, minutes: minutes, context: modelContext)
                    limitToEdit = nil
                },
                onCancel: { limitToEdit = nil }
            )
        }
        .confirmationDialog(
            "Видалити ліміт?",
            isPresented: Binding(
                get: { limitToDelete != nil },
                set: { if !$0 { limitToDelete = nil } }
            ),
            presenting: limitToDelete
        ) { limit in
            Button("Видалити", role: .destructive) {
                SettingsViewModel().deleteLimit(limit, context: modelContext)
                limitToDelete = nil
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "apps.iphone")
                .font(.system(size: 48))
                .foregroundStyle(Color.focusAccent.opacity(0.6))
            Text("Немає обраних додатків")
                .font(FocusFont.headline())
                .foregroundStyle(.white)
            Text("Додайте додатки, для яких хочете встановити денні ліміти")
                .font(FocusFont.caption())
                .foregroundStyle(Color.focusSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }

    private func limitCard(_ limit: AppLimit) -> some View {
        HStack(spacing: 14) {
            AppTokenIconView(tokenData: limit.tokenData, size: 48)

            VStack(alignment: .leading, spacing: 6) {
                AppTokenLabelView(tokenData: limit.tokenData, fallbackName: limit.appName)
                HStack(spacing: 8) {
                    Text("\(limit.limitMinutes) хв / день")
                        .font(FocusFont.caption())
                        .foregroundStyle(Color.focusSecondary)
                    if limit.isCurrentlyBlocked {
                        Label("Заблоковано", systemImage: "lock.fill")
                            .font(FocusFont.micro())
                            .foregroundStyle(Color.focusDanger)
                    }
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { limit.isEnabled },
                set: { enabled in
                    limit.isEnabled = enabled
                    try? modelContext.save()
                    let active = limits.filter(\.isEnabled)
                    do {
                        try AppBlockingManager.shared.startMonitoring(limits: active)
                    } catch let error as AppError {
                        AppCoordinator.shared.presentError(error)
                    } catch {
                        AppCoordinator.shared.presentError(.monitoringFailed(error.localizedDescription))
                    }
                    HapticFeedback.selection()
                }
            ))
            .labelsHidden()
            .tint(Color.focusAccent)
        }
        .padding(16)
        .focusCard()
        .contentShape(Rectangle())
        .onTapGesture { limitToEdit = limit }
        .contextMenu {
            Button { limitToEdit = limit } label: {
                Label("Редагувати ліміт", systemImage: "clock")
            }
            Button(role: .destructive) { limitToDelete = limit } label: {
                Label("Видалити", systemImage: "trash")
            }
        }
    }

    private func saveSelectionAndStartMonitoring(_ selection: FamilyActivitySelection) {
        AppBlockingManager.shared.saveSelection(selection)
        do {
            try AppBlockingManager.shared.syncLimits(
                from: selection,
                context: modelContext,
                defaultMinutes: settings.defaultLimitMinutes
            )
            let limits = try modelContext.fetch(FetchDescriptor<AppLimit>())
            try AppBlockingManager.shared.startMonitoring(limits: limits)
        } catch let error as AppError {
            AppCoordinator.shared.presentError(error)
        } catch {
            AppCoordinator.shared.presentError(.persistenceFailed(error.localizedDescription))
        }
    }

    private var addAppsButton: some View {
        Button {
            Task { await requestAuthorizationAndShowPicker() }
        } label: {
            Label("Додати або змінити додатки", systemImage: "plus.circle.fill")
                .primaryButton()
        }
        .padding(.top, 8)
    }

    @MainActor
    private func requestAuthorizationAndShowPicker() async {
        do {
            try await ScreenTimeService.shared.requestAuthorization()
            if ScreenTimeService.shared.isAuthorized {
                activitySelection = AppBlockingManager.shared.currentSelection
                showingActivityPicker = true
            } else {
                AppCoordinator.shared.presentError(.authorizationDenied)
            }
        } catch {
            AppCoordinator.shared.presentError(.authorizationFailed(error.localizedDescription))
        }
    }
}
