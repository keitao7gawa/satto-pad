//
//  ContentView.swift
//  SattoPad
//
//  Created by keitao7gawa on 2025/08/25.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var memoText: String = ""
    @FocusState private var isEditorFocused: Bool
    @State private var escapeKeyMonitor: Any?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SattoPad")
                    .font(.headline)
                Spacer()
                Button("Use F18") {
                    (NSApp.delegate as? AppDelegate)?.registerF18HotKey()
                }
                .help("Fallback if modifiers are blocked by another app")
                Button(action: { closePopover() }) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            TextEditor(text: $memoText)
                .font(.body)
                .frame(minWidth: 380, idealWidth: 420, maxWidth: 520,
                       minHeight: 360, idealHeight: 420, maxHeight: 560)
                .padding(8)
                .focused($isEditorFocused)
        }
        .onAppear {
            isEditorFocused = true
            escapeKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                // keyCode 53 == Escape
                if event.keyCode == 53 && isEditorFocused {
                    closePopover()
                    return nil // consume the key event
                }
                return event
            }
        }
        .onDisappear {
            if let monitor = escapeKeyMonitor {
                NSEvent.removeMonitor(monitor)
                escapeKeyMonitor = nil
            }
        }
    }

    private func closePopover() {
        // Try SwiftUI dismissal first
        dismiss()
        // Fallback: close the key window (works for MenuBarExtra window/popover)
        NSApp.keyWindow?.performClose(nil)
    }
}

#Preview {
    ContentView()
}
