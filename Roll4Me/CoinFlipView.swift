import SwiftUI
import CoreMotion

// MARK: - CoinFlipView
struct CoinFlipView: View {
    // Result state
    @State private var isHeads = true
    @State private var angle: Double = 0
    @State private var isFlipping = false
    @State private var flipCount = 0

    // Custom labels + weights
    @State private var side1Label = "Heads"
    @State private var side2Label = "Tails"
    @State private var side1Weight = 1
    @State private var side2Weight = 1

    // Bubble editor
    @State private var showEditor = false
    @FocusState private var anyFieldFocused: Bool

    // Tilt-to-Flip
    @StateObject private var tilt = TiltFlipDetector()
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        ZStack {
            Color(red: 216/255, green: 205/255, blue: 245/255).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                Text("Result: \(isHeads ? side1Label : side2Label)")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .padding(.top, 16)

                Spacer(minLength: 10)

                // Arc + Coin
                ZStack {
                    ArcText(
                        text: "Raise  to  Flip",
                        radius: 150,
                        startAngle: -145,    // nicer centering
                        endAngle: -35,
                        fontSize: 30
                    )

                    Image("coin image")      // put your PNG in Assets with this name
                        .resizable()
                        .scaledToFit()
                        .frame(width: 230, height: 230)
                        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
                        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0))
                        .animation(.easeOut(duration: 0.7), value: angle)
                        .overlay {
                            if isFlipping {
                                Text("?")
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundStyle(.black.opacity(0.7))
                            }
                        }
                }
                .frame(maxHeight: .infinity)

                // Bottom sticky bar (flush to safe area)
                bottomBar
            }

            // Editor bubble
            if showEditor {
                SpeechBubble {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Customize").font(.headline)
                            Spacer()
                            Button("Done") {
                                anyFieldFocused = false
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                    showEditor = false
                                }
                            }
                            .bold()
                        }

                        WeightRow(
                            tag: "Side 1",
                            text: $side1Label,
                            weight: $side1Weight
                        )

                        WeightRow(
                            tag: "Side 2",
                            text: $side2Label,
                            weight: $side2Weight
                        )
                    }
                    .padding(12)
                }
                .frame(maxWidth: 360)
                .padding(.trailing, 18)
                .padding(.bottom, 102) // sits above bottom bar
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: goHome) {
                    Image(systemName: "house.fill").font(.title3)
                }
                .tint(.primary)
                .accessibilityLabel("Home")
            }
        }
        .onAppear {
            tilt.start { trigger in
                if trigger { flipCoinWeighted() }
            }
        }
        .onDisappear { tilt.stop() }
        .onTapGesture { anyFieldFocused = false }
        .navigationTitle("Coin Flip")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 10) {
            // subtle divider line at top of bar
            Rectangle().fill(Color.black.opacity(0.12)).frame(height: 1)

            HStack {
                HandleButton()

                Spacer()

                Button {
                    flipCoinWeighted()
                } label: {
                    Text("Flip")
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.horizontal, 34)
                        .padding(.vertical, 12)
                        .background(
                            Capsule().fill(Color.purple.opacity(0.28))
                                .overlay(Capsule().stroke(.black.opacity(0.15), lineWidth: 1))
                        )
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        showEditor.toggle()
                    }
                } label: {
                    ZStack {
                        Circle().fill(.thinMaterial).frame(width: 40, height: 40)
                        Image(systemName: showEditor ? "xmark" : "plus")
                            .font(.headline)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 12)

            // counters
            Text("Flipped \(flipCount) times")
                .font(.subheadline)
                .foregroundStyle(.black.opacity(0.55))
                .padding(.bottom, 6)
        }
        .background(Color(UIColor.systemYellow).opacity(0.22))
        .frame(maxWidth: .infinity, alignment: .bottom)
        .ignoresSafeArea(edges: .bottom) // FLUSH to bottom
    }
    
    // MARK: Actions

    private func goHome() {
        // 1) Try popping to root (works when inside UINavigationController)
        if let nav = UIApplication.shared.topNavigationController() {
            nav.popToRootViewController(animated: true)
            return
        }
        // 2) SwiftUI fallbacks
        dismiss()
        presentationMode.wrappedValue.dismiss()
    }

    // MARK: - Weighted flip + animation
    private func flipCoinWeighted() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // enforce non-negative weights
        let w1 = max(0, side1Weight)
        let w2 = max(0, side2Weight)
        let total = max(1, w1 + w2)

        // sample from weights
        let r = Int.random(in: 1...total)
        let finalIsHeads = (r <= w1)

        isFlipping = true
        let spins = Int.random(in: 3...6)
        angle += Double(spins * 360) + (finalIsHeads ? 0 : 180)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
            isHeads = finalIsHeads
            flipCount += 1
            isFlipping = false
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

// MARK: - Tilt detector
final class TiltFlipDetector: ObservableObject {
    private let manager = CMMotionManager()
    private var lastTriggerTime = Date.distantPast

    func start(onTrigger: @escaping (Bool) -> Void) {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 40.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let m = motion else { return }
            let pitch = m.attitude.pitch
            let gravY = m.gravity.y
            let speed = abs(m.rotationRate.y)
            if (abs(pitch) > 0.60 || speed > 4.0 || abs(gravY) < 0.1) {
                if Date().timeIntervalSince(self.lastTriggerTime) > 0.9 {
                    self.lastTriggerTime = Date()
                    onTrigger(true)
                }
            }
        }
    }
    func stop() { manager.stopDeviceMotionUpdates() }
}

// MARK: - Reusable UI

private struct HandleButton: View {
    var body: some View {
        VStack(spacing: 6) {
            Capsule().fill(Color.gray.opacity(0.35)).frame(width: 50, height: 7)
            Capsule().fill(Color.gray.opacity(0.35)).frame(width: 38, height: 7)
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(radius: 2, y: 1)
    }
}

private struct WeightRow: View {
    let tag: String
    @Binding var text: String
    @Binding var weight: Int

    var body: some View {
        HStack(spacing: 10) {
            Tag(tag)

            TextField(tag == "Side 1" ? "Heads" : "Tails", text: $text)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 16))
                .frame(minWidth: 140)

            Spacer(minLength: 6)

            HStack(spacing: 6) {
                Button {
                    if weight > 0 { weight -= 1 }
                } label: {
                    Capsule().fill(Color.gray.opacity(0.15))
                        .overlay(Image(systemName: "minus").foregroundStyle(.primary))
                        .frame(width: 36, height: 34)
                }
                .buttonStyle(.plain)

                Text("\(weight)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .frame(width: 34, height: 34)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.12)))

                Button {
                    weight += 1
                } label: {
                    Capsule().fill(Color.gray.opacity(0.15))
                        .overlay(Image(systemName: "plus").foregroundStyle(.primary))
                        .frame(width: 36, height: 34)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct Tag: View {
    let text: String
    init(_ t: String) { self.text = t }
    var body: some View {
        Text(text)
            .font(.subheadline).bold()
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.12)))
    }
}

private struct SpeechBubble<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) {
            content
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.18), lineWidth: 1))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)

            Triangle()
                .fill(.ultraThinMaterial)
                .frame(width: 20, height: 12)
                .overlay(Triangle().stroke(Color.black.opacity(0.18), lineWidth: 1))
                .offset(x: 72, y: -1)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

// Curved text where glyphs face outward (bigger + better spacing)
private struct ArcText: View {
    let text: String
    let radius: CGFloat
    let startAngle: Double
    let endAngle: Double
    var fontSize: CGFloat = 28

    var body: some View {
        ZStack {
            ForEach(Array(text.enumerated()), id: \.offset) { (i, ch) in
                let t = Double(i) / Double(max(text.count - 1, 1))
                let angle = startAngle + (endAngle - startAngle) * t
                let rad = angle * Double.pi / 180
                let x = cos(rad) * radius
                let y = sin(rad) * radius

                Text(String(ch))
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .rotationEffect(.degrees(angle + 90)) // upright on arc
                    .offset(x: x, y: y)
            }
        }
        .frame(width: radius * 2, height: radius * 2)
        .allowsHitTesting(false)
    }
}

#Preview { NavigationStack { CoinFlipView() } }
