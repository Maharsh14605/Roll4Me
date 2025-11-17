//
//  ContentView.swift
//  Roll4MeWatch Watch App
//
//  Created by advait modh on 16/11/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Dice Roll") { DiceRollWatchView() }
                NavigationLink("Coin Flip") { CoinFlipWatchView() }
                NavigationLink("Spinner") { SpinnerWatchView() }
                NavigationLink("Random Order") { RandomOrderWatchView() }
                NavigationLink("Random Person") { RandomPersonWatchView() }
            }
            .navigationTitle("Roll4Me")
        }
    }
}

#Preview {
    ContentView()
}
