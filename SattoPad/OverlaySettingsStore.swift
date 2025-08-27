//
//  OverlaySettingsStore.swift
//  SattoPad
//
//  Persists overlay size and opacity settings with improved key management.
//

import Foundation

struct OverlaySettingsStore {
    // MARK: - UserDefaults Keys (namespaced)
    private enum Keys {
        static let width = "sattoPad.overlay.width"
        static let height = "sattoPad.overlay.height"
        static let opacity = "sattoPad.overlay.opacity"
        static let fontSize = "sattoPad.overlay.fontSize"
    }
    
    // MARK: - Default Values
    private enum Defaults {
        static let width: CGFloat = 360
        static let height: CGFloat = 220
        static let opacity: Double = 0.95
        static let fontSize: Double = 13.0
    }
    
    // MARK: - Properties with Property Wrapper
    @UserDefaultsProperty(key: Keys.width, defaultValue: Defaults.width)
    static var width: CGFloat
    
    @UserDefaultsProperty(key: Keys.height, defaultValue: Defaults.height)
    static var height: CGFloat
    
    @UserDefaultsProperty(key: Keys.opacity, defaultValue: Defaults.opacity)
    static var opacity: Double
    
    @UserDefaultsProperty(key: Keys.fontSize, defaultValue: Defaults.fontSize)
    static var fontSize: Double
}
