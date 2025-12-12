import SwiftUI
import AVFoundation
import Speech

// MARK: - Models
private struct SpinOption: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var weight: Int = 1
}

private struct WheelSlice: Identifiable {
    let id = UUID()
    let title: String
    let color: Color
    let startDeg: Double   // in degrees, BEFORE wheel rotation
    let endDeg: Double
}

@MainActor
struct SpinnerView: View {
    private let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"

    // OPTIONS
    @State private var options: [SpinOption] = [
        .init(title: "A", weight: 1),
        .init(title: "B", weight: 1),
        .init(title: "C", weight: 1),
        .init(title: "D", weight: 1)
    ]

    // EDITOR
    @State private var bulkInput: String = ""
    @State private var showEditor = false
    @FocusState private var inputFocused: Bool

    // SETTINGS
    @State private var segmentMultiplier: Int = 1
    @State private var eliminateAfterHit: Bool = false
    @State private var weightedSpin: Bool = true

    // SPIN STATE
    @State private var rotation: Double = 0
    @State private var spinning = false
    @State private var selected: String = ""
    @State private var dragVelocity: Double = 0

    // Haptic tick timer while spinning
    @State private var spinHapticTimer: Timer? = nil

    // SPEECH (disabled in preview)
    @State private var speechAllowed = false
    private let speech = SFSpeechRecognizer()

    private let wheelSize: CGFloat = 320

    // Global settings (shared with other tools)
    @AppStorage("roll4me_volume")    private var volume: Double = 0.7
    @AppStorage("roll4me_hapticsOn") private var hapticsOn: Bool = true
    @AppStorage("roll4me_soundOn")   private var soundOn: Bool = true

    // Small settings panel
    @State private var showSettingsPanel = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            Color(red: 205/255, green: 232/255, blue: 241/255).ignoresSafeArea()

            VStack(spacing: 0) {
                Text("Result: \(selected.isEmpty ? "—" : selected)")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .padding(.top, 14)

                Spacer(minLength: 8)

                ZStack {
                    ArcText(text: "Swipe  to  Spin",
                            radius: 140,
                            startAngle: -150,
                            endAngle: -30,
                            fontSize: 28)

                    WheelView(slices: buildSlices())
                        .frame(width: wheelSize, height: wheelSize)
                        .rotationEffect(.degrees(rotation))
                        .animation(.easeOut(duration: spinning ? 2.0 : 0), value: rotation)
                        .gesture(
                            DragGesture()
                                .onChanged { value in dragVelocity = Double(value.translation.width) }
                                .onEnded { _ in spin(by: dragVelocity); dragVelocity = 0 }
                        )

                    Triangle()
                        .fill(Color.yellow)
                        .frame(width: 30, height: 18)
                        .shadow(color: .black.opacity(0.18), radius: 3, y: 2)
                        .offset(y: -(wheelSize / 2) - 4)
                }
                .frame(maxHeight: .infinity)

                bottomBar
            }

            if showEditor { editorBubble }

            // Small bottom settings panel
            if showSettingsPanel {
                SpinnerSettingsPanel(isPresented: $showSettingsPanel)
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

    
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: showEditor)
        .onDisappear {
            // make sure timer dies if you leave the screen
            spinHapticTimer?.invalidate()
            spinHapticTimer = nil
        }
    }

    // MARK: Bottom bar
    private var bottomBar: some View {
        VStack(spacing: 8) {
            Rectangle().fill(Color.black.opacity(0.12)).frame(height: 1)

            HStack {
                // Handle toggles settings panel
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        showSettingsPanel.toggle()
                    }
                } label: {
                    HandleButton()
                }

                Spacer()

                Button { spin() } label: {
                    Text("Spin")
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.horizontal, 34).padding(.vertical, 12)
                        .background(
                            Capsule().fill(Color.blue.opacity(0.25))
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
                        Image(systemName: showEditor ? "xmark" : "plus").font(.headline)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 10)

            Text(spinning ? "Spinning…" : "Ready")
                .font(.subheadline).foregroundStyle(.black.opacity(0.55))
                .padding(.bottom, 6)
        }
        .background(Color(UIColor.systemYellow).opacity(0.22))
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: Actions

    private func goHome() {
        if let nav = UIApplication.shared.topNavigationController() {
            nav.popToRootViewController(animated: true)
            return
        }
        dismiss()
        presentationMode.wrappedValue.dismiss()
    }

    // MARK: Editor bubble
    private var editorBubble: some View {
        SpeechBubble {
            VStack(spacing: 10) {
                HStack {
                    Text("Options").font(.headline)
                    Spacer()
                    Button("Done") { showEditor = false }.bold()
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Add (comma or newline)")
                        .font(.caption).foregroundColor(.secondary)
                    TextField("e.g. Alice, Bob, Carol", text: $bulkInput)
                        .textFieldStyle(.roundedBorder)
                        .focused($inputFocused)

                    HStack(spacing: 10) {
                        Button { addFromBulk() } label: {
                            Label("Add", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            if !isPreview { startSpeechDictation() }
                        } label: { Image(systemName: "mic.fill") }
                        .buttonStyle(.bordered)
                        .disabled(isPreview || !speechAllowed)
                        .help(isPreview ? "Mic disabled in Preview" : "Dictate items")
                    }
                }

                ScrollView {
                    VStack(spacing: 8) {
                        let totalW = max(1, options.map { max(0, $0.weight) }.reduce(0, +))
                        ForEach($options) { $opt in
                            HStack(spacing: 8) {
                                TextField("Option", text: $opt.title)
                                    .textFieldStyle(.roundedBorder)

                                let p = Int(
                                    round(
                                        100.0 * Double(max(0, opt.weight * segmentMultiplier)) /
                                        Double(max(1, totalW * segmentMultiplier))
                                    )
                                )
                                Text("p \(p)%")
                                    .font(.caption).monospacedDigit()
                                    .frame(width: 54, alignment: .trailing)

                                Stepper(value: $opt.weight, in: 0...20) {
                                    Text("w \(opt.weight)")
                                        .font(.caption).monospacedDigit()
                                        .frame(width: 44, alignment: .trailing)
                                }
                                .labelsHidden()

                                Button(role: .destructive) {
                                    options.removeAll { $0.id == opt.id }
                                } label: { Image(systemName: "trash") }
                            }
                        }
                    }
                    .padding(.bottom, 2)
                }
                .frame(maxHeight: max(220, UIScreen.main.bounds.height * 0.4))

                HStack {
                    Toggle("Weighted", isOn: $weightedSpin)
                    Spacer()
                    Toggle("Eliminate after hit", isOn: $eliminateAfterHit)
                }
                .font(.subheadline)

                HStack {
                    Text("Segments x\(segmentMultiplier)")
                    Spacer()
                    Stepper("", value: $segmentMultiplier, in: 1...5).labelsHidden()
                }
                .font(.subheadline)
            }
            .padding(12)
            .frame(maxWidth: 360)
        }
        .padding(.trailing, 18)
        .padding(.bottom, 100)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: Build slices – one contiguous wedge per option
    private func buildSlices() -> [WheelSlice] {
        let valid = options
            .map { SpinOption(title: $0.title.trimmingCharacters(in: .whitespacesAndNewlines),
                              weight: max(0, $0.weight)) }
            .filter { !$0.title.isEmpty }

        if valid.isEmpty {
            return [WheelSlice(title: "Add options",
                               color: .gray,
                               startDeg: -90,
                               endDeg: 270)]
        }

        let palette: [Color] = [
            Color(red: 0.98, green: 0.62, blue: 0.62),
            Color(red: 0.99, green: 0.80, blue: 0.64),
            Color(red: 0.64, green: 0.86, blue: 0.82),
            Color(red: 0.69, green: 0.72, blue: 0.95),
            Color(red: 0.96, green: 0.73, blue: 0.88),
            Color(red: 0.60, green: 0.83, blue: 0.63)
        ]

        let baseColors: [Color] = (0..<valid.count).map { palette[$0 % palette.count] }

        let rawWeights: [Int] = weightedSpin
            ? valid.map(\.weight)
            : Array(repeating: 1, count: valid.count)

        let weights = rawWeights.map { max(0, $0 * max(1, segmentMultiplier)) }
        let totalW = max(1, weights.reduce(0, +))

        var slices: [WheelSlice] = []
        var currentDeg: Double = -90.0

        for (index, opt) in valid.enumerated() {
            let w = max(0, weights[index])
            guard w > 0 else { continue }

            let sweep = 360.0 * Double(w) / Double(totalW)
            let start = currentDeg
            let end   = currentDeg + sweep

            slices.append(
                WheelSlice(title: opt.title,
                           color: baseColors[index],
                           startDeg: start,
                           endDeg: end)
            )
            currentDeg = end
        }

        return slices
    }

    // MARK: Spin
    private func spin(by swipeVelocity: Double = 0) {
        guard !spinning else { return }
        let slices = buildSlices()
        guard !slices.isEmpty else { return }

        // cancel any previous tick timer
        spinHapticTimer?.invalidate()
        spinHapticTimer = nil

        spinning = true
        selected = ""

        // 🎵 play spinner sound
        if soundOn {
            SpinnerSoundPlayer.shared.playSpin(volume: volume)
        }

        // start tick haptics while spinning
        if hapticsOn {
            spinHapticTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
                if !spinning || !hapticsOn {
                    spinHapticTimer?.invalidate()
                    spinHapticTimer = nil
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }

        let base  = Double.random(in: 900...1800)
        let bonus = min(max(swipeVelocity * 2.0, -720), 720)
        let amount = base + bonus

        withAnimation(.easeOut(duration: 1.0)) {
            rotation += amount
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            let finalRotation = rotation

            func norm(_ a: Double) -> Double {
                var x = a.truncatingRemainder(dividingBy: 360)
                if x < 0 { x += 360 }
                return x
            }
            func angleDiff(_ a: Double, _ b: Double) -> Double {
                let d = abs(norm(a - b))
                return d > 180 ? 360 - d : d
            }

            let pointerAngle = -90.0

            var bestIndex = 0
            var bestDiff = Double.greatestFiniteMagnitude

            for (i, slice) in slices.enumerated() {
                let mid = (slice.startDeg + slice.endDeg) / 2 + finalRotation
                let diff = angleDiff(mid, pointerAngle)
                if diff < bestDiff {
                    bestDiff = diff
                    bestIndex = i
                }
            }

            let result = slices[bestIndex].title
            selected = result

            if eliminateAfterHit,
               let pos = options.firstIndex(where: { $0.title == result }) {
                options.remove(at: pos)
            }

            // stop tick haptics
            spinHapticTimer?.invalidate()
            spinHapticTimer = nil

            if hapticsOn {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            spinning = false
        }
    }

    // MARK: Input helpers
    private func addFromBulk() {
        let parts = bulkInput
            .split(whereSeparator: { $0 == "," || $0 == "\n" })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !parts.isEmpty else { return }
        for p in parts { options.append(.init(title: p, weight: 1)) }
        bulkInput = ""
        inputFocused = false
    }

    // MARK: Speech (guarded)
    private func requestSpeechIfNeeded() {
        SFSpeechRecognizer.requestAuthorization { auth in
            Task { @MainActor in
                speechAllowed = (auth == .authorized)
            }
        }
    }

    private func startSpeechDictation() {
        guard !isPreview else { return }
        guard speechAllowed else { requestSpeechIfNeeded(); return }
        let audioEngine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        guard let recognizer = speech, recognizer.isAvailable else { return }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try? audioEngine.start()

        recognizer.recognitionTask(with: request) { result, error in
            if let r = result { self.bulkInput = r.bestTranscription.formattedString }
            if error != nil || (result?.isFinal ?? false) {
                request.endAudio()
                audioEngine.stop()
                inputNode.removeTap(onBus: 0)
            }
        }
    }
}

// MARK: - Settings panel for spinner
private struct SpinnerSettingsPanel: View {
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
                    if !newValue { volume = 0 }
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

// MARK: - Wheel rendering
private struct WheelView: View {
    let slices: [WheelSlice]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)

            Canvas { ctx, canvasSize in
                let rect   = CGRect(origin: .zero, size: canvasSize)
                let center = CGPoint(x: rect.midX, y: rect.midY)
                let radius = min(rect.width, rect.height) / 2 - 6

                // Drop shadow + base disc
                ctx.addFilter(.shadow(color: .black.opacity(0.18),
                                      radius: 10, x: 0, y: 6))
                ctx.drawLayer { inner in
                    let baseRect = CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    let baseCircle = Path(ellipseIn: baseRect)
                    inner.fill(baseCircle, with: .color(.white))
                }

                // Slices with white dividers
                ctx.drawLayer { inner in
                    for slice in slices {
                        let startRad = slice.startDeg * .pi / 180
                        let endRad   = slice.endDeg   * .pi / 180

                        var wedge = Path()
                        wedge.move(to: center)
                        wedge.addArc(center: center,
                                     radius: radius - 10,
                                     startAngle: .radians(startRad),
                                     endAngle: .radians(endRad),
                                     clockwise: false)
                        wedge.closeSubpath()

                        inner.fill(wedge, with: .color(slice.color))
                        inner.stroke(wedge, with: .color(.white), lineWidth: 4)
                    }
                }

                // Labels
                for slice in slices {
                    let midDeg = (slice.startDeg + slice.endDeg) / 2
                    let midRad = midDeg * .pi / 180
                    let textRadius = radius * 0.60

                    let lx = center.x + textRadius * CGFloat(cos(midRad))
                    let ly = center.y + textRadius * CGFloat(sin(midRad))

                    let labelText = Text(slice.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)

                    ctx.draw(labelText, at: CGPoint(x: lx, y: ly), anchor: .center)
                }

                // Outer rim
                let rimRect = CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                let rim = Path(ellipseIn: rimRect)
                ctx.stroke(rim, with: .color(.white), lineWidth: 10)
                ctx.stroke(rim, with: .color(.gray.opacity(0.25)), lineWidth: 2)

                // Center hub
                let hubOuterR: CGFloat = radius * 0.26
                let hubInnerR: CGFloat = radius * 0.18

                let hubOuterRect = CGRect(
                    x: center.x - hubOuterR,
                    y: center.y - hubOuterR,
                    width: hubOuterR * 2,
                    height: hubOuterR * 2
                )
                let hubOuter = Path(ellipseIn: hubOuterRect)
                ctx.fill(hubOuter, with: .color(.white))
                ctx.stroke(hubOuter, with: .color(.gray.opacity(0.3)), lineWidth: 3)

                let hubInnerRect = CGRect(
                    x: center.x - hubInnerR,
                    y: center.y - hubInnerR,
                    width: hubInnerR * 2,
                    height: hubInnerR * 2
                )
                let hubInner = Path(ellipseIn: hubInnerRect)
                ctx.fill(hubInner, with: .color(.yellow))
            }
            .frame(width: size, height: size)
        }
    }
}

// MARK: - Arc text
private struct ArcText: View {
    let text: String
    let radius: CGFloat
    let startAngle: Double
    let endAngle: Double
    var fontSize: CGFloat = 24

    var body: some View {
        ZStack {
            ForEach(Array(text.enumerated()), id: \.offset) { (i, ch) in
                let t = Double(i) / Double(max(text.count - 1, 1))
                let ang = startAngle + (endAngle - startAngle) * t
                let rad = ang * Double.pi / 180
                let x = cos(rad) * radius
                let y = sin(rad) * radius

                Text(String(ch))
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .rotationEffect(.degrees(ang + 90))
                    .offset(x: x, y: y)
            }
        }
        .frame(width: radius * 2, height: radius * 2)
        .allowsHitTesting(false)
    }
}

// MARK: - Small shared views
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

// MARK: - Spinner sound helper
final class SpinnerSoundPlayer {
    static let shared = SpinnerSoundPlayer()
    private var player: AVAudioPlayer?

    private init() {}

    func playSpin(volume: Double) {
        let clamped = max(0.0, min(volume, 1.0))
        guard clamped > 0 else { return }

        if player == nil {
            if let url = Bundle.main.url(forResource: "spinner", withExtension: "wav") {
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
#Preview { NavigationStack { SpinnerView() } }
