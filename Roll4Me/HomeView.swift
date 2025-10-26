//
//  HomeView.swift
//  Roll4Me
//

import SwiftUI

struct HomeView: View {
    // slide-up panel state (kept if you want it later)
    @State private var showPanel = false
    private let panelHeight: CGFloat = 300

    // grid spacing & padding
    private let horizontalPadding: CGFloat = 20
    private let interItemSpacing: CGFloat = 22

    // tools list with your asset names
    private var tools: [(title: String, imageName: String, destination: AnyView)] {
        [
            ("Dice Roll", "Dice", AnyView(DiceRollView())),
            ("Coin Flip", "Coin", AnyView(CoinFlipView())),
            ("Spinner", "Spinner", AnyView(SpinnerView())),
            ("Team Generator", "Team Generator", AnyView(TeamGeneratorView())),
            ("Random Order", "Random Order Generator", AnyView(RandomOrderView())),
            ("Random Person", "Random Person Picker", AnyView(RandomPersonView()))
        ]
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // soft background
            LinearGradient(colors: [Color(.systemYellow).opacity(0.16),
                                    Color(.systemGreen).opacity(0.10)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            GeometryReader { geo in
                // adaptive tile width for 2 columns
                let totalSpacing = interItemSpacing + (horizontalPadding * 2)
                let tileWidth = (geo.size.width - totalSpacing) / 2

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // BIG main heading
                        Text("Roll4Me")
                            .font(.system(size: 36, weight: .heavy))
                            .padding(.top, 10)
                            .padding(.horizontal, horizontalPadding)

                        // Sub-heading
                        Text("Let Fate Decide")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, horizontalPadding)
                            .padding(.bottom, 6)

                        // 2-column large tiles
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: interItemSpacing),
                                      GridItem(.flexible(), spacing: interItemSpacing)],
                            spacing: interItemSpacing
                        ) {
                            ForEach(tools, id: \.title) { tool in
                                NavigationLink(destination: tool.destination) {
                                    ToolTileLarge(imageName: tool.imageName, size: tileWidth)
                                }
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, 120) // space for handle/panel if used
                    }
                }
            }

            // three-line handle (kept minimal; toggles panel)
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    showPanel.toggle()
                }
            } label: {
                VStack(spacing: 6) {
                    Capsule().fill(Color.gray.opacity(0.35)).frame(width: 44, height: 6)
                    Capsule().fill(Color.gray.opacity(0.35)).frame(width: 32, height: 6)
                    Capsule().fill(Color.gray.opacity(0.35)).frame(width: 24, height: 6)
                }
                .padding(10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(radius: 3, y: 2)
            }
            .padding(.leading, 16)
            .padding(.bottom, showPanel ? (panelHeight + 16) : 16)

            // slide-up panel (optional – content placeholder)
            if showPanel {
                AccessPanel()
                    .frame(maxWidth: .infinity)
                    .frame(height: panelHeight)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 10, y: -2)
                    .overlay(Divider(), alignment: .top)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 0)
            }
        }
        .navigationBarTitleDisplayMode(.inline) // we use custom big title in content
        .toolbar { ToolbarItem(placement: .principal) { EmptyView() } } // hide nav title
    }
}

private struct ToolTileLarge: View {
    let imageName: String
    let size: CGFloat
    var body: some View {
        ZStack {
            // soft outer shadow
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.clear)
                .shadow(color: .black.opacity(0.14), radius: 8, x: 0, y: 6)

            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        // make tap target comfy
        .frame(width: size, height: size)
    }
}

private struct AccessPanel: View {
    @State private var volume: Double = 0.7
    @State private var hapticsOn = true
    @State private var animationsOn = true

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Color.secondary.opacity(0.25))
                .frame(width: 44, height: 5)
                .padding(.top, 8)

            HStack(spacing: 12) {
                Image(systemName: "speaker.wave.2.fill")
                Slider(value: $volume, in: 0...1)
            }
            .padding(.horizontal, 18)

            HStack(spacing: 14) {
                ToggleChip(title: "Haptics", isOn: $hapticsOn)
                ToggleChip(title: "Animations", isOn: $animationsOn)
            }
            .padding(.horizontal, 18)

            HStack(spacing: 12) {
                PanelButton("Presets")
                PanelButton("History")
            }
            .padding(.horizontal, 18)

            PanelButton("Tutorial / How To Use")
                .padding(.horizontal, 18)

            Spacer()
        }
        .padding(.top, 6)
    }
}

private struct ToggleChip: View {
    let title: String
    @Binding var isOn: Bool
    var body: some View {
        Button {
            isOn.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                Text(title).font(.subheadline).bold()
            }
            .foregroundStyle(isOn ? .primary : .secondary)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

private struct PanelButton: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Button(title) {}
            .font(.subheadline).bold()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    NavigationStack { HomeView() }
}
