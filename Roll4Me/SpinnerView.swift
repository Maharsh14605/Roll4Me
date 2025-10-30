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
    @State private var weightedSpin: Bool = true   // default ON so you can test bias quickly

    // SPIN STATE
    @State private var rotation: Double = 0
    @State private var spinning = false
    @State private var selected: String = ""
    @State private var dragVelocity: Double = 0

    // SPEECH (disabled in preview)
    @State private var speechAllowed = false
    private let speech = SFSpeechRecognizer()
    
    private let wheelSize: CGFloat = 320
    
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

                    Image(systemName: "triangle.fill")
                        .rotationEffect(.degrees(180))
                        .foregroundStyle(.red)
                        .offset(y: -(wheelSize / 2) - 10)
                }
                .frame(maxHeight: .infinity)

                bottomBar
            }

            if showEditor { editorBubble }
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

        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: showEditor)
    }

    // MARK: Bottom bar
    private var bottomBar: some View {
        VStack(spacing: 8) {
            Rectangle().fill(Color.black.opacity(0.12)).frame(height: 1)

            HStack {
                HandleButton()
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
                Button { showEditor.toggle() } label: {
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
        // 1) Try popping to root (works when inside UINavigationController)
        if let nav = UIApplication.shared.topNavigationController() {
            nav.popToRootViewController(animated: true)
            return
        }
        // 2) SwiftUI fallbacks
        dismiss()
        presentationMode.wrappedValue.dismiss()
    }
    
    // MARK: Editor bubble (now truly scrollable & taller)
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

                // Larger, scrollable list (up to ~40% screen height)
                ScrollView {
                    VStack(spacing: 8) {
                        let totalW = max(1, options.map { max(0, $0.weight) }.reduce(0, +))
                        ForEach($options) { $opt in
                            HStack(spacing: 8) {
                                TextField("Option", text: $opt.title)
                                    .textFieldStyle(.roundedBorder)

                                // Probability preview
                                let p = Int(round(100.0 * Double(max(0, opt.weight)) / Double(totalW)))
                                Text("p \(p)%")
                                    .font(.caption).monospacedDigit()
                                    .frame(width: 54, alignment: .trailing)

                                // Weight stepper (0..20)
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
                .frame(maxHeight: max(220, UIScreen.main.bounds.height * 0.4)) // <<< taller & scrollable

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

    // MARK: Build slices (proportional to weights when ON)
    private func buildSlices() -> [WheelSlice] {
        let valid = options
            .map { SpinOption(title: $0.title.trimmingCharacters(in: .whitespacesAndNewlines), weight: max(0, $0.weight)) }
            .filter { !$0.title.isEmpty }

        if valid.isEmpty {
            return [WheelSlice(title: "Add options", color: .gray)]
        }

        // Palette
        let baseColors: [Color] = (0..<valid.count).map { i in
            let hue = Double(i) / Double(valid.count)
            return Color(hue: hue, saturation: 0.75, brightness: 0.98)
        }

        // Equal or weighted
        let weights = weightedSpin ? valid.map(\.weight) : Array(repeating: 1, count: valid.count)
        let totalW = max(1, weights.reduce(0, +))

        // Target slices
        let target = max(valid.count, valid.count * segmentMultiplier)

        // Apportion slices by largest remainder
        var ideal = weights.map { Double($0) / Double(totalW) * Double(target) }
        var allocated = ideal.map { Int(floor($0)) }
        var remaining = target - allocated.reduce(0, +)
        if remaining > 0 {
            let order = ideal.enumerated().sorted { ($0.element - floor($0.element)) > ($1.element - floor($1.element)) }
            for i in 0..<remaining { allocated[order[i].offset] += 1 }
        }

        var slices: [WheelSlice] = []
        for (i, opt) in valid.enumerated() {
            let color = baseColors[i]
            let copies = max( (weightedSpin ? allocated[i] : 1), 0 )
            for _ in 0..<max(1, copies) {
                slices.append(WheelSlice(title: opt.title, color: color))
            }
        }

        if slices.isEmpty { slices = [WheelSlice(title: "Add options", color: .gray)] }
        return slices
    }

    // MARK: Spin
    private func spin(by swipeVelocity: Double = 0) {
        guard !spinning else { return }
        let slices = buildSlices()
        guard slices.count > 0 else { return }

        spinning = true
        selected = ""

        let base = Double.random(in: 900...1800)
        let bonus = min(max(swipeVelocity * 2.0, -720), 720)
        let amount = base + bonus

        withAnimation(.easeOut(duration: 2.0)) { rotation += amount }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let count = max(1, slices.count)
            let final = rotation.truncatingRemainder(dividingBy: 360)
            let sliceAngle = 360.0 / Double(count)
            let corrected = (360 - final + 270).truncatingRemainder(dividingBy: 360)
            let idx = min(count - 1, Int(corrected / sliceAngle) % count)
            let result = slices[idx].title
            selected = result

            if eliminateAfterHit, let pos = options.firstIndex(where: { $0.title == result }) {
                options.remove(at: pos)
            }

            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
        guard speechAllowed else { return }
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

// MARK: - Wheel rendering
private struct WheelView: View {
    let slices: [WheelSlice]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size/2, y: size/2)
            let radius = size/2
            let count = max(1, slices.count)
            let anglePer = 2 * Double.pi / Double(count)

            Canvas { ctx, _ in
                for (i, s) in slices.enumerated() {
                    let start = Double(i) * anglePer
                    let end   = start + anglePer

                    var path = Path()
                    path.move(to: center)
                    path.addArc(center: center,
                                radius: radius,
                                startAngle: .radians(start),
                                endAngle: .radians(end),
                                clockwise: false)
                    ctx.fill(path, with: .color(s.color))

                    let mid = start + anglePer/2
                    let lx = center.x + radius * 0.62 * CGFloat(cos(mid))
                    let ly = center.y + radius * 0.62 * CGFloat(sin(mid))
                    let label = Text(s.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.black)
                    ctx.draw(label, at: CGPoint(x: lx, y: ly), anchor: .center)
                }

                var rim = Path()
                rim.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius,
                                          width: radius*2, height: radius*2))
                ctx.stroke(rim, with: .color(.white.opacity(0.9)), lineWidth: 10)
                ctx.stroke(rim, with: .color(.gray.opacity(0.35)), lineWidth: 2)
            }
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
        .frame(width: radius*2, height: radius*2)
        .allowsHitTesting(false)
    }
}

// MARK: - Tiny shared views
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
        return p;
    }
}

// MARK: - Preview
#Preview { NavigationStack { SpinnerView() } }
