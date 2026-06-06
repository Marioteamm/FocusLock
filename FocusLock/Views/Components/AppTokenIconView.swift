import SwiftUI
import FamilyControls
import ManagedSettings

struct AppTokenIconView: View {
    let tokenData: Data?
    var size: CGFloat = 44

    private var token: ApplicationToken? {
        guard let tokenData else { return nil }
        return FamilyActivitySelectionStorage.decodeSingleToken(from: tokenData)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .fill(Color.focusAccent.opacity(0.12))
                .frame(width: size, height: size)

            if let token {
                Label(token)
                    .labelStyle(.iconOnly)
                    .scaleEffect(size / 44)
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(Color.focusAccent)
            }
        }
    }
}
