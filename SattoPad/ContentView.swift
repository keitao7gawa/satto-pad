//
//  ContentView.swift
//  SattoPad
//
//  Created by keitao7gawa on 2025/08/25.
//

import SwiftUI

struct ContentView: View {
    @State private var memoText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SattoPad")
                .font(.headline)
                .padding(.horizontal, 8)
                .padding(.top, 8)

            TextEditor(text: $memoText)
                .font(.body)
                .frame(minWidth: 380, idealWidth: 420, maxWidth: 520,
                       minHeight: 360, idealHeight: 420, maxHeight: 560)
                .padding(8)
        }
    }
}

#Preview {
    ContentView()
}
