import SwiftUI
import WatchKit

// MARK: - Model

private struct LiveDie: Identifiable, Equatable {
    let id = UUID()
    var sides: Int
    var value: Int
    var weighted: Bool = false
    var spinToken = UUID()
}

// MARK: - View

struct DiceRollWatchView: View {
    @State private var liveDice: [LiveDie] = [LiveDie(sides: 6, value: 1, weighted: false)]

    @State private var hasWeightedDie = false
    @State private var weightSteps = [1,1,1,1,1,1]

    @State private var tempHasWeighted = false
    @State private var tempWeightSteps = [1,1,1,1,1,1]

    @State private var latestTotal = 1
    @State private var showPanel = false
    @State private var isRolling = false

    var body: some View {
        ZStack {
            Color(red: 214/255, green: 166/255, blue: 162/255)
                .opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("Result: \(latestTotal)")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .padding(.top, 4)

                ZStack {
                    WatchArcText(
                        text: "Shake  to  Roll",
                        radius: 60,
                        startAngle: -140,
                        endAngle: -40,
                        followTangent: true
                    )
                    .foregroundStyle(.black.opacity(0.75))

                    let columns: [GridItem] =
                        liveDice.count == 1
                        ? [GridItem(.flexible())]
                        : [GridItem(.flexible(), spacing: 12),
                           GridItem(.flexible(), spacing: 12)]

                    LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
                        ForEach(liveDice.indices, id: \.self) { i in
                            DieView(
                                sides: liveDice[i].sides,
                                value: liveDice[i].value,
                                spinToken: liveDice[i].spinToken
                            )
                            .frame(width: 70, height: 70)
                            .onTapGesture { rollSingleAnimated(index: i) }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 30)
                }
                .frame(maxHeight: .infinity)

                bottomBar
            }

            if showPanel {
                WatchSpeechBubble {
                    VStack(spacing: 8) {
                        HStack {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                    showPanel = false
                                }
                            } label: {
                                Image(systemName: "xmark")
                            }

                            Spacer()
                            Text("Weighted Die").font(.headline)
                            Spacer()

                            Button {
                                hasWeightedDie = tempHasWeighted
                                weightSteps = tempWeightSteps
                                rebuildLiveDice()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                    showPanel = false
                                }
                            } label: {
                                Text("Done").bold()
                            }
                        }

                        Toggle("Add second die", isOn: $tempHasWeighted)

                        if tempHasWeighted {
                            VStack(spacing: 6) {
                                ForEach(1...6, id: \.self) { face in
                                    HStack {
                                        Text("\(face)")
                                            .frame(width: 16, alignment: .leading)
                                        Stepper(value: $tempWeightSteps[face-1], in: 0...10) {
                                            Text("w \(tempWeightSteps[face-1])")
                                        }
                                        .labelsHidden()

                                        let p = normalizedWeights(from: tempWeightSteps)[face-1]
                                        Text(String(format: "%.0f%%", p * 100))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                HStack {
                                    Button("Reset fair") {
                                        tempWeightSteps = [1,1,1,1,1,1]
                                    }
                                    .buttonStyle(.bordered)

                                    Spacer()
                                    Text("Sum \(tempWeightSteps.reduce(0,+))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(8)
                }
                .frame(width: 210)
                .transition(.scale.combined(with: .opacity))
                .padding(.trailing, 10)
                .padding(.bottom, 60)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
        .onAppear { rebuildLiveDice() }
//        .navigationTitle("Dice Roll")
    }

    private var bottomBar: some View {
        VStack(spacing: 4) {
            Rectangle().fill(Color.black.opacity(0.12)).frame(height: 1)

            HStack {
                WatchHandleButton()

                Spacer()

                Button { rollAllAnimated() } label: {
                    Text("Roll")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(red: 214/255, green: 166/255, blue: 162/255))
                                .overlay(
                                    Capsule().stroke(Color.black.opacity(0.15), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    tempHasWeighted = hasWeightedDie
                    tempWeightSteps = weightSteps
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        showPanel = true
                    }
                } label: {
                    ZStack {
                        Circle().fill(.thinMaterial).frame(width: 28, height: 28)
                        Image(systemName: "plus").font(.headline)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 4)
            .background(Color.yellow.opacity(0.22).ignoresSafeArea(edges: .bottom))
        }
    }

    // MARK: Logic

    private func hapticMedium() { WKInterfaceDevice.current().play(.directionUp) }
    private func hapticLight()  { WKInterfaceDevice.current().play(.click) }

    private func rebuildLiveDice() {
        var arr: [LiveDie] = [LiveDie(sides: 6, value: 1, weighted: false)]
        if hasWeightedDie {
            arr.append(LiveDie(sides: 6, value: 1, weighted: true))
        }
        liveDice = arr
        latestTotal = liveDice.map(\.value).reduce(0,+)
    }

    private func rollAllAnimated() {
        guard !isRolling else { return }
        isRolling = true
        hapticMedium()

        for i in liveDice.indices {
            rollSingleAnimated(index: i, updateTotalAtEnd: false)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            latestTotal = liveDice.map(\.value).reduce(0,+)
            isRolling = false
        }
    }

    private func rollSingleAnimated(index: Int, updateTotalAtEnd: Bool = true) {
        guard liveDice.indices.contains(index) else { return }
        let final = rollValue(for: liveDice[index])

        liveDice[index].spinToken = UUID()

        Task { @MainActor in
            let ticks = 10 + Int.random(in: 0...6)
            for _ in 0..<ticks {
                liveDice[index].value = rollValue(for: liveDice[index], preview: true)
                try? await Task.sleep(nanoseconds: 55_000_000)
            }
            liveDice[index].value = final
            hapticLight()
            if updateTotalAtEnd {
                latestTotal = liveDice.map(\.value).reduce(0,+)
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
        for i in 0..<weights.count {
            acc += weights[i]
            if r < acc { return i + 1 }
        }
        return weights.count
    }
}

#Preview {
    DiceRollWatchView()
}

// MARK: - DieView & Pips (shared with all dice)

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
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: s * 0.18, style: .continuous)
                            .stroke(Color(.sRGB, red: 0.10, green: 0.16, blue: 0.28, opacity: 1),
                                    lineWidth: s * 0.06)
                    )
                    .shadow(color: .black.opacity(0.15),
                            radius: s * 0.06, x: 0, y: s * 0.05)

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
        .onChange(of: spinToken) { _, _ in
            tumble()
        }
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
                default: return [TL, CL, BL, TR, CR, BR]
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
