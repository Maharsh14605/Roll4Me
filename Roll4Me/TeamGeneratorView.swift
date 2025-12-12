import SwiftUI
import UIKit
import AVFoundation

// MARK: - Team Generator
struct TeamGeneratorView: View {
    struct Person: Identifiable, Equatable { let id = UUID(); var name: String }

    // Data
    @State private var teamsCount: Int = 2
    @State private var input: String = ""
    @FocusState private var nameFieldFocused: Bool
    @State private var people: [Person] = []

    // Result
    @State private var teams: [[Person]] = []

    // Inline edit
    @State private var editing: Person?
    @State private var editText: String = ""

    // Finger mode (point + radius)
    struct TouchInfo: Equatable { var point: CGPoint; var radius: CGFloat }
    typealias PointsDict = [Int: TouchInfo]
    @State private var touches: PointsDict = [:]

    // Bias store: personID -> [teamIndex : weight]
    @State private var biasWeights: [UUID: [Int : Int]] = [:]

    // Bias editor UI
    @State private var showBiasSheet = false
    @State private var biasPersonID: UUID?
    @State private var biasTeamIndex: Int = 0
    @State private var biasValue: Int = 1
    @State private var showNoPeopleAlert = false

    // Global settings
    @AppStorage("roll4me_volume")    private var volume: Double = 0.7
    @AppStorage("roll4me_hapticsOn") private var hapticsOn: Bool = true
    @AppStorage("roll4me_soundOn")   private var soundOn: Bool = true

    // Small settings panel
    @State private var showSettingsPanel = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack(alignment: .bottom) {
            background

            ScrollView { content }

            // bottom settings panel
            if showSettingsPanel {
                TeamSettingsPanel(isPresented: $showSettingsPanel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 10, y: -2)
                    .overlay(Divider(), alignment: .top)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: goHome) {
                    Image(systemName: "house.fill").font(.title3)
                }
                .tint(.primary)
                .accessibilityLabel("Home")
            }
        }
        // full-width bottom bar
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .sheet(item: $editing) { person in
            EditNameSheet(title: "Edit Name", text: $editText) {
                let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                if let i = people.firstIndex(of: person) {
                    people[i].name = trimmed
                    teams = []
                }
            }
        }
        .sheet(isPresented: $showBiasSheet) { BiasEditor() }
        .alert("Add at least one name first", isPresented: $showNoPeopleAlert) {
            Button("OK", role: .cancel) {}
        }
    }

    // MARK: UI

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 214/255, green: 235/255, blue: 210/255),
                Color(red: 230/255, green: 245/255, blue: 225/255)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Teams control row
            HStack(spacing: 12) {
                Text("Teams")
                    .font(.title3).bold()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button { if teamsCount > 1 { teamsCount -= 1 } } label: {
                    ControlCapsule(symbol: "minus")
                }

                Text("\(teamsCount)")
                    .font(.title3).bold()
                    .frame(minWidth: 44)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button { teamsCount += 1 } label: {
                    ControlCapsule(symbol: "plus")
                }
            }

            // Input row
            HStack(spacing: 10) {
                TextField("Enter a Name", text: $input)
                    .textFieldStyle(.roundedBorder)
                    .focused($nameFieldFocused)
                    .submitLabel(.done)
                    .onSubmit(addName)

                Button(action: addName) { ControlCapsule(symbol: "plus") }
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if !people.isEmpty {
                // Chips
                WrapLayout(spacing: 8, runSpacing: 8) {
                    ForEach(people) { p in
                        Text(p.name)
                            .font(.subheadline).bold()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(white: 0.96))
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                            .onTapGesture {
                                if let i = people.firstIndex(of: p) {
                                    people.remove(at: i)
                                    teams = []
                                    biasWeights[p.id] = nil
                                }
                            }
                            .onLongPressGesture {
                                editing = p
                                editText = p.name
                            }
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(.thinMaterial))

                // Result teams
                if !teams.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(teams.indices, id: \.self) { t in
                            TeamCard(
                                title: "Team \(t+1)",
                                names: teams[t].map(\.name),
                                tint: teamTint(t)
                            )
                        }
                    }
                }
            } else {
                // Finger mode
                VStack(alignment: .leading, spacing: 8) {
                    Text("Place Your Finger").font(.title2).bold()
                    Text("Use multiple fingers. Colors distinguish teams automatically.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ZStack {
                        RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial)
                        TouchCaptureView(points: $touches, hapticsOn: hapticsOn)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        GeometryReader { _ in
                            // assign team colors based on index, limited by teamsCount
                            let keys = Array(touches.keys).sorted()
                            let palette = teamCirclePalette()
                            let clampedTeams = max(1, min(teamsCount, palette.count))

                            ForEach(Array(keys.enumerated()), id: \.element) { (index, key) in
                                if let info = touches[key] {
                                    let color = palette[index % clampedTeams]
                                    Circle()
                                        .fill(color)
                                        .frame(width: info.radius, height: info.radius)
                                        .position(info.point)
                                        .shadow(radius: 3, y: 1)
                                }
                            }
                        }
                    }
                    // Larger zone – fills most of screen until bottom toolbar
                    .frame(minHeight: UIScreen.main.bounds.height * 0.55)
                }
            }
        }
        .padding(18)
    }

    // MARK: Bottom bar – full width & under home indicator
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.black.opacity(0.12))
                .frame(height: 1)

            HStack {
                // Handle opens/closes settings panel
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        showSettingsPanel.toggle()
                    }
                } label: {
                    HandleButton()
                }

                Spacer()

                Button(action: sortNow) {
                    Text("Sort")
                        .font(.headline)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color(white: 0.98))
                                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                        )
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    if people.isEmpty {
                        showNoPeopleAlert = true
                    } else {
                        biasPersonID = people.first?.id
                        biasTeamIndex = 0
                        biasValue = currentBiasValue(for: people.first!.id, team: 0)
                        showBiasSheet = true
                    }
                } label: {
                    ZStack {
                        Circle().fill(.thinMaterial).frame(width: 36, height: 36)
                        Image(systemName: "plus").font(.headline)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .background(.ultraThinMaterial)
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: Actions

    private func goHome() {
        if let nav = UIApplication.shared.topNavigationController() {
            nav.popToRootViewController(animated: true)
            return
        }
        dismiss()
        presentationMode.wrappedValue.dismiss()
    }

    private func addName() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if hapticsOn {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        let p = Person(name: trimmed)
        people.append(p)
        input = ""
        teams = []
        nameFieldFocused = true
    }

    private func sortNow() {
        guard !people.isEmpty else { return }

        if hapticsOn {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        // 🔊 play team sort sound
        if soundOn {
            TeamSortSoundPlayer.shared.play(volume: volume)
        }

        // capacity per team (balanced)
        let n = people.count
        var cap = Array(repeating: n / teamsCount, count: teamsCount)
        for i in 0..<(n % teamsCount) { cap[i] += 1 }

        var newTeams = Array(repeating: [Person](), count: teamsCount)

        for person in people.shuffled() {
            let remainingTeams = (0..<teamsCount).filter { newTeams[$0].count < cap[$0] }
            let weights = remainingTeams.map { teamWeight(for: person.id, team: $0) }
            let chosenIndex = weightedChoice(indices: remainingTeams, weights: weights)
            newTeams[chosenIndex].append(person)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            teams = newTeams
        }
    }

    // Bias helpers
    private func teamWeight(for id: UUID, team: Int) -> Int {
        max(1, biasWeights[id]?[team] ?? 1)
    }
    private func currentBiasValue(for id: UUID, team: Int) -> Int {
        biasWeights[id]?[team] ?? 1
    }
    private func setBias(for id: UUID, team: Int, value: Int) {
        var map = biasWeights[id] ?? [:]
        map[team] = max(1, min(10, value))
        biasWeights[id] = map
    }
    private func weightedChoice(indices: [Int], weights: [Int]) -> Int {
        let total = max(1, weights.reduce(0,+))
        var r = Int.random(in: 1...total)
        for (i, w) in weights.enumerated() {
            r -= w
            if r <= 0 { return indices[i] }
        }
        return indices.last ?? 0
    }

    // Colors
    private func teamTint(_ i: Int) -> Color {
        let palette: [Color] = [.blue.opacity(0.15), .purple.opacity(0.15), .teal.opacity(0.18),
                                .orange.opacity(0.18), .pink.opacity(0.18), .green.opacity(0.18)]
        return palette[i % palette.count]
    }

    // Base palette for finger circles
    private func teamCirclePalette() -> [Color] {
        [
            .blue.opacity(0.75),
            .red.opacity(0.75),
            .green.opacity(0.75),
            .orange.opacity(0.75),
            .purple.opacity(0.75),
            .pink.opacity(0.75)
        ]
    }

    // MARK: Bias editor sheet
    @ViewBuilder
    private func BiasEditor() -> some View {
        NavigationStack {
            Form {
                Section("Player") {
                    Picker("Person", selection: Binding(
                        get: { biasPersonID ?? people.first?.id },
                        set: { biasPersonID = $0 }
                    )) {
                        ForEach(people) { p in
                            Text(p.name).tag(p.id as UUID?)
                        }
                    }
                }
                Section("Team") {
                    Picker("Team", selection: $biasTeamIndex) {
                        ForEach(0..<teamsCount, id: \.self) { i in
                            Text("Team \(i+1)").tag(i)
                        }
                    }
                }
                Section("Weight (1–10)") {
                    Stepper("w \(biasValue)", value: $biasValue, in: 1...10)
                }
            }
            .navigationTitle("Bias Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showBiasSheet = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let id = biasPersonID {
                            setBias(for: id, team: biasTeamIndex, value: biasValue)
                        }
                        showBiasSheet = false
                    }
                }
            }
            .onAppear {
                if biasPersonID == nil { biasPersonID = people.first?.id }
                if let id = biasPersonID { biasValue = currentBiasValue(for: id, team: biasTeamIndex) }
            }
            .onChange(of: biasPersonID) { _, newID in
                if let id = newID { biasValue = currentBiasValue(for: id, team: biasTeamIndex) }
            }
            .onChange(of: biasTeamIndex) { _, newTeam in
                if let id = biasPersonID { biasValue = currentBiasValue(for: id, team: newTeam) }
            }
        }
    }
}

// MARK: - Components

private struct ControlCapsule: View {
    let symbol: String
    var body: some View {
        Image(systemName: symbol)
            .font(.headline)
            .frame(width: 36, height: 36)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
    }
}

private struct TeamCard: View {
    let title: String
    let names: [String]
    let tint: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(names.indices, id: \.self) { i in Text("• \(names[i])") }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.9)))
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14).fill(tint))
    }
}

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

// MARK: Settings panel + chips

private struct TeamSettingsPanel: View {
    @Binding var isPresented: Bool

    @AppStorage("roll4me_volume")    private var volume: Double = 0.7
    @AppStorage("roll4me_hapticsOn") private var hapticsOn: Bool = true
    @AppStorage("roll4me_soundOn")   private var soundOn: Bool = true

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 44, height: 5)
                .padding(.top, 8)

            HStack(spacing: 12) {
                Image(systemName: "speaker.wave.2.fill")
                Slider(value: $volume, in: 0...1)
                    .disabled(!soundOn)
                    .opacity(soundOn ? 1.0 : 0.4)
            }
            .padding(.horizontal, 18)

            HStack(spacing: 14) {
                SettingsToggleChip(title: "Haptics", isOn: $hapticsOn)

                SettingsToggleChip(title: "Sound", isOn: $soundOn) { newValue in
                    if !newValue { volume = 0 }
                }
            }
            .padding(.horizontal, 18)

            Spacer(minLength: 8)
        }
        .padding(.top, 6)
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

private struct SettingsToggleChip: View {
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

// MARK: Wrap layout

struct WrapLayout: Layout {
    var spacing: CGFloat = 8
    var runSpacing: CGFloat = 8

    init(spacing: CGFloat = 8, runSpacing: CGFloat = 8) {
        self.spacing = spacing; self.runSpacing = runSpacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > maxWidth { x = 0; y += rowH + runSpacing; rowH = 0 }
            rowH = max(rowH, sz.height)
            x += sz.width + spacing
        }
        return CGSize(width: maxWidth, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > bounds.minX + maxWidth { x = bounds.minX; y += rowH + runSpacing; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
        }
    }
}

// MARK: Edit sheet

private struct EditNameSheet: View {
    let title: String
    @Binding var text: String
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form { Section(title) { TextField("Name", text: $text).autocorrectionDisabled() } }
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { onSave(); dismiss() }
                            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
        }
    }
}

// MARK: Touch capture (bigger circles, less “jittery” removal)

private struct TouchCaptureView: UIViewRepresentable {
    @Binding var points: TeamGeneratorView.PointsDict
    var hapticsOn: Bool

    func makeUIView(context: Context) -> TouchView {
        let v = TouchView()
        v.hapticsOn = hapticsOn
        v.onUpdate = { pts in DispatchQueue.main.async { self.points = pts } }
        return v
    }
    func updateUIView(_ uiView: TouchView, context: Context) {
        uiView.hapticsOn = hapticsOn
    }

    final class TouchView: UIView {
        var onUpdate: ((TeamGeneratorView.PointsDict) -> Void)?
        private var pts: TeamGeneratorView.PointsDict = [:]
        var hapticsOn: Bool = true

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
            if hapticsOn {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
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
            if removing {
                for t in touches {
                    let key = t.hash
                    let oldInfo = pts[key]

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                        guard let self = self else { return }
                        if let current = self.pts[key],
                           current.point == oldInfo?.point {
                            self.pts.removeValue(forKey: key)
                            self.onUpdate?(self.pts)
                        }
                    }
                }
            } else {
                for t in touches {
                    let key = t.hash
                    let p = t.location(in: self)

                    let baseRadius: CGFloat
                    if t.majorRadius.isNormal {
                        baseRadius = t.majorRadius * 4.0
                    } else {
                        baseRadius = 96
                    }
                    let r = max(96, baseRadius)

                    pts[key] = TeamGeneratorView.TouchInfo(point: p, radius: r)
                }
                onUpdate?(pts)
            }
        }
    }
}

// MARK: UIKit helper to pop to root
extension UIApplication {
    func topNavigationController() -> UINavigationController? {
        guard let scene = connectedScenes.compactMap({ $0 as? UIWindowScene }).first else { return nil }
        guard let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first else { return nil }
        return window.rootViewController?.findNav()
    }
}
private extension UIViewController {
    func findNav() -> UINavigationController? {
        if let nav = self as? UINavigationController { return nav }
        if let tab = self as? UITabBarController { return tab.selectedViewController?.findNav() }
        if let presented = presentedViewController { return presented.findNav() }
        for child in children {
            if let nav = child.findNav() { return nav }
        }
        return navigationController
    }
}

// MARK: - Team sort sound

final class TeamSortSoundPlayer {
    static let shared = TeamSortSoundPlayer()
    private var player: AVAudioPlayer?

    func play(volume: Double) {
        let clamped = max(0.0, min(volume, 1.0))
        guard clamped > 0 else { return }

        if player == nil {
            if let url = Bundle.main.url(forResource: "questionMark", withExtension: "wav") {
                player = try? AVAudioPlayer(contentsOf: url)
                player?.prepareToPlay()
            }
        }

        guard let player = player else { return }
        player.currentTime = 0
        player.volume = Float(clamped)
        player.play()
    }
}

#Preview {
    NavigationStack { TeamGeneratorView() }
}
