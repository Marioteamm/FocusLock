// Прогрес-бар використаного часу
import SwiftUI

struct ProgressRingView: View {

    var progress: Double
    var color: Color
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Фоновий трек
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.focusDivider)
                    .frame(height: height)

                // Заповнена частина
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: max(height, geometry.size.width * CGFloat(min(1.0, progress))),
                        height: height
                    )
                    .animation(.easeInOut(duration: 0.4), value: progress)
            }
        }
        .frame(height: height)
    }
}
