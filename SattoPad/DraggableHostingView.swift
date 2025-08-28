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

    override var mouseDownCanMoveWindow: Bool { 
        guard isDraggable else { return false }
        
        // 現在のマウス位置を取得
        guard let window = window else { return false }
        let mouseLocation = window.mouseLocationOutsideOfEventStream
        
        // スクロールバー領域ではウィンドウ移動を無効化
        let scrollbarWidth: CGFloat = 15
        let rightEdge = bounds.maxX - scrollbarWidth
        let bottomEdge = bounds.minY + scrollbarWidth
        
        // 右端のスクロールバー領域
        if mouseLocation.x > rightEdge {
            return false
        }
        
        // 下端のスクロールバー領域
        if mouseLocation.y < bottomEdge {
            return false
        }
        
        // スクロールバー領域以外は全てドラッグ可能
        return true
    }

    // Allow window edge resizing by not intercepting events near the borders
    // Also prevent dragging in scrollbar areas
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard isDraggable else { return super.hitTest(point) }
        
        // スクロールバー領域（右端と下端）ではドラッグを無効化
        let scrollbarWidth: CGFloat = 15
        let rightEdge = bounds.maxX - scrollbarWidth
        let bottomEdge = bounds.minY + scrollbarWidth
        
        // 右端のスクロールバー領域
        if point.x > rightEdge {
            return super.hitTest(point)
        }
        
        // 下端のスクロールバー領域
        if point.y < bottomEdge {
            return super.hitTest(point)
        }
        
        // スクロールバー領域以外は全てドラッグ可能
        return self
    }

    override func mouseDown(with event: NSEvent) {
        guard isDraggable else { return super.mouseDown(with: event) }
        
        let point = convert(event.locationInWindow, from: nil)
        
        // スクロールバー領域ではドラッグを無効化
        let scrollbarWidth: CGFloat = 15
        let rightEdge = bounds.maxX - scrollbarWidth
        let bottomEdge = bounds.minY + scrollbarWidth
        
        // 右端のスクロールバー領域
        if point.x > rightEdge {
            return super.mouseDown(with: event)
        }
        
        // 下端のスクロールバー領域
        if point.y < bottomEdge {
            return super.mouseDown(with: event)
        }
        
        // スクロールバー領域以外は全てドラッグ可能
        window?.performDrag(with: event)
        if let panel = window as? NSPanel {
            OverlayManager.shared.savePosition(for: panel)
        }
    }
}
