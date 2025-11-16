import SwiftUI

struct RandomOrderView: View {
    // Input + data
    @State private var itemInput: String = ""
    @State private var items: [String] = []          // starts empty (no placeholder players)
    @State private var result: [String] = []

    // Editing
    @State private var editingIndex: Int? = nil
    @State private var editText: String = ""
    @FocusState private var inputFocused: Bool

    // Simple layout helper for chips
    private let columns = [GridItem(.adaptive(minimum: 130), spacing: 8)]

    var body: some View {
        ZStack {
            background

            VStack(spacing: 16) {
                header
                inputRow
                namesGrid
                dividerLine
                resultCard
                Spacer(minLength: 8)
            }
            .padding(18)
        }
        // Edit sheet
        .sheet(isPresented: Binding(
            get: { editingIndex != nil },
            set: { if !$0 { editingIndex = nil } }
        )) {
            EditNameSheet(
                title: "Edit Name",
                text: $editText
            ) {
                let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard let i = editingIndex, !trimmed.isEmpty else { return }
                items[i] = trimmed
                editingIndex = nil
            }
        }
        // Full-width bottom bar like TeamGeneratorView
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar
        }
    }

    // MARK: - Subviews

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.94, blue: 0.85),
                Color(red: 1.0, green: 0.96, blue: 0.75)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        Text("Shake to Shuffle")
            .font(.system(size: 36, weight: .heavy, design: .rounded))
            .padding(.top, 8)
    }

    private var inputRow: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                TextField("Type Here …", text: $itemInput)
                    .textFieldStyle(.roundedBorder)
                    .focused($inputFocused)
                    .onSubmit(addCurrent)

                Button(action: addCurrent) {
                    Image(systemName: "plus")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .disabled(itemInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var namesGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !items.isEmpty {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                    ForEach(items.indices, id: \.self) { i in
                        Text(items[i])
                            .font(.subheadline).bold()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(white: 0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                            .onTapGesture {
                                // tap → remove
                                items.remove(at: i)
                                result = []
                            }
                            .onLongPressGesture {
                                // long-press → edit
                                editingIndex = i
                                editText = items[i]
                            }
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.green.opacity(0.5), lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.green.opacity(0.1))
                        )
                )
            }
        }
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color.black.opacity(0.15))
            .frame(height: 1)
            .padding(.vertical, 4)
    }

    private var resultCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.85))

            if result.isEmpty {
                Text("Sorted order will appear here after you press Sort.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(result.indices, id: \.self) { i in
                        HStack(alignment: .center, spacing: 12) {
                            Text("\(i + 1).")
                                .font(.headline)
                                .frame(width: 28, alignment: .trailing)

                            Text(result[i])
                                .font(.headline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color(red: 0.93, green: 0.92, blue: 1.0))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }
                .padding(18)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
    }

    // Bottom bar – matches TeamGenerator style (handle + centered Sort)
    private var bottomBar: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .frame(height: 86)
                .overlay(
                    Rectangle()
                        .fill(Color.black.opacity(0.12))
                        .frame(height: 1),
                    alignment: .top
                )
                .ignoresSafeArea()

            HStack {
                HandleButton()

                Spacer()

                Button(action: shuffleNow) {
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
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }

    // MARK: - Actions

    private func addCurrent() {
        let trimmed = itemInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(trimmed)
        itemInput = ""
        result = []
        inputFocused = true
    }

    private func shuffleNow() {
        guard !items.isEmpty else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        result = items.shuffled()
    }
}

// MARK: - Shared small views

private struct HandleButton: View {
    var body: some View {
        VStack(spacing: 6) {
            Capsule().fill(Color.gray.opacity(0.35)).frame(width: 44, height: 6)
            Capsule().fill(Color.gray.opacity(0.35)).frame(width: 32, height: 6)
        }
        .padding(8)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(radius: 2, y: 1)
    }
}

private struct EditNameSheet: View {
    let title: String
    @Binding var text: String
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(title) {
                    TextField("Name", text: $text)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RandomOrderView()
    }
}
