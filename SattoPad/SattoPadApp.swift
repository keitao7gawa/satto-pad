//
//  SattoPadApp.swift
//  SattoPad
//
//  Created by keitao7gawa on 2025/08/25.
//

import SwiftUI
import AppKit

@main
struct SattoPadApp: App {
    init() {
        // Hide Dock icon for menu bar–only behavior
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra("SattoPad", systemImage: "note.text") {
            ContentView()
                .frame(width: 420, height: 520)
        }
        .menuBarExtraStyle(.window)
    }
}
