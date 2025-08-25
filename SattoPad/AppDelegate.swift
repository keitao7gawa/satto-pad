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

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyEventHandlerRef: EventHandlerRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "SattoPad")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        // Popover content
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 420, height: 520)
        popover.contentViewController = NSHostingController(rootView: ContentView())

        // Register global hotkey (default)
        registerDefaultHotKey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        unregisterGlobalHotKey()
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
    }

    private func closePopover(_ sender: Any?) {
        popover.performClose(sender)
    }
}

// MARK: - Global Hot Key (Cmd + Option + Control + T)
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
