//
//  OverlayManager.swift
//  SattoPad
//
//  Manages a lightweight floating overlay window to preview memo content.
//  Refactored for improved readability and maintainability with separated concerns.
//

import Foundation
import AppKit
import SwiftUI

final class OverlayManager: NSObject, ObservableObject {
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
    
    // Scroll position management
    private let scrollXKey = "sattoPad.overlay.scrollX"
    private let scrollYKey = "sattoPad.overlay.scrollY"

    private override init() {}

    func update(text: String) {
        memoText = text
        hostingView?.rootView = OverlayPreviewView(text: text, adjustable: isAdjustable)
    }

    func show() {
        guard panel == nil else {
            panel?.orderFrontRegardless()
            return
        }
        
        let panel = createOverlayPanel()
        let hosting = createHostingView()
        
        configurePanel(panel, with: hosting)
        positionPanelInitial(panel)
        
        self.panel = panel
        self.hostingView = hosting
        
        panel.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func setAdjustable(_ adjustable: Bool) {
        isAdjustable = adjustable
        updateAdjustmentMode()
        
        // Save scroll position when exiting adjustment mode
        if !adjustable {
            saveScrollPosition()
        }
    }
    
    private func updateAdjustmentMode() {
        guard let panel = panel else { return }
        
        // Update panel behavior
        panel.ignoresMouseEvents = !isAdjustable
        panel.isMovableByWindowBackground = isAdjustable
        
        // Update style mask for resizable behavior
        var mask = panel.styleMask
        if isAdjustable {
            mask.insert(.resizable)
        } else {
            mask.remove(.resizable)
        }
        panel.styleMask = mask
        
        // Update hosting view
        if let hosting = panel.contentView as? DraggableHostingView<OverlayPreviewView> {
            hosting.isDraggable = isAdjustable
        }
        
        // Update root view to reflect adjustable state
        hostingView?.rootView = OverlayPreviewView(text: memoText, adjustable: isAdjustable)
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

    // MARK: - Window Creation and Configuration
    
    private func createOverlayPanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: OverlaySettingsStore.width, height: OverlaySettingsStore.height),
            styleMask: [.titled, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )
        return panel
    }
    
    private func createHostingView() -> DraggableHostingView<OverlayPreviewView> {
        let view = OverlayPreviewView(text: memoText, adjustable: isAdjustable)
        return DraggableHostingView(rootView: view)
    }
    
    private func configurePanel(_ panel: NSPanel, with hosting: DraggableHostingView<OverlayPreviewView>) {
        // Basic panel properties
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        panel.minSize = NSSize(width: 200, height: 120)
        
        // Hide standard window buttons
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        
        // Set content view and delegate
        panel.contentView = hosting
        panel.delegate = self
        
        // Configure adjustable behavior
        configureAdjustableBehavior(panel, hosting: hosting)
    }
    
    private func configureAdjustableBehavior(_ panel: NSPanel, hosting: DraggableHostingView<OverlayPreviewView>) {
        panel.isMovableByWindowBackground = isAdjustable
        panel.ignoresMouseEvents = !isAdjustable
        hosting.isDraggable = isAdjustable
        
        // Configure resizable behavior
        var mask = panel.styleMask
        if isAdjustable {
            mask.insert(.resizable)
        } else {
            mask.remove(.resizable)
        }
        panel.styleMask = mask
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
    
    // MARK: - Scroll Position Management
    
    func saveScrollPosition() {
        // This will be called by the OverlayPreviewView when scroll position changes
        // The actual scroll position is managed by the view itself via @AppStorage
    }
    
    func getScrollPosition() -> CGPoint {
        let x = defaults.object(forKey: scrollXKey) as? Double ?? 0
        let y = defaults.object(forKey: scrollYKey) as? Double ?? 0
        return CGPoint(x: x, y: y)
    }
}

// MARK: - NSWindowDelegate (persist overlay size when user resizes the panel)
extension OverlayManager: NSWindowDelegate {
    func windowDidEndLiveResize(_ notification: Notification) {
        guard let panel = notification.object as? NSPanel else { return }
        persistOverlaySize(from: panel)
    }

    func windowDidResize(_ notification: Notification) {
        // Live update during resize for immediate visual feedback
        // Size persistence is handled in windowDidEndLiveResize
        guard let panel = notification.object as? NSPanel else { return }
        updateOverlaySize(from: panel)
    }
    
    private func persistOverlaySize(from panel: NSPanel) {
        let newSize = panel.contentLayoutRect.size
        OverlaySettingsStore.width = newSize.width
        OverlaySettingsStore.height = newSize.height
        // Re-render rootView to ensure SwiftUI frame reflects latest store values
        hostingView?.rootView = OverlayPreviewView(text: memoText, adjustable: isAdjustable)
    }
    
    private func updateOverlaySize(from panel: NSPanel) {
        let newSize = panel.contentLayoutRect.size
        OverlaySettingsStore.width = newSize.width
        OverlaySettingsStore.height = newSize.height
    }
}

private extension NSScreen {
    var displayID: UInt32 {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }
}
