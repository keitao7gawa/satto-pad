//
//  ContentView.swift
//  SattoPad
//
//  Created by keitao7gawa on 2025/08/25.
//

import SwiftUI
import AppKit
#if canImport(KeyboardShortcuts)
import KeyboardShortcuts
#endif

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
                #if canImport(KeyboardShortcuts)
                KeyboardShortcuts.Recorder("Toggle SattoPad:", name: .toggleSattoPad)
                #else
                Text("Add KeyboardShortcuts package to enable recorder")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                #endif
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
                .onChange(of: isEditorFocused) { _, focused in
                    // When the editor gets focus, ensure overlay is adjustable
                    if focused {
                        OverlayManager.shared.setAdjustable(true)
                    }
                }
        }
        .onAppear {
            isEditorFocused = true
            // When the popover opens, show overlay and allow drag to reposition
            OverlayManager.shared.setAdjustable(true)
            OverlayManager.shared.update(text: memoText)
            OverlayManager.shared.show()
            escapeKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                // keyCode 53 == Escape
                if event.keyCode == 53 {
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
            // Hide overlay and disable adjustments when popover closes
            OverlayManager.shared.hide()
            OverlayManager.shared.setAdjustable(false)
        }
        .onChange(of: memoText) { _, newValue in
            OverlayManager.shared.update(text: newValue)
        }
    }

    private func closePopover() {
        // Try SwiftUI dismissal first
        dismiss()
        // Fallback: close the key window (works for MenuBarExtra window/popover)
        NSApp.keyWindow?.performClose(nil)
        // Also ensure overlay is hidden when closing via ESC
        OverlayManager.shared.hide()
        OverlayManager.shared.setAdjustable(false)
    }
}

#Preview {
    ContentView()
}
