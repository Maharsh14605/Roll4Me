//
//  DiceRollView.swift
//  Roll4Me
//

import SwiftUI
import AVFoundation   // ⬅️ for sound

private struct LiveDie: Identifiable, Equatable {
    let id = UUID()
    var sides: Int
    var value: Int
    var weighted: Bool = false
    var spinToken = UUID() // change to trigger animation
}

struct DiceRollView: View {
    // Dice on screen (starts with one fair D6)
    @State private var liveDice: [LiveDie] = [LiveDie(sides: 6, value: 1, weighted: false)]

    // Weighted die configuration (for the optional second die)
    @State private var hasWeightedDie = false
    @State private var weightSteps = [1, 1, 1, 1, 1, 1] // per-face weights 1..6

    // Temp edits shown in the "+" panel (cancel-safe)
    @State private var tempHasWeighted = false
    @State private var tempWeightSteps = [1, 1, 1, 1, 1, 1]

    // UI state
    @State private var latestTotal = 1
    @State private var showPanel = false           // weighted die bubble
    @State private var showSettingsPanel = false   // bottom settings sheet
    @State private var isRolling = false

    // Global settings shared with Home panel
    @AppStorage("roll4me_volume")    private var volume: Double = 0.7
    @AppStorage("roll4me_hapticsOn") private var hapticsOn: Bool = true
    @AppStorage("roll4me_soundOn")   private var soundOn: Bool = true

    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            // Background (warm rose)
            Color(red: 214/255, green: 166/255, blue: 162/255).opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                // Top result
                Text("Result: \(latestTotal)")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .padding(.top, 12)

                // Arc label + dice area
                ZStack {
                    ArcText(
                        text: "Shake  to  Roll",
                        radius: 130,
                        startAngle: -140,
                        endAngle: -40,
                        followTangent: true
                    )
                    .foregroundStyle(.black.opacity(0.75))

                    // Center when only one die
                    let columns: [GridItem] =
                        liveDice.count == 1
                        ? [GridItem(.flexible())]
                        : [GridItem(.flexible(), spacing: 24),
                           GridItem(.flexible(), spacing: 24)]

                    LazyVGrid(columns: columns, alignment: .center, spacing: 24) {
                        ForEach(liveDice.indices, id: \.self) { i in
                            DieView(
                                sides: liveDice[i].sides,
                                value: liveDice[i].value,
                                spinToken: liveDice[i].spinToken
                            )
                            .frame(width: 140, height: 140)
                            .onTapGesture {
                                // single die tap -> sound + roll
                                if soundOn { DiceSoundPlayer.shared.playRoll(volume: volume) }
                                rollSingleAnimated(index: i)
                            }
                            .accessibilityElement()
                            .accessibilityLabel("D\(liveDice[i].sides) showing \(liveDice[i].value)")
                            .accessibilityHint("Double-tap to roll this die")
                            .accessibilityAddTraits(.isButton)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 60)
                }
                .frame(maxHeight: .infinity)

                // MARK: - Bottom bar
                VStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.black.opacity(0.12))
                        .frame(height: 1)

                    HStack {
                        // Left handle opens settings panel
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                showSettingsPanel.toggle()
                            }
                        } label: {
                            HandleButton()
                        }

                        Spacer()

                        Button {
                            // main roll -> sound + roll
                            if soundOn { DiceSoundPlayer.shared.playRoll(volume: volume) }
                            rollAllAnimated()
                        } label: {
                            Text("Roll")
                                .font(.headline)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(Color(red: 214/255, green: 166/255, blue: 162/255))
                                        .overlay(
                                            Capsule()
                                                .stroke(.black.opacity(0.15), lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            // open weighted die panel with temp copies (so Cancel restores)
                            tempHasWeighted = hasWeightedDie
                            tempWeightSteps = weightSteps
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                showPanel = true
                            }
                        } label: {
                            ZStack {
                                Circle().fill(.thinMaterial).frame(width: 40, height: 40)
                                Image(systemName: "plus").font(.headline)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Options")
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 6)

                    Text("Shake or tap a die to roll")
                        .font(.subheadline)
                        .foregroundStyle(.black.opacity(0.55))
                        .padding(.bottom, 8)
                }
                .background(Color(UIColor.systemYellow).opacity(0.22))
                .ignoresSafeArea(edges: .bottom)
            }

            // "+" Panel: add one weighted die + set weights
            if showPanel {
                SpeechBubble {
                    VStack(spacing: 10) {
                        HStack {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                    showPanel = false // cancel (discard temp)
                                }
                            } label: { Image(systemName: "xmark") }

                            Spacer()
                            Text("Weighted Die").font(.headline)
                            Spacer()

                            Button {
                                // apply temp → real, rebuild dice set
                                hasWeightedDie = tempHasWeighted
                                weightSteps = tempWeightSteps
                                rebuildLiveDice()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                    showPanel = false
                                }
                            } label: { Text("Done").bold() }
                        }

                        Toggle("Add second die (weighted)", isOn: $tempHasWeighted)
                            .tint(.blue)

                        if tempHasWeighted {
                            // Simple per-face weights using steppers (0..10)
                            VStack(spacing: 8) {
                                ForEach(1...6, id: \.self) { face in
                                    HStack {
                                        Text("\(face)")
                                            .frame(width: 22, alignment: .leading)
                                        Stepper(value: $tempWeightSteps[face-1], in: 0...10) {
                                            Text("Weight: \(tempWeightSteps[face-1])")
                                                .frame(minWidth: 110, alignment: .leading)
                                        }
                                        Spacer()
                                        // live normalized probability
                                        let p = normalizedWeights(from: tempWeightSteps)[face-1]
                                        Text(String(format: "%.0f%%", p * 100))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                HStack {
                                    Button("Reset fair") {
                                        tempWeightSteps = [1,1,1,1,1,1]
                                    }
                                    .buttonStyle(.bordered)

                                    Spacer()
                                    Text("Sum: \(tempWeightSteps.reduce(0,+))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(10)
                }
                .frame(width: 260)
                .transition(.scale.combined(with: .opacity))
                .padding(.trailing, 16)
                .padding(.bottom, 92)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }

            // Settings panel (same toggles as Home, smaller)
            if showSettingsPanel {
                DiceSettingsPanel(isPresented: $showSettingsPanel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 10, y: -2)
                    .overlay(Divider(), alignment: .top)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        // Shake support (still works, but rolls with haptics only when enabled)
        .onShake {
            if soundOn { DiceSoundPlayer.shared.playRoll(volume: volume) }
            rollAllAnimated()
        }
        // ⬇️ home button removed: let default back button handle navigation
        .onAppear { rebuildLiveDice() }
    }

    // MARK: - Dice logic

    private func rebuildLiveDice() {
        var arr: [LiveDie] = [LiveDie(sides: 6, value: 1, weighted: false)]
        if hasWeightedDie {
            arr.append(LiveDie(sides: 6, value: 1, weighted: true))
        }
        liveDice = arr
        latestTotal = liveDice.map(\.value).reduce(0, +)
    }

    private func rollAllAnimated() {
        guard !isRolling else { return }
        isRolling = true
        if hapticsOn {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        for i in liveDice.indices {
            rollSingleAnimated(index: i, updateTotalAtEnd: false)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            latestTotal = liveDice.map(\.value).reduce(0, +)
            isRolling = false
        }
    }

    private func rollSingleAnimated(index: Int, updateTotalAtEnd: Bool = true) {
        guard liveDice.indices.contains(index) else { return }
        let final = rollValue(for: liveDice[index])

        // start a quick “tumble”
        liveDice[index].spinToken = UUID()

        // fast value cycling -> final
        Task { @MainActor in
            let ticks = 10 + Int.random(in: 0...6)
            for _ in 0..<ticks {
                liveDice[index].value = rollValue(for: liveDice[index], preview: true)
                try? await Task.sleep(nanoseconds: 55_000_000) // 55 ms
            }
            liveDice[index].value = final
            if hapticsOn {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            if updateTotalAtEnd {
                latestTotal = liveDice.map(\.value).reduce(0, +)
            }
        }
    }

    private func rollValue(for die: LiveDie, preview: Bool = false) -> Int {
        if die.weighted {
            return weightedSample(weights: normalizedWeights(from: weightSteps))
        } else {
            return Int.random(in: 1...die.sides)
        }
    }

    private func normalizedWeights(from steps: [Int]) -> [Double] {
        let sum = max(1, steps.reduce(0,+))
        return steps.map { Double($0) / Double(sum) }
    }

    private func weightedSample(weights: [Double]) -> Int {
        let r = Double.random(in: 0..<1)
        var acc = 0.0
        for i in 0..<6 {
            acc += weights[i]
            if r < acc { return i + 1 }
        }
        return 6 // fallback
    }
}

#Preview {
    NavigationStack { DiceRollView() }
}

// MARK: - Settings panel used on Dice screen

private struct DiceSettingsPanel: View {
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
                SettingsToggleChip(title: "Haptics", isOn: $hapticsOn)

                SettingsToggleChip(title: "Sound", isOn: $soundOn) { newValue in
                    if !newValue {
                        volume = 0
                    }
                }
            }
            .padding(.horizontal, 18)

            Spacer(minLength: 8)
        }
        .padding(.top, 6)
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

private struct SettingsToggleChip: View {
    let title: String
    @Binding var isOn: Bool
    var onToggle: ((Bool) -> Void)? = nil

    var body: some View {
        Button {
            isOn.toggle()
            if isOn {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
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

// MARK: - Sound helper

final class DiceSoundPlayer {
    static let shared = DiceSoundPlayer()
    private var player: AVAudioPlayer?

    func playRoll(volume: Double) {
        let clamped = max(0.0, min(volume, 1.0))
        guard clamped > 0 else { return }

        if player == nil {
            if let url = Bundle.main.url(forResource: "dice_roll", withExtension: "wav") {
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
// MARK: - Die + Helpers (unchanged below)

private struct DieView: View {
    let sides: Int
    let value: Int
    let spinToken: UUID

    @State private var rotX: Double = 0
    @State private var rotY: Double = 0
    @State private var rotZ: Double = 0
    @State private var scale: CGFloat = 1

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)

            ZStack {
                RoundedRectangle(cornerRadius: s * 0.18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color(red: 0.93, green: 0.96, blue: 0.98)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: s * 0.18, style: .continuous)
                            .stroke(Color(.sRGB, red: 0.10, green: 0.16, blue: 0.28, opacity: 1), lineWidth: s * 0.06)
                    )
                    .shadow(color: .black.opacity(0.15), radius: s * 0.06, x: 0, y: s * 0.05)

                if sides == 6 {
                    PipsSix(value: value)
                        .padding(s * 0.18)
                } else {
                    Text("\(value)")
                        .font(.system(size: s * 0.45, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black.opacity(0.9))
                }
            }
            .frame(width: s, height: s)
        }
        .scaleEffect(scale)
        .rotation3DEffect(.degrees(rotX), axis: (x: 1, y: 0, z: 0))
        .rotation3DEffect(.degrees(rotY), axis: (x: 0, y: 1, z: 0))
        .rotationEffect(.degrees(rotZ))
        .onChange(of: spinToken) { _, _ in tumble() }
    }

    private func tumble() {
        let d: Double = 0.55
        let rx = Double.random(in: 240...540)
        let ry = Double.random(in: 240...540)
        let rz = Double.random(in: -120...120)

        withAnimation(.easeIn(duration: d * 0.25)) { scale = 0.9 }
        withAnimation(.easeOut(duration: d)) {
            rotX = rx; rotY = ry; rotZ = rz
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + d) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                rotX = 0; rotY = 0; rotZ = 0; scale = 1
            }
        }
    }
}

private struct PipsSix: View {
    let value: Int

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let dot = min(w, h) * 0.18

            let pos: (CGFloat, CGFloat) -> CGPoint = { x, y in
                CGPoint(x: x * w, y: y * h)
            }

            let TL = pos(0.20, 0.20), TR = pos(0.80, 0.20)
            let CL = pos(0.20, 0.50), CC = pos(0.50, 0.50), CR = pos(0.80, 0.50)
            let BL = pos(0.20, 0.80), BR = pos(0.80, 0.80)

            let pts: [CGPoint] = {
                switch value {
                case 1: return [CC]
                case 2: return [TL, BR]
                case 3: return [TL, CC, BR]
                case 4: return [TL, TR, BL, BR]
                case 5: return [TL, TR, CC, BL, BR]
                default: return [TL, CL, BL, TR, CR, BR] // 6
                }
            }()

            ZStack {
                ForEach(0..<pts.count, id: \.self) { i in
                    Circle()
                        .fill(Color.black.opacity(0.9))
                        .frame(width: dot, height: dot)
                        .position(pts[i])
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ArcText: View {
    let text: String
    let radius: CGFloat
    let startAngle: Double
    let endAngle: Double
    var followTangent: Bool = true

    var body: some View {
        ZStack {
            ForEach(Array(text.enumerated()), id: \.offset) { (i, ch) in
                let t = Double(i) / Double(max(text.count - 1, 1))
                let angle = startAngle + (endAngle - startAngle) * t
                let rad = angle * .pi / 180
                let x = cos(rad) * radius
                let y = sin(rad) * radius

                Text(String(ch))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .rotationEffect(.degrees(followTangent ? angle + 90 : 0))
                    .offset(x: x, y: y)
            }
        }
        .frame(width: radius * 2, height: radius * 2)
    }
}

private struct SpeechBubble<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) {
            content
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.18), lineWidth: 1))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)

            Triangle()
                .fill(.ultraThinMaterial)
                .frame(width: 18, height: 10)
                .overlay(Triangle().stroke(Color.black.opacity(0.18), lineWidth: 1))
                .offset(x: 62, y: -1)
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

private struct HandleButton: View {
    var body: some View {
        VStack(spacing: 6) {
            Capsule().fill(Color.gray.opacity(0.35)).frame(width: 44, height: 6)
            Capsule().fill(Color.gray.opacity(0.35)).frame(width: 32, height: 6)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(radius: 2, y: 1)
    }
}
