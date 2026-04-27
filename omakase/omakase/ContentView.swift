//
//  ContentView.swift
//  omakase
//

import SwiftUI

struct ContentView: View {
    @AppStorage("omakase.hasOnboarded") private var hasOnboarded: Bool = false

    var body: some View {
        Group {
            if hasOnboarded {
                FeedView()
            } else {
                OnboardingView()
            }
        }
        .animation(.default, value: hasOnboarded)
    }
}

#Preview {
    ContentView()
}
