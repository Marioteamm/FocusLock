import SwiftUI
import FamilyControls
import ManagedSettings

struct AppTokenLabelView: View {
    let tokenData: Data?
    var fallbackName: String

    private var token: ApplicationToken? {
        guard let tokenData else { return nil }
        return FamilyActivitySelectionStorage.decodeSingleToken(from: tokenData)
    }

    var body: some View {
        if let token {
            Label(token)
                .labelStyle(.titleOnly)
                .font(.headline)
                .foregroundStyle(.white)
        } else {
            Text(fallbackName)
                .font(.headline)
                .foregroundStyle(.white)
        }
    }
}
