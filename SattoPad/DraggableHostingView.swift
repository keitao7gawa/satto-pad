//
//  DraggableHostingView.swift
//  SattoPad
//
//  An NSHostingView that allows dragging the window by clicking anywhere
//  when `isDraggable` is true. This uses mouseDownCanMoveWindow for smooth dragging.
//

import AppKit
import SwiftUI

final class DraggableHostingView<Content: View>: NSHostingView<Content> {
    var isDraggable: Bool = false

    override var mouseDownCanMoveWindow: Bool { isDraggable }

    override func hitTest(_ point: NSPoint) -> NSView? {
        // When adjustable, capture events at the hosting view level to allow smooth dragging
        guard isDraggable else { return super.hitTest(point) }
        return self
    }

    override func mouseDown(with event: NSEvent) {
        guard isDraggable else { return super.mouseDown(with: event) }
        // Perform native window drag for smooth movement
        window?.performDrag(with: event)
        if let panel = window as? NSPanel {
            OverlayManager.shared.savePosition(for: panel)
        }
    }
}
