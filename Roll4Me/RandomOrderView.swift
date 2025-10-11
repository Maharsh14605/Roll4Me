//
//  RandomOrderView.swift
//  Roll4Me
//
//  Created by Maharsh Patel on 04/10/25.
//
import SwiftUI

struct RandomOrderView: View {
    @State private var itemInput: String = ""
    @State private var originalItems: [String] = []
    @State private var randomizedItems: [String] = []

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Enter items (comma-separated):")
                    .font(.headline)

                TextField("e.g. Apple, Banana, Mango", text: $itemInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        addItems()
                    }

                Button("Add Items") {
                    addItems()
                }

                if !originalItems.isEmpty {
                    Text("Original List:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(originalItems.joined(separator: ", "))
                        .padding(.bottom)

                    Button("Shuffle List") {
                        randomizedItems = originalItems.shuffled()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                if !randomizedItems.isEmpty {
                    Text("Randomized Order:")
                        .font(.headline)
                        .padding(.top)

                    ForEach(randomizedItems.indices, id: \.self) { index in
                        Text("\(index + 1). \(randomizedItems[index])")
                            .padding(.vertical, 2)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Random Order")
        }
    }

    func addItems() {
        let newItems = itemInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        originalItems = newItems
        randomizedItems = []
        itemInput = ""
    }
}

