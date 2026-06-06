import SwiftUI

extension Animation {
    static var focusSpring: Animation {
        UIAccessibility.isReduceMotionEnabled
            ? .easeInOut(duration: 0.2)
            : .spring(duration: 0.45, bounce: 0.25)
    }

    static var focusQuick: Animation {
        .easeInOut(duration: UIAccessibility.isReduceMotionEnabled ? 0.15 : 0.22)
    }

    static var focusBounce: Animation {
        UIAccessibility.isReduceMotionEnabled
            ? .easeInOut(duration: 0.2)
            : .spring(duration: 0.55, bounce: 0.35)
    }
}

extension View {
    func focusAppear(delay: Double = 0) -> some View {
        modifier(StaggeredAppearModifier(delay: delay))
    }

    func pulseWhenActive(_ isActive: Bool) -> some View {
        modifier(PulseModifier(isActive: isActive))
    }

    func pressableScale() -> some View {
        modifier(PressableScaleModifier())
    }

    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

private struct StaggeredAppearModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let delay: Double
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible || reduceMotion ? 0 : 14)
            .scaleEffect(visible || reduceMotion ? 1 : 0.97)
            .onAppear {
                if reduceMotion {
                    visible = true
                } else {
                    withAnimation(.focusSpring.delay(delay)) {
                        visible = true
                    }
                }
            }
    }
}

private struct PulseModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isActive: Bool
    @State private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: isActive) { _, active in
                guard active, !reduceMotion else {
                    scale = 1
                    return
                }
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    scale = 1.04
                }
            }
    }
}

private struct PressableScaleModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed && !reduceMotion ? 0.97 : 1)
            .animation(.focusQuick, value: pressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if !reduceMotion { pressed = true } }
                    .onEnded { _ in pressed = false }
            )
    }
}

private struct ShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.12), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: phase)
                    .mask(content)
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                    phase = 200
                }
            }
    }
}
