import SwiftUI

struct SpinnerView: View {
    @State private var optionInput: String = ""
    @State private var options: [String] = ["a", "b", "c", "d", "e", "f", "g"]
    @State private var rotation: Double = 0
    @State private var selectedOption: String?
    @State private var spinning = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Spinner")
                    .font(.largeTitle)
                    .bold()

                Text("Enter options (comma-separated):")
                    .font(.headline)

                TextField("e.g. Apple, Banana, Orange", text: $optionInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        updateOptions()
                    }

                Button("Add Options") {
                    updateOptions()
                }

                ZStack {
                    WheelView(options: options)
                        .frame(width: 300, height: 300)
                        .rotationEffect(.degrees(rotation))
                        .animation(.easeOut(duration: 2), value: rotation)

                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                        .offset(y: -160)
                }

                Button("🎯 Spin the Wheel") {
                    spin()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)

                if let result = selectedOption, !spinning {
                    Text("🎉 Selected: \(result)")
                        .font(.title2)
                        .padding()
                }

                Spacer()
            }
            .padding()
        }
    }

    func updateOptions() {
        let items = optionInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !items.isEmpty {
            options = items
            selectedOption = nil
            optionInput = ""
        }
    }

    func spin() {
        spinning = true
        selectedOption = nil

        let spinAmount = Double.random(in: 720...1440)
        withAnimation {
            rotation += spinAmount
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let finalRotation = rotation.truncatingRemainder(dividingBy: 360)
            let sliceAngle = 360.0 / Double(options.count)

            
            let adjustedRotation = (360 - finalRotation + 270).truncatingRemainder(dividingBy: 360)
            let index = Int(adjustedRotation / sliceAngle) % options.count

            selectedOption = options[index]
            spinning = false
        }
    }
}

struct WheelView: View {
    let options: [String]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = size / 2
            let anglePerSegment = 2 * .pi / Double(options.count)

            Canvas { context, _ in
                for (index, option) in options.enumerated() {
                    let startAngle = Double(index) * anglePerSegment
                    let endAngle = startAngle + anglePerSegment

                    var path = Path()
                    path.move(to: center)
                    path.addArc(center: center, radius: radius,
                                startAngle: Angle(radians: startAngle),
                                endAngle: Angle(radians: endAngle),
                                clockwise: false)

                    let hue = Double(index) / Double(options.count)
                    context.fill(path, with: .color(Color(hue: hue, saturation: 0.6, brightness: 1.0)))

                    let midAngle = startAngle + anglePerSegment / 2
                    let labelX = center.x + radius * 0.6 * cos(midAngle)
                    let labelY = center.y + radius * 0.6 * sin(midAngle)
                    let label = Text(option)
                        .font(.caption)
                        .foregroundColor(.black)
                    context.draw(label, at: CGPoint(x: labelX, y: labelY), anchor: .center)
                }
            }
        }
    }
}
