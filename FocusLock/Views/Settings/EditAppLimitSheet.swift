import SwiftUI
import SwiftData

struct EditAppLimitSheet: View {

    @Environment(\.modelContext) private var modelContext

    let limit: AppLimit
    var onSave: (Int) -> Void
    var onCancel: () -> Void

    @State private var selectedMinutes: Int
    @State private var selectedIntention: MindfulCopy.LimitIntention

    init(limit: AppLimit, onSave: @escaping (Int) -> Void, onCancel: @escaping () -> Void) {
        self.limit = limit
        self.onSave = onSave
        self.onCancel = onCancel
        _selectedMinutes = State(initialValue: limit.limitMinutes)
        _selectedIntention = State(initialValue: limit.limitIntention)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                HStack(spacing: 16) {
                    AppTokenIconView(tokenData: limit.tokenData, size: 56)
                    VStack(alignment: .leading, spacing: 6) {
                        AppTokenLabelView(tokenData: limit.tokenData, fallbackName: limit.appName)
                        Text("Денний ліміт використання")
                            .font(FocusFont.caption())
                            .foregroundStyle(Color.focusSecondary)
                    }
                    Spacer()
                }

                VStack(spacing: 8) {
                    Text("\(selectedMinutes)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.focusAccent)
                        .contentTransition(.numericText())
                    Text("хвилин на день")
                        .font(FocusFont.caption())
                        .foregroundStyle(Color.focusSecondary)
                }

                LimitPresetChips(selectedMinutes: $selectedMinutes)

                VStack(alignment: .leading, spacing: 10) {
                    FocusSectionHeader(title: "Чому обмежуєте?", subtitle: "Персональна підказка на Shield")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MindfulCopy.LimitIntention.allCases) { item in
                                Button {
                                    selectedIntention = item
                                    HapticFeedback.selection()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: item.icon)
                                        Text(item.title)
                                            .font(FocusFont.micro())
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedIntention == item
                                            ? Color.focusAccent.opacity(0.25)
                                            : Color.focusDivider.opacity(0.5),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(.white)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    Text(selectedIntention.intervention)
                        .font(FocusFont.caption())
                        .foregroundStyle(Color.focusSecondary)
                        .italic()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("Після ліміту", systemImage: "lock.shield")
                        .font(FocusFont.caption())
                        .foregroundStyle(Color.focusSecondary)
                    Text("Додаток буде заблоковано Shield-екраном. Один раз на день можна додати +15 хв.")
                        .font(FocusFont.caption())
                        .foregroundStyle(Color.focusSecondary.opacity(0.8))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.focusCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Spacer()
            }
            .padding(24)
            .focusScreenBackground()
            .navigationTitle("Ліміт часу")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати", action: onCancel)
                        .foregroundStyle(Color.focusSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Зберегти") {
                        limit.limitIntentionRaw = selectedIntention.rawValue
                        try? modelContext.save()
                        onSave(selectedMinutes)
                        HapticFeedback.notification(.success)
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.focusAccent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }
}
