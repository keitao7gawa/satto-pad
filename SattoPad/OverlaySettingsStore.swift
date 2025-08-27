//
//  OverlaySettingsStore.swift
//  SattoPad
//
//  Persists overlay size and opacity settings.
//

import Foundation

struct OverlaySettingsStore {
    private static let widthKey = "sattoPad.overlay.width"
    private static let heightKey = "sattoPad.overlay.height"
    private static let opacityKey = "sattoPad.overlay.opacity"
    private static let fontSizeKey = "sattoPad.overlay.fontSize"

    static var width: CGFloat {
        get { (UserDefaults.standard.object(forKey: widthKey) as? CGFloat) ?? 360 }
        set { UserDefaults.standard.set(newValue, forKey: widthKey) }
    }

    static var height: CGFloat {
        get { (UserDefaults.standard.object(forKey: heightKey) as? CGFloat) ?? 220 }
        set { UserDefaults.standard.set(newValue, forKey: heightKey) }
    }

    static var opacity: Double {
        get { (UserDefaults.standard.object(forKey: opacityKey) as? Double) ?? 0.95 }
        set { UserDefaults.standard.set(newValue, forKey: opacityKey) }
    }

    static var fontSize: Double {
        get { (UserDefaults.standard.object(forKey: fontSizeKey) as? Double) ?? 13.0 }
        set { UserDefaults.standard.set(newValue, forKey: fontSizeKey) }
    }
}
