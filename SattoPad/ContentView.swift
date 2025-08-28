//
//  ContentView.swift
//  SattoPad
//
//  Created by keitao7gawa on 2025/08/25.
//

import SwiftUI
import AppKit
// Shared UI components and constants
import CoreGraphics
#if canImport(KeyboardShortcuts)
import KeyboardShortcuts
#endif

struct ContentView: View {
    @State private var memoText: String = ""
    @FocusState private var isEditorFocused: Bool
    @State private var escapeKeyMonitor: Any?
    @State private var overlayOpacity: Double = OverlaySettingsStore.opacity
    @State private var overlayFontSize: Double = OverlaySettingsStore.fontSize
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mdStore = MarkdownStore.shared
    @State private var showConfirmReload: Bool = false
    @State private var showConfirmChangeLocation: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var showWarningAlert: Bool = false
    @State private var warningMessage: String = ""
    @State private var showHotkeySheet: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            OverlayHeaderView(
                overlayOpacity: $overlayOpacity,
                overlayFontSize: $overlayFontSize,
                saveLocation: { requestSelectSaveLocation() },
                reloadFromDisk: { requestReload() },
                close: { closePopover() }
            )
            .padding(.horizontal, 8)
            .padding(.top, 8)

            TextEditor(text: $memoText)
                .font(.body)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(8)
                .focused($isEditorFocused)
                .onChange(of: isEditorFocused) { _, focused in
                    // When the editor gets focus, ensure overlay is adjustable
                    if focused {
                        OverlayManager.shared.setAdjustable(true)
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            isEditorFocused = true
            // When the popover opens, show overlay and allow drag to reposition
            OverlayManager.shared.setAdjustable(true)
            OverlayManager.shared.update(text: memoText)
            OverlayManager.shared.show()
            // Load memo from disk
            mdStore.loadOnLaunch()
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
            // Flush pending saves when view disappears
            mdStore.saveNow()
            // Hide overlay and disable adjustments when popover closes
            OverlayManager.shared.hide()
            OverlayManager.shared.setAdjustable(false)
        }
        .onChange(of: memoText) { _, newValue in
            OverlayManager.shared.update(text: newValue)
            mdStore.setTextAndScheduleAutosave(newValue)
        }
        .onChange(of: mdStore.text) { _, newValue in
            // Update editor with disk content when store loads
            if memoText != newValue {
                memoText = newValue
                OverlayManager.shared.update(text: newValue)
            }
        }
        .onChange(of: mdStore.lastErrorMessage) { _, newValue in
            guard let msg = newValue, !msg.isEmpty else { return }
            errorMessage = msg
            showErrorAlert = true
            mdStore.lastErrorMessage = nil
        }
        .onChange(of: mdStore.lastWarningMessage) { _, newValue in
            guard let msg = newValue, !msg.isEmpty else { return }
            warningMessage = msg
            showWarningAlert = true
            mdStore.lastWarningMessage = nil
        }
        .onChange(of: overlayOpacity) { _, newValue in
            let clamped = max(0.05, min(1.0, newValue))
            // Round to 2 decimals to stabilize float errors for 1% steps
            let rounded = (clamped * 100).rounded() / 100
            if abs(rounded - overlayOpacity) > 0.000_001 {
                overlayOpacity = rounded
            }
            OverlaySettingsStore.opacity = rounded
        }
        .onChange(of: overlayFontSize) { _, newValue in
            let clamped = max(8.0, min(36.0, newValue))
            if abs(clamped - overlayFontSize) > 0.000_001 {
                overlayFontSize = clamped
            }
            OverlaySettingsStore.fontSize = clamped
        }
        .alert("未保存の変更", isPresented: $showConfirmReload) {
            Button("破棄して再読み込み", role: .destructive) { mdStore.reloadFromDisk() }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("保存されていない変更があります。破棄して再読み込みしますか？")
        }
        .alert("未保存の変更", isPresented: $showConfirmChangeLocation) {
            Button("破棄して保存先を変更", role: .destructive) {
                // 直前に保存を明示し、未保存扱いを最小化
                mdStore.saveNow()
                mdStore.selectSaveLocation()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("保存されていない変更があります。破棄して保存先を変更しますか？")
        }
        .alert("エラー", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("警告", isPresented: $showWarningAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(warningMessage)
        }
    }

    private func closePopover() {
        // Try SwiftUI dismissal first
        dismiss()
        // Fallback: close the key window (works for MenuBarExtra window/popover)
        NSApp.keyWindow?.performClose(nil)
        // Also ensure overlay is hidden when closing via ESC or button
        OverlayManager.shared.hide()
        OverlayManager.shared.setAdjustable(false)
    }

    private func requestReload() {
        if mdStore.hasPendingChanges {
            showConfirmReload = true
        } else {
            mdStore.reloadFromDisk()
        }
    }

    private func requestSelectSaveLocation() {
        if mdStore.hasPendingChanges {
            showConfirmChangeLocation = true
        } else {
            mdStore.selectSaveLocation()
        }
    }

    private func stepFont(_ delta: Double) {
        overlayFontSize = max(8.0, min(36.0, overlayFontSize + delta))
    }
}



#Preview {
    ContentView()
}
