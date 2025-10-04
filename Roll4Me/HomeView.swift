//
//  HomeView.swift
//  Roll4Me
//
//  Created by Maharsh Patel on 04/10/25.
//
import SwiftUI

struct HomeView: View {
    let tools: [(title: String, icon: String, destination: AnyView)] = [
        ("Dice Roll", "die.face.6", AnyView(DiceRollView())),
        ("Coin Flip", "dollarsign.circle", AnyView(CoinFlipView())),
        ("Spinner", "arrow.triangle.2.circlepath", AnyView(SpinnerView())),
        ("Team Generator", "person.3.fill", AnyView(TeamGeneratorView())),
        ("Random Order", "list.number", AnyView(RandomOrderView())),
        ("Random Person", "person.crop.circle.badge.questionmark", AnyView(RandomPersonView()))
    ]
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Let Fate Decide")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding([.top, .horizontal])

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(tools, id: \.title) { tool in
                        NavigationLink(destination: tool.destination) {
                            VStack {
                                Image(systemName: tool.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .padding(.bottom, 5)
                                Text(tool.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .shadow(radius: 2)
                        }
                    }
                }
                .padding()
                Spacer()
            }
            .navigationTitle("🎲 Roll4Me")
        }
    }
}

#Preview {
    HomeView()
}

