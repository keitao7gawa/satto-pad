//
//  OverlayPreviewView.swift
//  SattoPad
//
//  SwiftUI preview content for the overlay window.
//  Uses MarkdownRenderer and OverlayTypography for consistent rendering.
//

import SwiftUI
import Foundation

struct OverlayPreviewView: View {
    let text: String
    let adjustable: Bool
    @AppStorage("sattoPad.overlay.opacity") private var overlayOpacity: Double = 0.95
    @State private var dragOffset: CGSize = .zero
    @AppStorage("sattoPad.overlay.fontSize") private var baseFontSize: Double = OverlaySettingsStore.fontSize
    @State private var scrollPosition: CGPoint = .zero
    @AppStorage("sattoPad.overlay.scrollX") private var savedScrollX: Double = 0
    @AppStorage("sattoPad.overlay.scrollY") private var savedScrollY: Double = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Make only the background translucent; keep text fully opaque
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .opacity(overlayOpacity)
                .shadow(radius: 8)
            ScrollViewReader { proxy in
                ScrollView {
                    if text.isEmpty {
                        Text("No content")
                            .foregroundStyle(.secondary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("empty-content")
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(MarkdownRenderer.parseMarkdownBlocks(text: text)) { block in
                                blockView(block)
                                    .id("block-\(block.id)")
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .scrollIndicators(adjustable ? .visible : .hidden)
                .scrollDisabled(!adjustable)
                .padding(.top, 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    // Restore saved scroll position when view appears
                    if adjustable && !text.isEmpty {
                        restoreScrollPosition(proxy: proxy)
                    }
                }
                .onChange(of: adjustable) { _, newAdjustable in
                    if newAdjustable {
                        // When entering adjustment mode, restore saved scroll position
                        restoreScrollPosition(proxy: proxy)
                    } else {
                        // When exiting adjustment mode, save current scroll position
                        saveScrollPosition()
                    }
                }
                .onChange(of: text) { _, _ in
                    // When text changes, try to maintain scroll position if in adjustment mode
                    if adjustable {
                        restoreScrollPosition(proxy: proxy)
                    }
                }
            }

            if adjustable {
                VStack {
                    HStack(spacing: 6) {
                        Image(systemName: "move.3d")
                        Text("Drag to move")
                            .font(.caption2)
                    }
                    .padding(6)
                    .background(.thinMaterial, in: Capsule())
                    .padding(8)
                    Spacer()
                }
            }
        }
        .contentShape(Rectangle())
        .clipped()
    }



    @ViewBuilder
    private func blockView(_ block: MarkdownRenderer.MDLine) -> some View {
        switch block.kind {
        case let .heading(level, elements):
            renderInlineElements(elements)
                .font(OverlayTypography.fontForHeading(level, baseSize: baseFontSize))
        case let .bullet(level, elements):
            // Detect GitHub-style task list: [ ] label or [x] label
            let textContent = elements.map { element in
                switch element.kind {
                case .text(let text): return text
                case .bold(let text): return text
                case .italic(let text): return text
                case .code(let text): return text
                }
            }.joined()
            
            let trimmed = textContent.trimmingCharacters(in: .whitespaces)
            if trimmed.count >= 3,
               let first = trimmed.first, first == "[",
               let secondIndex = trimmed.index(after: trimmed.startIndex) as String.Index?,
               secondIndex < trimmed.endIndex,
               let thirdIndex = trimmed.index(secondIndex, offsetBy: 1, limitedBy: trimmed.endIndex),
               thirdIndex < trimmed.endIndex,
               trimmed[thirdIndex] == "]",
               (trimmed[secondIndex] == " " || trimmed[secondIndex] == "x" || trimmed[secondIndex] == "X") {
                let checked = (trimmed[secondIndex] == "x" || trimmed[secondIndex] == "X")
                let labelStart = trimmed.index(thirdIndex, offsetBy: 1)
                let label = trimmed[labelStart...].trimmingCharacters(in: .whitespaces)
                HStack(alignment: .firstTextBaseline, spacing: OverlayTypography.taskListSpacing) {
                    Image(systemName: checked ? "checkmark.square" : "square")
                        .foregroundStyle(.secondary)
                    Text(label)
                }
                .font(OverlayTypography.fontForBody(baseSize: baseFontSize))
                .padding(.leading, CGFloat(level) * OverlayTypography.bulletIndent)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: OverlayTypography.bulletSpacing) {
                    Text("•")
                    renderInlineElements(elements)
                }
                .font(OverlayTypography.fontForBody(baseSize: baseFontSize))
                .padding(.leading, CGFloat(level) * OverlayTypography.bulletIndent)
            }
        case let .numbered(level, number, elements):
            HStack(alignment: .firstTextBaseline, spacing: OverlayTypography.bulletSpacing) {
                Text("\(number).")
                    .foregroundStyle(.secondary)
                renderInlineElements(elements)
            }
            .font(OverlayTypography.fontForBody(baseSize: baseFontSize))
            .padding(.leading, CGFloat(level) * OverlayTypography.bulletIndent)
        case let .code(code):
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code.isEmpty ? "\u{00A0}" : code)
                    .font(OverlayTypography.fontForCode(baseSize: baseFontSize))
                    .padding(OverlayTypography.codeBlockPadding)
                    .background(RoundedRectangle(cornerRadius: OverlayTypography.codeBlockCornerRadius).fill(Color(nsColor: .windowBackgroundColor)))
                    .overlay(RoundedRectangle(cornerRadius: OverlayTypography.codeBlockCornerRadius).stroke(Color.secondary.opacity(0.2)))
            }
        case let .paragraph(elements):
            renderInlineElements(elements)
                .font(OverlayTypography.fontForBody(baseSize: baseFontSize))
                .lineSpacing(OverlayTypography.lineSpacing)
        }
    }
    
    @ViewBuilder
    private func renderInlineElements(_ elements: [MarkdownRenderer.InlineElement]) -> some View {
        HStack(spacing: 0) {
            ForEach(elements) { element in
                renderInlineElement(element)
            }
        }
    }
    
    @ViewBuilder
    private func renderInlineElement(_ element: MarkdownRenderer.InlineElement) -> some View {
        switch element.kind {
        case .text(let text):
            Text(text)
        case .bold(let text):
            Text(text)
                .fontWeight(.bold)
        case .italic(let text):
            Text(text)
                .italic()
        case .code(let text):
            Text(text)
                .font(OverlayTypography.fontForCode(baseSize: baseFontSize))
                .padding(.horizontal, 2)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(3)
        }
    }
    
    // MARK: - Scroll Position Management
    
    private func saveScrollPosition() {
        // Save current scroll position to UserDefaults
        savedScrollX = scrollPosition.x
        savedScrollY = scrollPosition.y
    }
    
    private func restoreScrollPosition(proxy: ScrollViewProxy) {
        // Restore scroll position based on saved values
        // For simplicity, we'll scroll to a specific block if we have a saved position
        if savedScrollY > 0 && !text.isEmpty {
            let blocks = MarkdownRenderer.parseMarkdownBlocks(text: text)
            if !blocks.isEmpty {
                // Calculate which block to scroll to based on saved Y position
                let targetBlockIndex = min(Int(savedScrollY / 20), blocks.count - 1)
                let targetBlock = blocks[targetBlockIndex]
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo("block-\(targetBlock.id)", anchor: .top)
                }
            }
        }
    }


}
