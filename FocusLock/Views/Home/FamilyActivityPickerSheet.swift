import SwiftUI
import FamilyControls

/// Legacy wrapper — prefer `AppSelectionFlowView` for full flow.
struct FamilyActivityPickerSheet: View {

    @Binding var selection: FamilyActivitySelection
    @Binding var isPresented: Bool
    var onConfirm: (FamilyActivitySelection) -> Void

    var defaultLimitMinutes: Int = 60

    var body: some View {
        AppSelectionFlowView(
            selection: $selection,
            defaultLimitMinutes: defaultLimitMinutes,
            onComplete: { sel, _ in
                onConfirm(sel)
                isPresented = false
            }
        )
    }
}
