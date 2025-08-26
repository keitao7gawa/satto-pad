//
//  KeyboardShortcutsSupport.swift
//  SattoPad
//
//  KeyboardShortcuts integration helpers.
//

import Foundation
#if canImport(KeyboardShortcuts)
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleSattoPad = Self("toggleSattoPad")
}

struct KeyboardShortcutsDefaults {
    static func ensureDefaultIfNeeded() {
        #if DEBUG
        if KeyboardShortcuts.getShortcut(for: .toggleSattoPad) == nil {
            KeyboardShortcuts.setShortcut(.init(.t, modifiers: [.command, .shift]), for: .toggleSattoPad)
        }
        #endif
    }
}
#endif
