import SwiftUI
import WatchKit

struct CoinFlipWatchView: View {
    @State private var result: String = "Heads"
    @State private var angle: Double = 0
    @State private var isFlipping = false

    var body: some View {
        ZStack {
            Color(red: 240/255, green: 228/255, blue: 190/255)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                Text("Coin Flip")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .padding(.top, 4)

                Spacer(minLength: 4)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white, Color.yellow.opacity(0.8)],
                                center: .center,
                                startRadius: 4,
                                endRadius: 60
                            )
                        )
                        .overlay(
                            Circle().stroke(Color.black.opacity(0.25), lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 6, y: 4)

                    Text(result)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .frame(width: 90, height: 90)
                .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0))
                .animation(.easeInOut(duration: 0.6), value: angle)
                .onTapGesture { flip() }

                Spacer()

                VStack(spacing: 4) {
                    Rectangle().fill(Color.black.opacity(0.12)).frame(height: 1)

                    HStack {
                        WatchHandleButton()
                        Spacer()
                        Button("Flip") { flip() }
                            .font(.headline)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.yellow.opacity(0.7))
                                    .overlay(
                                        Capsule().stroke(Color.black.opacity(0.15),
                                                         lineWidth: 1)
                                    )
                            )
                            .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 4)
                    // Replaced systemBackground with plain color
                    .background(
                        Color.white.opacity(0.5)
                            .ignoresSafeArea(edges: .bottom)
                    )
                }
            }
        }
        .navigationTitle("Coin Flip")
    }

    private func flip() {
        guard !isFlipping else { return }
        isFlipping = true
        WKInterfaceDevice.current().play(.start)

        angle += 720

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            result = Bool.random() ? "Heads" : "Tails"
            WKInterfaceDevice.current().play(.success)
            isFlipping = false
        }
    }
}

#Preview {
    CoinFlipWatchView()
}
