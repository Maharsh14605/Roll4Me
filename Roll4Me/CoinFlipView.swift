//
//  CoinFlipView.swift
//  ToDoAppApp
//
//  Created by You on 24/10/25.
//

import SwiftUI

struct CoinFlipView: View {
    // current side (true = Heads, false = Tails)
    @State private var isHeads = true
    // rotation angle for 3D flip
    @State private var angle: Double = 0
    // how many flips happened
    @State private var flipCount = 0
    // while animating, show "?"
    @State private var isFlipping = false

    var body: some View {
        VStack(spacing: 36) {
            Spacer()

            Text("Coin Flip").font(.largeTitle).bold()

            // coin view (no assets needed)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(colors: [.yellow, .orange], center: .center, startRadius: 10, endRadius: 120)
                    )
                    .frame(width: 160, height: 160)
                    .shadow(radius: 8)

                // Face label (changes after flip completes)
                Text(isFlipping ? "?" : (isHeads ? "Heads" : "Tails"))
                    .font(.title)
                    .bold()
                    .foregroundStyle(.black.opacity(0.8))
            }
            .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0)) // y-axis flip
            .animation(.easeOut(duration: 0.7), value: angle)

            Button("Flip Coin") {
                flipCoin()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(width: 200)
            .background(Color.blue)
            .cornerRadius(12)

            Text("Flipped \(flipCount) times")
                .font(.subheadline)
                .foregroundColor(.gray)

            Spacer()
        }
        .padding()
        .navigationTitle("Coin Flip")
    }

    // MARK: - Logic
    private func flipCoin() {
        // small haptic
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // number of full spins (2–5) for a nicer feel
        let spins = Int.random(in: 2...5)
        // final side
        let finalIsHeads = Bool.random()

        // Show "?" while flipping
        isFlipping = true

        // Animate rotation: spins * 360 plus 0 (Heads) or 180 (Tails)
        angle += Double(spins * 360) + (finalIsHeads ? 0 : 180)

        // After animation ends, set result + count
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            isHeads = finalIsHeads
            flipCount += 1
            isFlipping = false
        }
    }
}

#Preview {
    NavigationStack { CoinFlipView() }
}
