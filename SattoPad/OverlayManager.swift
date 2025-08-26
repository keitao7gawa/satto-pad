//
//  OverlayManager.swift
//  SattoPad
//
//  Manages a lightweight floating overlay window to preview memo content.
//

import Foundation
import AppKit
import SwiftUI

final class OverlayManager: ObservableObject {
    static let shared = OverlayManager()

    private var panel: NSPanel?
    private var hostingView: NSHostingView<OverlayPreviewView>?

    // Normalized position within the target screen (0..1 from top-left)
    private let defaults = UserDefaults.standard
    private let positionXKey = "sattoPad.overlay.positionX"
    private let positionYKey = "sattoPad.overlay.positionY"
    private let screenIdKey = "sattoPad.overlay.screenId"

    @Published var isAdjustable: Bool = false
    @Published var memoText: String = ""
    private var dragStartOrigin: CGPoint?

    private init() {}

    func update(text: String) {
        memoText = text
        hostingView?.rootView = OverlayPreviewView(text: text, adjustable: isAdjustable)
    }

    func show() {
        guard panel == nil else {
            panel?.orderFrontRegardless()
            return
        }
        let view = OverlayPreviewView(text: memoText, adjustable: isAdjustable)
        let hosting = DraggableHostingView(rootView: view)
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: OverlaySettingsStore.width, height: OverlaySettingsStore.height),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = isAdjustable
        panel.becomesKeyOnlyIfNeeded = true
        panel.ignoresMouseEvents = !isAdjustable
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        panel.contentView = hosting
        hosting.isDraggable = isAdjustable

        self.panel = panel
        self.hostingView = hosting

        positionPanelInitial(panel)

        panel.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func setAdjustable(_ adjustable: Bool) {
        isAdjustable = adjustable
        panel?.ignoresMouseEvents = !adjustable
        panel?.isMovableByWindowBackground = adjustable
        (panel?.contentView as? DraggableHostingView<OverlayPreviewView>)?.isDraggable = adjustable
        hostingView?.rootView = OverlayPreviewView(text: memoText, adjustable: adjustable)
    }

    // MARK: - Dragging
    func beginDrag() {
        dragStartOrigin = panel?.frame.origin
    }

    func drag(to translation: CGSize) {
        guard let start = dragStartOrigin, let panel else { return }
        let newOrigin = CGPoint(x: start.x + translation.width, y: start.y - translation.height)
        // Use non-animating immediate frame set to avoid jitter
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.allowsImplicitAnimation = false
        panel.setFrameOrigin(newOrigin)
        NSAnimationContext.endGrouping()
    }

    func endDrag(translation: CGSize) {
        guard let start = dragStartOrigin, let panel else { dragStartOrigin = nil; return }
        let finalOrigin = CGPoint(x: start.x + translation.width, y: start.y - translation.height)
        panel.setFrameOrigin(finalOrigin)
        savePosition(for: panel)
        dragStartOrigin = nil
    }

    // MARK: - Positioning

    private func positionPanelInitial(_ panel: NSPanel) {
        let (screen, normX, normY) = loadPosition()
        let targetScreen = screen ?? NSScreen.main
        let origin = convertNormalizedToScreenOrigin(normX: normX,
                                                     normY: normY,
                                                     size: CGSize(width: OverlaySettingsStore.width, height: OverlaySettingsStore.height),
                                                     screen: targetScreen)
        panel.setFrameOrigin(origin)
    }

    func savePosition(for panel: NSPanel) {
        guard let screen = panel.screen else { return }
        let origin = panel.frame.origin
        let normalized = convertScreenOriginToNormalized(origin: origin, size: panel.frame.size, screen: screen)
        defaults.set(normalized.x, forKey: positionXKey)
        defaults.set(normalized.y, forKey: positionYKey)
        defaults.set(screen.displayID, forKey: screenIdKey)
    }

    private func loadPosition() -> (screen: NSScreen?, normX: CGFloat, normY: CGFloat) {
        let normX = defaults.object(forKey: positionXKey) as? CGFloat ?? 0.02
        let normY = defaults.object(forKey: positionYKey) as? CGFloat ?? 0.02
        let desiredId = defaults.object(forKey: screenIdKey) as? UInt32
        let screen = NSScreen.screens.first { $0.displayID == desiredId } ?? NSScreen.main
        return (screen, normX, normY)
    }

    private func convertNormalizedToScreenOrigin(normX: CGFloat, normY: CGFloat, size: CGSize, screen: NSScreen?) -> CGPoint {
        guard let screen else { return .zero }
        let frame = screen.frame
        let x = frame.minX + (frame.width * normX)
        let yFromTop = frame.height * normY
        let y = frame.maxY - yFromTop - size.height
        return CGPoint(x: x, y: y)
    }

    private func convertScreenOriginToNormalized(origin: CGPoint, size: CGSize, screen: NSScreen) -> CGPoint {
        let frame = screen.frame
        let normX = (origin.x - frame.minX) / frame.width
        let yFromTop = frame.maxY - origin.y - size.height
        let normY = yFromTop / frame.height
        return CGPoint(x: max(0, min(1, normX)), y: max(0, min(1, normY)))
    }
}

private extension NSScreen {
    var displayID: UInt32 {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }
}
