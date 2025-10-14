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
    private let draggableHeaderHeight: CGFloat = 56
    private let scrollbarWidth: CGFloat = 15

    override var mouseDownCanMoveWindow: Bool { 
        guard isDraggable else { return false }
        guard let window = window else { return false }
        let mouseLocation = window.mouseLocationOutsideOfEventStream
        let point = convert(mouseLocation, from: nil)
        return isPointInDraggableRegion(point)
    }

    // Allow window edge resizing by not intercepting events near the borders
    // Also prevent dragging in scrollbar areas
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard isDraggable else { return super.hitTest(point) }
        if point.x > bounds.maxX - scrollbarWidth || point.y < bounds.minY + scrollbarWidth {
            return super.hitTest(point)
        }
        return isPointInDraggableRegion(point) ? self : super.hitTest(point)
    }

    override func mouseDown(with event: NSEvent) {
        guard isDraggable else { return super.mouseDown(with: event) }
        
        let point = convert(event.locationInWindow, from: nil)
        if point.x > bounds.maxX - scrollbarWidth || point.y < bounds.minY + scrollbarWidth {
            return super.mouseDown(with: event)
        }

        guard isPointInDraggableRegion(point) else {
            return super.mouseDown(with: event)
        }

        window?.performDrag(with: event)
        if let panel = window as? NSPanel {
            OverlayManager.shared.savePosition(for: panel)
        }
    }

    private func isPointInDraggableRegion(_ point: NSPoint) -> Bool {
        let withinHeader = point.y >= bounds.maxY - draggableHeaderHeight
        let withinHorizontalBounds = point.x <= bounds.maxX - scrollbarWidth
        return withinHeader && withinHorizontalBounds
    }
}
