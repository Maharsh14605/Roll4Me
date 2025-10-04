//
//  TeamGeneratorView.swift
//  Roll4Me
//
//  Created by Maharsh Patel on 04/10/25.
//
import SwiftUI

struct TeamGeneratorView: View {
    @State private var nameInput: String = ""
    @State private var names: [String] = []
    @State private var numberOfTeams: Int = 2
    @State private var generatedTeams: [[String]] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Enter Names:")
                        .font(.headline)

                    TextField("e.g. Alice, Bob", text: $nameInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            addNamesFromInput()
                        }

                    Button("Add Names") {
                        addNamesFromInput()
                    }

                    if !names.isEmpty {
                        Text("Names: \(names.joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Stepper("Number of Teams: \(numberOfTeams)", value: $numberOfTeams, in: 2...10)

                    Button("Generate Teams") {
                        generateTeams()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    if !generatedTeams.isEmpty {
                        ForEach(0..<generatedTeams.count, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Team \(index + 1)")
                                    .font(.headline)
                                ForEach(generatedTeams[index], id: \.self) { name in
                                    Text("• \(name)")
                                }
                            }
                            .padding(.top)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Team Generator")
        }
    }


    func addNamesFromInput() {
        let newNames = nameInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        names.append(contentsOf: newNames)
        nameInput = ""
        generatedTeams = []
    }

    func generateTeams() {
         let shuffled = names.shuffled()
        var result: [[String]] = Array(repeating: [], count: numberOfTeams)

        for (index, name) in shuffled.enumerated() {
            result[index % numberOfTeams].append(name)
        }

        generatedTeams = result
    }
}

