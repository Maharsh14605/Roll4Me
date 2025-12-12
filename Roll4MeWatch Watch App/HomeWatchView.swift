import SwiftUI

/// Main menu for the watch app – shows all RNG tools.
struct HomeWatchView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Let Fate Decide") {
                    NavigationLink {
                        DiceRollWatchView()
                    } label: {
                        menuRow(
                            title: "Dice Roll",
                            subtitle: "Roll one or two dice",
                            systemImage: "die.face.5"
                        )
                    }

                    NavigationLink {
                        CoinFlipWatchView()
                    } label: {
                        menuRow(
                            title: "Coin Flip",
                            subtitle: "Heads or tails",
                            systemImage: "centsign.circle"
                        )
                    }

           

                

                    NavigationLink {
                        RandomPersonWatchView()   // your finger chooser version
                    } label: {
                        menuRow(
                            title: "Finger Chooser",
                            subtitle: "Pick random person",
                            systemImage: "hand.point.up.left.fill"
                        )
                    }
                }
            }
            .navigationTitle("Roll4Me")
        }
    }

    // MARK: - Row helper

    private func menuRow(title: String,
                         subtitle: String,
                         systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title3)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
#Preview {
    HomeWatchView()
}
