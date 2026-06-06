// Вибір ліміту часу для програми
import SwiftUI

struct TimeLimitPickerView: View {

    let limit: AppLimit
    var onSave: (Int) -> Void
    var onCancel: () -> Void

    @State private var selectedMinutes: Int
    private let options = [15, 30, 45, 60, 90, 120]

    init(
        limit: AppLimit,
        onSave: @escaping (Int) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.limit    = limit
        self.onSave   = onSave
        self.onCancel = onCancel
        self._selectedMinutes = State(initialValue: limit.limitMinutes)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.focusBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Заголовок
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ліміт часу")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.focusSecondary)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        Text(limit.appName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Варіанти лімітів
                    VStack(spacing: 10) {
                        ForEach(options, id: \.self) { minutes in
                            limitOptionRow(minutes: minutes)
                                .padding(.horizontal, 20)
                        }
                    }

                    Spacer()

                    // Кнопки дій
                    VStack(spacing: 12) {
                        Button("Зберегти") { onSave(selectedMinutes) }
                            .primaryButton()

                        Button("Скасувати") { onCancel() }
                            .secondaryButton()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.height(580)])
        .presentationCornerRadius(24)
    }

    private func limitOptionRow(minutes: Int) -> some View {
        let isSelected = selectedMinutes == minutes

        return Button {
            selectedMinutes = minutes
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? Color.focusAccent : Color.focusSecondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(labelFor(minutes))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : Color.focusSecondary)

                    Text(descriptionFor(minutes))
                        .font(.system(size: 12))
                        .foregroundColor(Color.focusSecondary.opacity(0.7))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.focusAccent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isSelected ? Color.focusAccent.opacity(0.12) : Color.focusCard)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? Color.focusAccent.opacity(0.4) : Color.focusDivider,
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private func labelFor(_ minutes: Int) -> String {
        switch minutes {
        case 60:  return "1 год"
        case 90:  return "1 год 30 хв"
        case 120: return "2 год"
        default:  return "\(minutes) хв"
        }
    }

    private func descriptionFor(_ minutes: Int) -> String {
        switch minutes {
        case 15:  return "Мінімальний час для перевірки"
        case 30:  return "Короткий перегляд"
        case 45:  return "Помірне використання"
        case 60:  return "Рекомендовано Apple"
        case 90:  return "Довший час відпочинку"
        case 120: return "Максимальний дозволений час"
        default:  return ""
        }
    }
}
