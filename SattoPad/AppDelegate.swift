//
//  AppDelegate.swift
//  SattoPad
//
//  Created by SattoPad Assistant on 2025/08/25.
//

import Foundation
import SwiftUI
import AppKit
import Carbon.HIToolbox
#if canImport(KeyboardShortcuts)
import KeyboardShortcuts
#endif

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyEventHandlerRef: EventHandlerRef?

    // MARK: - Menu bar icon state
    private enum StatusIconState {
        case idle      // 未使用
        case active    // 使用中（プレビュー表示）
        case adjusting // 調整中（ポップオーバー表示）
    }
    private var statusButton: NSStatusBarButton? { statusItem?.button }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "SattoPad")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        // 初期状態は未使用
        updateStatusIcon(.idle)

        // Popover content
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 420, height: 520)
        popover.contentViewController = NSHostingController(rootView: ContentView())
        popover.delegate = self

        // Register global hotkey (KeyboardShortcuts preferred)
        #if canImport(KeyboardShortcuts)
        KeyboardShortcutsDefaults.ensureDefaultIfNeeded()
        KeyboardShortcuts.onKeyDown(for: .toggleSattoPad) {
            OverlayManager.shared.show()
            if !(self.popover.isShown) {
                self.updateStatusIcon(.active)
            }
        }
        KeyboardShortcuts.onKeyUp(for: .toggleSattoPad) {
            OverlayManager.shared.hide()
            self.updateStatusIcon(self.popover.isShown ? .adjusting : .idle)
        }
        #else
        registerDefaultHotKey()
        #endif
    }

    func applicationWillTerminate(_ notification: Notification) {
        #if !canImport(KeyboardShortcuts)
        unregisterGlobalHotKey()
        #endif
    }

    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }

    private func showPopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        // Bring app forward enough to receive key events inside the popover
        NSApp.activate(ignoringOtherApps: true)
        // Enable overlay adjustment while popover is visible
        OverlayManager.shared.setAdjustable(true)
        OverlayManager.shared.show()
        // ポップオーバー表示中は調整中
        updateStatusIcon(.adjusting)
    }

    private func closePopover(_ sender: Any?) {
        popover.performClose(sender)
        // Ensure overlay is hidden when popover closes
        OverlayManager.shared.hide()
        OverlayManager.shared.setAdjustable(false)
        // ポップオーバー終了 → 未使用へ
        updateStatusIcon(.idle)
    }

    // MARK: - NSPopoverDelegate
    func popoverWillShow(_ notification: Notification) {
        OverlayManager.shared.setAdjustable(true)
        OverlayManager.shared.show()
        updateStatusIcon(.adjusting)
    }

    func popoverWillClose(_ notification: Notification) {
        OverlayManager.shared.hide()
        OverlayManager.shared.setAdjustable(false)
        updateStatusIcon(.idle)
    }
}

private extension AppDelegate {
    private func updateStatusIcon(_ state: StatusIconState) {
        guard let button = statusButton else { return }
        switch state {
        case .idle:
            let img = NSImage(systemSymbolName: "note.text", accessibilityDescription: "SattoPad")
            img?.isTemplate = true // メニューバー色に追従（グレースケール）
            button.image = img
        case .active:
            button.title = ""
            button.image = makeEmojiStatusImage("👀")
        case .adjusting:
            button.title = ""
            button.image = makeEmojiStatusImage("✏️")
        }
        button.imagePosition = .imageOnly
    }

    // 絵文字をカラーのままNSImageとして描画（メニューバーの推奨サイズに合わせる）
    private func makeEmojiStatusImage(_ emoji: String) -> NSImage? {
        // 18〜20pt 程度が一般的。Retina を考慮してスケール2xで描画
        let pointSize: CGFloat = 18
        let _: CGFloat = NSScreen.main?.backingScaleFactor ?? 2.0
        let image = NSImage(size: CGSize(width: pointSize, height: pointSize))
        image.lockFocusFlipped(false)
        defer { image.unlockFocus() }

        // センターに描画されるように計測
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: pointSize)
        ]
        let attributed = NSAttributedString(string: emoji, attributes: attributes)
        let textSize = attributed.size()
        let drawRect = CGRect(
            x: (pointSize - textSize.width) / 2.0,
            y: (pointSize - textSize.height) / 2.0,
            width: textSize.width,
            height: textSize.height
        )
        attributed.draw(in: drawRect)

        // 色付きで表示したいのでテンプレートにはしない
        image.isTemplate = false
        return image
    }
}

#if !canImport(KeyboardShortcuts)
// MARK: - Global Hot Key (Carbon fallback)
// Global hotkey C-callback
private func SattoPadHotKeyHandler(_ nextHandler: EventHandlerCallRef?, _ eventRef: EventRef?, _ userData: UnsafeMutableRawPointer?) -> OSStatus {
    var hotKeyID = EventHotKeyID()
    GetEventParameter(eventRef, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout.size(ofValue: hotKeyID), nil, &hotKeyID)
    if hotKeyID.id == 1 {
        if let userData {
            let delegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async {
                delegate.togglePopover(nil)
            }
        }
    }
    return noErr
}

extension AppDelegate {
    private func unregisterIfNeeded() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let handler = hotKeyEventHandlerRef {
            RemoveEventHandler(handler)
            hotKeyEventHandlerRef = nil
        }
    }

    private func registerGlobalHotKey(modifiers: UInt32, keyCode: UInt32) {
        unregisterIfNeeded()
        let hotKeyID = EventHotKeyID(signature: OSType(bitPattern: Int32(UInt32(truncatingIfNeeded: 0x53505444))), // 'SPTD'
                                     id: 1)
        // Register to the Event Dispatcher for broader delivery across apps
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &hotKeyRef)
        #if DEBUG
        if status == noErr {
            print("[SattoPad] Global hotkey registered: keyCode=\(keyCode) modifiers=\(modifiers)")
        } else {
            print("[SattoPad] RegisterEventHotKey failed: \(status)")
        }
        #endif

        // Install event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let installStatus = InstallEventHandler(GetEventDispatcherTarget(), SattoPadHotKeyHandler, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &hotKeyEventHandlerRef)

        #if DEBUG
        if installStatus == noErr {
            print("[SattoPad] Hotkey event handler installed")
        } else {
            print("[SattoPad] InstallEventHandler failed: \(installStatus)")
        }
        #endif
    }

    // Default: Cmd + Shift + T（M2 既定）
    func registerDefaultHotKey() {
        registerGlobalHotKey(modifiers: UInt32(cmdKey | shiftKey), keyCode: UInt32(kVK_ANSI_T))
    }

    // Testing: F18 with no modifiers (often unused with external keyboard)
    func registerF18HotKey() {
        #if canImport(Carbon)
        registerGlobalHotKey(modifiers: 0, keyCode: UInt32(kVK_F18))
        #endif
    }

    func registerCtrlOptCmdP() {
        registerGlobalHotKey(modifiers: UInt32(controlKey | optionKey | cmdKey), keyCode: UInt32(kVK_ANSI_P))
    }

    func registerCtrlOptCmdY() {
        registerGlobalHotKey(modifiers: UInt32(controlKey | optionKey | cmdKey), keyCode: UInt32(kVK_ANSI_Y))
    }

    // Public API to update hotkey from UI
    func setGlobalHotKey(modifiers: UInt32, keyCode: UInt32) {
        registerGlobalHotKey(modifiers: modifiers, keyCode: keyCode)
    }

    private func unregisterGlobalHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let handler = hotKeyEventHandlerRef {
            RemoveEventHandler(handler)
            hotKeyEventHandlerRef = nil
        }
    }
}
#endif
