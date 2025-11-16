import SwiftUI
import UIKit

struct RandomPersonView: View {
    // Touch points: UITouch.hash -> CGPoint
    @State private var touches: [Int: CGPoint] = [:]

    // How many fingers to choose
    @State private var chooseCount: Int = 1
    @State private var showChoosePopover = false

    // Selection animation state
    @State private var revealedIDs: Set<Int> = []
    @State private var finalSelectedID: Int?
    @State private var isSelecting = false

    var body: some View {
        ZStack {
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
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .onChange(of: touches) { dict in
            // Clamp choose count when number of fingers changes
            let maxFingers = max(dict.count, 1)
            if chooseCount > maxFingers { chooseCount = maxFingers }
            if chooseCount < 1 { chooseCount = 1 }
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

            GeometryReader { geo in
                ForEach(Array(touches.keys), id: \.self) { key in
                    if let pos = touches[key] {
                        let isWinner = revealedIDs.contains(key)
                        let isFinal = finalSelectedID == key

                        Circle()
                            .fill(circleColor(for: key))
                            .frame(width: 70, height: 70)
                            .scaleEffect(isFinal ? 1.25 : (isWinner ? 1.08 : 1.0))
                            .shadow(radius: 4, y: 2)
                            .position(pos)
                            .animation(.spring(response: 0.35, dampingFraction: 0.55),
                                       value: revealedIDs)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6),
                                       value: finalSelectedID)
                    }
                }
            }
        }
        .frame(height: 360)
    }

    private var bottomBar: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .frame(height: 86)
                .overlay(
                    Rectangle()
                        .fill(Color.black.opacity(0.14))
                        .frame(height: 1),
                    alignment: .top
                )
                .ignoresSafeArea()

            HStack {
                HandleButton()

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
                .disabled(touches.isEmpty || isSelecting)
                .opacity(touches.isEmpty ? 0.4 : 1.0)

                Spacer()

                Button {
                    if !touches.isEmpty {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                            showChoosePopover.toggle()
                        }
                    } else {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    ZStack {
                        Circle().fill(.thinMaterial)
                            .frame(width: 36, height: 36)
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
        }
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

    // MARK: - Logic

    private func startSelection() {
        guard !touches.isEmpty else { return }

        let ids = Array(touches.keys)
        let k = min(max(1, chooseCount), ids.count)
        let winners = Array(ids.shuffled().prefix(k))

        isSelecting = true
        revealedIDs = []
        finalSelectedID = nil

        var delay: Double = 0.0
        for (idx, id) in winners.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                revealedIDs.insert(id)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                if idx == winners.count - 1 {
                    finalSelectedID = id
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    isSelecting = false
                }
            }
            delay += 0.5
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
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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

// MARK: - Preview

#Preview {
    RandomPersonView()
}
