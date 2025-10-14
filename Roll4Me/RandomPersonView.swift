//
//  RandomPersonView.swift
//  Roll4Me
//
//  Created by advait modh on 11/10/25.
//
import SwiftUI

struct RandomPersonView: View {
    @State private var nameInput: String = ""
    @State private var names: [String] = []
    @State private var selectedName: String?
    @State private var isSelecting = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Random Person Selector")
                    .font(.largeTitle)
                    .bold()

                TextField("Enter names separated by commas", text: $nameInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button("Add Names") {
                    addNames()
                }

                if !names.isEmpty {
                    List {
                        ForEach(names, id: \.self) { name in
                            Text(name)
                        }
                        .onDelete(perform: delete)
                    }
                    .frame(height: 200)
                }

                Button("🎯 Pick Random Person") {
                    pickRandomPerson()
                }
                .disabled(names.count < 2)
                .padding()
                .background(names.count < 2 ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)

                if let name = selectedName {
                    Text("🎉 Selected: \(name)")
                        .font(.title)
                        .padding(.top, 20)
                }

                Spacer()
            }
            .padding()
        }
    }

    func addNames() {
        let inputNames = nameInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        names.append(contentsOf: inputNames)
        nameInput = ""
    }

    func delete(at offsets: IndexSet) {
        names.remove(atOffsets: offsets)
    }

    func pickRandomPerson() {
        guard !names.isEmpty else { return }
        isSelecting = true
        selectedName = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            selectedName = names.randomElement()
            isSelecting = false
        }
    }
}

