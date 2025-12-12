import SwiftUI
import UIKit
import AVFoundation

struct RandomPersonView: View {
    // Touch points: UITouch.hash -> CGPoint
    @State private var touches: [Int: CGPoint] = [:]

    // How many fingers to choose
    @State private var chooseCount: Int = 1
    @State private var showChoosePopover = false

    // Selection animation state
    @State private var revealedIDs: Set<Int> = []
    @State private var finalSelectedID: Int?

    // Pulse animation for the final winner
    @State private var winnerPulse = false

    // Global settings shared across tools
    @AppStorage("roll4me_volume")    private var volume: Double = 0.7
    @AppStorage("roll4me_hapticsOn") private var hapticsOn: Bool = true
    @AppStorage("roll4me_soundOn")   private var soundOn: Bool = true

    // Settings panel
    @State private var showSettingsPanel = false

    var body: some View {
        ZStack(alignment: .bottom) {
            background

            VStack(spacing: 24) {
                header
                fingerPanel
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)

            if showChoosePopover {
                choosePopover
            }

            // Bottom settings panel
            if showSettingsPanel {
                RandomPersonSettingsPanel(isPresented: $showSettingsPanel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 10, y: -2)
                    .overlay(Divider(), alignment: .top)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .onChange(of: touches) { old, newDict in
            let maxFingers = max(newDict.count, 1)
            if chooseCount > maxFingers { chooseCount = maxFingers }
            if chooseCount < 1 { chooseCount = 1 }

            // If all fingers are removed → clear everything
            if newDict.isEmpty {
                revealedIDs.removeAll()
                finalSelectedID = nil
                winnerPulse = false
                return
            }

            // Keep only IDs that still exist
            let currentIDs = Set(newDict.keys)
            revealedIDs = revealedIDs.intersection(currentIDs)

            // If the winning finger was lifted, clear winner state
            if let winner = finalSelectedID, !currentIDs.contains(winner) {
                finalSelectedID = nil
                winnerPulse = false
            }
        }
    }

    // MARK: - Pieces

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 245/255, green: 228/255, blue: 248/255),
                Color(red: 250/255, green: 238/255, blue: 252/255)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        Text("Place Your Finger")
            .font(.system(size: 32, weight: .heavy, design: .rounded))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var fingerPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)

            FingerTouchCaptureView(points: $touches)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            GeometryReader { _ in
                ForEach(Array(touches.keys), id: \.self) { key in
                    if let pos = touches[key] {
                        let isWinner = revealedIDs.contains(key)
                        let isFinal  = finalSelectedID == key

                        ZStack {
                            // Bigger main dot
                            Circle()
                                .fill(circleColor(for: key))
                                .frame(width: 120, height: 120)
                                .scaleEffect(isFinal ? 1.25 : (isWinner ? 1.08 : 1.0))
                                .shadow(radius: 4, y: 2)

                            // Pulsing ring for final chosen finger
                            if isFinal {
                                Circle()
                                    .stroke(Color.white.opacity(0.9), lineWidth: 6)
                                    .frame(width: 160, height: 160)
                                    .scaleEffect(winnerPulse ? 1.2 : 0.8)
                                    .opacity(winnerPulse ? 0.1 : 0.45)
                                    .blendMode(.screen)
                            }
                        }
                        .position(pos)
                    }
                }
            }
        }
        .frame(height: 550)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.black.opacity(0.14))
                .frame(height: 1)

            HStack {
                // Handle opens/closes settings panel
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        showSettingsPanel.toggle()
                    }
                } label: {
                    HandleButton()
                }

                Spacer()

                Button(action: startSelection) {
                    Text("Pick")
                        .font(.headline)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color(white: 0.98))
                                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        )
                }
                .buttonStyle(.plain)
                // Only disabled when there are no fingers at all
                .disabled(touches.isEmpty)
                .opacity(touches.isEmpty ? 0.4 : 1.0)

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .background(.ultraThinMaterial)
        .ignoresSafeArea(edges: .bottom)
    }

    private var choosePopover: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("choose")
                    .font(.headline)
                HStack(spacing: 12) {
                    Button {
                        if chooseCount > 1 { chooseCount -= 1 }
                    } label: {
                        Image(systemName: "minus")
                            .font(.headline)
                            .frame(width: 34, height: 34)
                            .background(Color.red.opacity(0.85))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Text("\(chooseCount)")
                        .font(.title3.bold())
                        .frame(width: 40)

                    Button {
                        let maxFingers = max(touches.count, 1)
                        if chooseCount < maxFingers { chooseCount += 1 }
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .frame(width: 34, height: 34)
                            .background(Color.green.opacity(0.85))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            )

            Triangle()
                .fill(.ultraThinMaterial)
                .frame(width: 18, height: 10)
        }
        .padding(.trailing, 26)
        .padding(.bottom, 92)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .onTapGesture {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                showChoosePopover = false
            }
        }
    }

    private func startSelection() {
        guard !touches.isEmpty else { return }

        let ids = Array(touches.keys)
        let k = min(max(1, chooseCount), ids.count)
        guard k > 0 else { return }

        // Pick k random winners immediately
        let winners = Array(ids.shuffled().prefix(k))

        revealedIDs = Set(winners)
        finalSelectedID = winners.last   // last one gets the red + pulse

        // 🔊 play pop sound (no delay needed)
        if soundOn {
            RandomPersonSoundPlayer.shared.play(volume: volume)
        }

        // restart pulsing animation
        winnerPulse = false
        withAnimation(
            .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
        ) {
            winnerPulse = true
        }

        if hapticsOn {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    private func circleColor(for id: Int) -> Color {
        if finalSelectedID == id {
            return .red
        } else if revealedIDs.contains(id) {
            return Color.blue.opacity(0.75)
        } else {
            return Color.gray.opacity(0.6)
        }
    }
}

// MARK: - Settings panel

private struct RandomPersonSettingsPanel: View {
    @Binding var isPresented: Bool

    @AppStorage("roll4me_volume")    private var volume: Double = 0.7
    @AppStorage("roll4me_hapticsOn") private var hapticsOn: Bool = true
    @AppStorage("roll4me_soundOn")   private var soundOn: Bool = true

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 44, height: 5)
                .padding(.top, 8)

            HStack(spacing: 12) {
                Image(systemName: "speaker.wave.2.fill")
                Slider(value: $volume, in: 0...1)
                    .disabled(!soundOn)
                    .opacity(soundOn ? 1.0 : 0.4)
            }
            .padding(.horizontal, 18)

            HStack(spacing: 14) {
                RandomPersonToggleChip(title: "Haptics", isOn: $hapticsOn)

                RandomPersonToggleChip(title: "Sound", isOn: $soundOn) { newValue in
                    if !newValue { volume = 0 }
                }
            }
            .padding(.horizontal, 18)

            Spacer(minLength: 8)
        }
        .padding(.top, 6)
        .background(.clear)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = max(0, value.translation.height)
                }
                .onEnded { value in
                    if value.translation.height > 60 {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            isPresented = false
                        }
                    }
                    dragOffset = 0
                }
        )
    }
}

private struct RandomPersonToggleChip: View {
    let title: String
    @Binding var isOn: Bool
    var onToggle: ((Bool) -> Void)? = nil

    var body: some View {
        Button {
            isOn.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onToggle?(isOn)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                Text(title)
                    .font(.subheadline).bold()
            }
            .foregroundStyle(isOn ? .primary : .secondary)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

// MARK: - Touch capture view

private struct FingerTouchCaptureView: UIViewRepresentable {
    @Binding var points: [Int: CGPoint]

    func makeUIView(context: Context) -> TouchView {
        let v = TouchView()
        v.onUpdate = { newPoints in
            DispatchQueue.main.async {
                self.points = newPoints
            }
        }
        return v
    }

    func updateUIView(_ uiView: TouchView, context: Context) {}

    final class TouchView: UIView {
        var onUpdate: (([Int: CGPoint]) -> Void)?
        private var pts: [Int: CGPoint] = [:]

        override init(frame: CGRect) {
            super.init(frame: frame)
            isMultipleTouchEnabled = true
            backgroundColor = .clear
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            isMultipleTouchEnabled = true
            backgroundColor = .clear
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            if UserDefaults.standard.bool(forKey: "roll4me_hapticsOn") {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            update(touches, removing: false)
        }
        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            update(touches, removing: false)
        }
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            update(touches, removing: true)
        }
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            update(touches, removing: true)
        }

        private func update(_ touches: Set<UITouch>, removing: Bool) {
            for t in touches {
                let key = t.hash
                if removing {
                    pts.removeValue(forKey: key)
                } else {
                    pts[key] = t.location(in: self)
                }
            }
            onUpdate?(pts)
        }
    }
}

// MARK: - Small shared views

private struct HandleButton: View {
    var body: some View {
        VStack(spacing: 6) {
            Capsule().fill(Color.gray.opacity(0.35)).frame(width: 44, height: 6)
            Capsule().fill(Color.gray.opacity(0.35)).frame(width: 32, height: 6)
        }
        .padding(8)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
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

// MARK: - Random person sound

final class RandomPersonSoundPlayer {
    static let shared = RandomPersonSoundPlayer()
    private var player: AVAudioPlayer?

    func play(volume: Double) {
        let clamped = max(0.0, min(volume, 1.0))
        guard clamped > 0 else { return }

        if player == nil {
            if let url = Bundle.main.url(forResource: "pop", withExtension: "wav") {
                player = try? AVAudioPlayer(contentsOf: url)
                player?.prepareToPlay()
            }
        }

        guard let player = player else { return }
        player.currentTime = 0
        player.volume = Float(clamped)
        player.play()
    }
}
// MARK: - Preview

#Preview {
    RandomPersonView()
}
