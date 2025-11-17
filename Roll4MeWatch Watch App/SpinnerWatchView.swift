import SwiftUI
import WatchKit

private struct WheelSlice: Identifiable {
    let id = UUID()
    let title: String
    let color: Color
}

struct SpinnerWatchView: View {
    @State private var options: [String] = ["A", "B", "C", "D"]
    @State private var rotation: Double = 0
    @State private var spinning = false
    @State private var selected: String = ""

    private let wheelSize: CGFloat = 140

    var body: some View {
        ZStack {
            Color(red: 205/255, green: 232/255, blue: 241/255)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("Result: \(selected.isEmpty ? "—" : selected)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .padding(.top, 4)

                Spacer(minLength: 4)

                ZStack {
                    WatchArcText(
                        text: "Swipe  to  Spin",
                        radius: 60,
                        startAngle: -150,
                        endAngle: -30,
                        followTangent: false
                    )

                    WheelView(slices: buildSlices())
                        .frame(width: wheelSize, height: wheelSize)
                        .rotationEffect(.degrees(rotation))
                        .animation(.easeOut(duration: spinning ? 2.0 : 0), value: rotation)
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    spin(by: Double(value.translation.width))
                                }
                        )

                    Image(systemName: "triangle.fill")
                        .rotationEffect(.degrees(180))
                        .foregroundStyle(.red)
                        .offset(y: -(wheelSize / 2) - 6)
                }

                Spacer()

                VStack(spacing: 4) {
                    Rectangle().fill(Color.black.opacity(0.12)).frame(height: 1)

                    HStack {
                        WatchHandleButton()

                        Spacer()

                        Button("Spin") { spin() }
                            .font(.headline)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.3))
                                    .overlay(
                                        Capsule().stroke(Color.black.opacity(0.15),
                                                         lineWidth: 1)
                                    )
                            )
                            .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 4)
                    // Replaced systemYellow with plain yellow
                    .background(
                        Color.yellow.opacity(0.25)
                            .ignoresSafeArea(edges: .bottom)
                    )
                }
            }
        }
        .navigationTitle("Spinner")
    }

    private func buildSlices() -> [WheelSlice] {
        if options.isEmpty {
            return [WheelSlice(title: "Add", color: .gray)]
        }
        let baseColors: [Color] = (0..<options.count).map { i in
            Color(hue: Double(i) / Double(options.count),
                  saturation: 0.75,
                  brightness: 0.98)
        }
        var slices: [WheelSlice] = []
        for (i, title) in options.enumerated() {
            slices.append(WheelSlice(title: title, color: baseColors[i]))
        }
        return slices
    }

    private func spin(by swipeVelocity: Double = 0) {
        guard !spinning else { return }
        spinning = true
        selected = ""

        let base = Double.random(in: 720...1440)
        let bonus = min(max(swipeVelocity * 2.0, -360), 360)
        let amount = base + bonus

        WKInterfaceDevice.current().play(.start)

        withAnimation(.easeOut(duration: 2.0)) {
            rotation += amount
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let slices = buildSlices()
            let count = max(1, slices.count)
            let final = rotation.truncatingRemainder(dividingBy: 360)
            let sliceAngle = 360.0 / Double(count)
            let corrected = (360 - final + 270).truncatingRemainder(dividingBy: 360)
            let idx = min(count - 1, Int(corrected / sliceAngle) % count)
            selected = slices[idx].title
            WKInterfaceDevice.current().play(.success)
            spinning = false
        }
    }

    private func spin() { spin(by: 0) }
}

#Preview {
    SpinnerWatchView()
}
