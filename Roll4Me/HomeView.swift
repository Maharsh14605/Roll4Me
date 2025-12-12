import SwiftUI

struct HomeView: View {
    @State private var showPanel = false
    private let panelHeight: CGFloat = 180     // smaller panel

    private let horizontalPadding: CGFloat = 20
    private let interItemSpacing: CGFloat = 22

    // Drive background music from Home only
    @AppStorage("roll4me_soundOn") private var soundOn: Bool = true
    @AppStorage("roll4me_volume")  private var volume: Double = 0.7

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
            LinearGradient(
                colors: [Color(.systemYellow).opacity(0.16),
                         Color(.systemGreen).opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                let totalSpacing = interItemSpacing + (horizontalPadding * 2)
                let tileWidth = (geo.size.width - totalSpacing) / 2

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Roll4Me")
                            .font(.system(size: 36, weight: .heavy))
                            .padding(.top, 10)
                            .padding(.horizontal, horizontalPadding)

                        Text("Let Fate Decide")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, horizontalPadding)
                            .padding(.bottom, 6)

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: interItemSpacing),
                                GridItem(.flexible(), spacing: interItemSpacing)
                            ],
                            spacing: interItemSpacing
                        ) {
                            ForEach(tools, id: \.title) { tool in
                                NavigationLink(destination: tool.destination) {
                                    ToolTileLarge(imageName: tool.imageName, size: tileWidth)
                                }
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, 120)
                    }
                }
            }

            // handle button toggles panel
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

            if showPanel {
                AccessPanel(isPresented: $showPanel)
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { EmptyView() }
        }
        // Background music only on Home
        .onAppear {
            BackgroundMusicPlayer.shared.update(soundOn: soundOn, volume: volume)
        }
        .onChange(of: soundOn) { _, newValue in
            BackgroundMusicPlayer.shared.update(soundOn: newValue, volume: volume)
        }
        .onChange(of: volume) { _, newValue in
            BackgroundMusicPlayer.shared.update(soundOn: soundOn, volume: newValue)
        }
        .onDisappear {
            // Stop bg music when leaving Home (Dice, Spinner, etc.)
            BackgroundMusicPlayer.shared.stop()
        }
    }
}

private struct ToolTileLarge: View {
    let imageName: String
    let size: CGFloat
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.clear)
                .shadow(color: .black.opacity(0.14), radius: 8, x: 0, y: 6)

            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .frame(width: size, height: size)
    }
}
// Slim Access Panel (Volume + Haptics + Sound)

private struct AccessPanel: View {
    @Binding var isPresented: Bool

    @AppStorage("roll4me_volume") private var volume: Double = 0.7
    @AppStorage("roll4me_hapticsOn") private var hapticsOn: Bool = true
    @AppStorage("roll4me_soundOn")   private var soundOn: Bool = true

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 44, height: 5)
                .padding(.top, 8)

            // Volume row
            HStack(spacing: 12) {
                Image(systemName: "speaker.wave.2.fill")
                Slider(value: $volume, in: 0...1)
                    .disabled(!soundOn)        // lock slider when sound off
                    .opacity(soundOn ? 1.0 : 0.4)
            }
            .padding(.horizontal, 18)

            // Haptics + Sound toggles
            HStack(spacing: 14) {
                ToggleChip(title: "Haptics", isOn: $hapticsOn)

                ToggleChip(title: "Sound", isOn: $soundOn) { newValue in
                    if !newValue {
                        volume = 0          // turning sound OFF → set volume to 0
                    }
                }
            }
            .padding(.horizontal, 18)

            Spacer(minLength: 8)
        }
        .padding(.top, 6)
        // swipe down to close
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = max(0, value.translation.height)
                }
                .onEnded { value in
                    if value.translation.height > 60 {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            isPresented = false
                        }
                    }
                    dragOffset = 0
                }
        )
    }
}

// Reusable chip 
private struct ToggleChip: View {
    let title: String
    @Binding var isOn: Bool
    var onToggle: ((Bool) -> Void)? = nil

    var body: some View {
        Button {
            isOn.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onToggle?(isOn)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                Text(title)
                    .font(.subheadline).bold()
            }
            .foregroundStyle(isOn ? .primary : .secondary)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

#Preview {
    NavigationStack { HomeView() }
}
