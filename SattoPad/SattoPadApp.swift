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
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Hide Dock icon for menu bar–only behavior
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        // No SwiftUI scenes; status item and popover are managed in AppDelegate
        Settings { EmptyView() }
    }
}
