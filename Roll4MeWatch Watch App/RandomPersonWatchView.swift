import SwiftUI
import WatchKit

struct RandomPersonWatchView: View {
    // How many “fingers / people” are in the game
    @State private var fingerCount: Int = 6          // 1…10
    // How many winners to choose (you can set this to 1 always if you want)
    @State private var winnersToPick: Int = 1        // 1…fingerCount

    // Animation / selection state
    @State private var highlightedIndex: Int? = nil  // currently hopping circle
    @State private var chosenIndices: Set<Int> = []  // final red circles
    @State private var isSelecting = false

    // Bubble for adjusting “choose N”
    @State private var showChooserBubble = false

    // Layout: 2 columns grid of circles
    private var columns: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }

    var body: some View {
        ZStack {
            // soft pink background like the mock
            Color(red: 244/255, green: 222/255, blue: 244/255)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("Random Finger")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .padding(.top, 4)

                Spacer(minLength: 4)

                // Circles representing each finger / person
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(0..<fingerCount, id: \.self) { i in
                        fingerCircle(for: i)
                    }
                }
                .padding(.horizontal, 6)

                Spacer(minLength: 4)

                bottomBar
            }

            if showChooserBubble {
                chooserBubble
            }
        }
        
        .animation(.spring(response: 0.30, dampingFraction: 0.8),
                   value: showChooserBubble)
    }

    // Circles

    private func fingerCircle(for index: Int) -> some View {
        let isHighlighted = highlightedIndex == index
        let isChosen = chosenIndices.contains(index)

        let baseColor = Color.gray.opacity(0.45)
        let highlightColor = Color.blue.opacity(0.7)
        let chosenColor = Color.red

        return Circle()
            .fill(isChosen ? chosenColor : (isHighlighted ? highlightColor : baseColor))
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(isChosen ? 0.4 : 0.2),
                    radius: isChosen ? 6 : 3,
                    y: isChosen ? 3 : 2)
            .scaleEffect(isChosen ? 1.12 : (isHighlighted ? 1.06 : 1.0))
            .frame(height: 34)   // comfortable size on watch
            .animation(.spring(response: 0.25, dampingFraction: 0.8),
                       value: isHighlighted)
            .animation(.spring(response: 0.25, dampingFraction: 0.8),
                       value: isChosen)
    }

    // Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 4) {
            Rectangle().fill(Color.black.opacity(0.15)).frame(height: 1)

            HStack {
                RPMiniHandle()

                Spacer(minLength: 6)

                Button {
                    startSelection()
                } label: {
                    Text(isSelecting ? "Choosing…" : "Choose")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.9))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.black.opacity(0.18), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(isSelecting || fingerCount == 0)

                Spacer(minLength: 6)

                Button {
                    showChooserBubble.toggle()
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.headline)
                        .padding(4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 4)
            .background(
                Color(red: 1.0, green: 0.99, blue: 0.88)
                    .opacity(0.85)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }

    // Bubble to adjust counts

    private var chooserBubble: some View {
        ZStack {
            // tap outside to dismiss
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture { showChooserBubble = false }

            VStack(spacing: 0) {
                VStack(alignment: .center, spacing: 6) {
                    Text("choose")
                        .font(.headline)

                    HStack(spacing: 10) {
                        Button {
                            if winnersToPick > 1 {
                                winnersToPick -= 1
                            }
                        } label: {
                            Image(systemName: "minus")
                                .font(.headline)
                                .padding(6)
                                .background(Color.red.opacity(0.9))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }

                        Text("\(winnersToPick)")
                            .font(.title3)
                            .frame(width: 28)

                        Button {
                            if winnersToPick < max(1, fingerCount) {
                                winnersToPick += 1
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.headline)
                                .padding(6)
                                .background(Color.green.opacity(0.9))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }

                    // adjust how many fingers appear on screen
                    HStack(spacing: 6) {
                        Text("Fingers:")
                            .font(.caption)

                        Stepper("\(fingerCount)",
                                value: $fingerCount,
                                in: 1...10)
                            .labelsHidden()
                    }
                    .font(.caption2)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.99, green: 0.98, blue: 0.90))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black.opacity(0.18), lineWidth: 1)
                )

                RPTriangle()
                    .fill(Color(red: 0.99, green: 0.98, blue: 0.90))
                    .frame(width: 16, height: 10)
                    .overlay(
                        RPTriangle()
                            .stroke(Color.black.opacity(0.18), lineWidth: 1)
                    )
                    .offset(x: 40, y: -1)
            }
            .padding(.bottom, 32)
            .padding(.trailing, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }

    // Selection Logic

    private func startSelection() {
        guard !isSelecting, fingerCount > 0 else { return }

        isSelecting = true
        highlightedIndex = nil
        chosenIndices.removeAll()

        let count = fingerCount
        let winners = min(winnersToPick, count)

        // random visiting order + which indices will stay red
        let order = Array(0..<count).shuffled()
        let winnerSet = Set(order.suffix(winners))

        Task { @MainActor in
            for idx in order {
                highlightedIndex = idx

                if winnerSet.contains(idx) {
                    chosenIndices.insert(idx)
                    WKInterfaceDevice.current().play(.success)
                } else {
                    chosenIndices.remove(idx)
                    WKInterfaceDevice.current().play(.click)
                }

                try? await Task.sleep(nanoseconds: 260_000_000) // 0.26s
            }

            highlightedIndex = nil
            isSelecting = false
        }
    }
}

// Small helpers (watch-safe, prefixed to avoid name clashes)

fileprivate struct RPMiniHandle: View {
    var body: some View {
        VStack(spacing: 4) {
            Capsule().fill(Color.gray.opacity(0.45)).frame(width: 30, height: 4)
            Capsule().fill(Color.gray.opacity(0.45)).frame(width: 22, height: 4)
        }
        .padding(4)
        .background(Color.white.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(radius: 1, y: 1)
    }
}

fileprivate struct RPTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    RandomPersonWatchView()
}
