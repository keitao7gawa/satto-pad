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

    // Allow window edge resizing by not intercepting events near the borders
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard isDraggable else { return super.hitTest(point) }
        let edgeMargin: CGFloat = 8
        let innerRect = bounds.insetBy(dx: edgeMargin, dy: edgeMargin)
        if innerRect.contains(point) {
            return self
        } else {
            return super.hitTest(point)
        }
    }

    override func mouseDown(with event: NSEvent) {
        guard isDraggable else { return super.mouseDown(with: event) }
        window?.performDrag(with: event)
        if let panel = window as? NSPanel {
            OverlayManager.shared.savePosition(for: panel)
        }
    }
}
