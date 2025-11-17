import SwiftUI
import WatchKit

struct RandomOrderWatchView: View {
    @State private var itemInput: String = ""
    @State private var items: [String] = []
    @State private var result: [String] = []

    var body: some View {
        ZStack {
            Color(red: 250/255, green: 240/255, blue: 200/255)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("Random Order")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .padding(.top, 4)

                // custom rounded field instead of .roundedBorder
                TextField("Type item…", text: $itemInput)
                    .font(.caption)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )

                    .onSubmit(addCurrent)

                HStack {
                    Button(action: addCurrent) {
                        Image(systemName: "plus")
                    }
                    .disabled(itemInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Spacer()

                    Button("Shuffle") { shuffle() }
                        .disabled(items.count < 2)
                }
                .font(.caption)

                List {
                    Section("Items") {
                        ForEach(items, id: \.self) { it in
                            Text(it)
                        }
                        .onDelete(perform: delete)
                    }

                    if !result.isEmpty {
                        Section("Order") {
                            ForEach(result.indices, id: \.self) { i in
                                Text("\(i+1). \(result[i])")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Random Order")
    }

    private func addCurrent() {
        let trimmed = itemInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(trimmed)
        itemInput = ""
        result = []
    }

    private func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        result = []
    }

    private func shuffle() {
        guard items.count >= 2 else { return }
        result = items.shuffled()
        WKInterfaceDevice.current().play(.success)
    }
}

#Preview {
    RandomOrderWatchView()
}
