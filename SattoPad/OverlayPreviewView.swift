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

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Make only the background translucent; keep text fully opaque
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .opacity(overlayOpacity)
                .shadow(radius: 8)
            ScrollView {
                if text.isEmpty {
                    Text("No content")
                        .foregroundStyle(.secondary)
                        .padding(12)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(MarkdownRenderer.parseMarkdownBlocks(text: text)) { block in
                            blockView(block)
                        }
                    }
                    .padding(12)
                }
            }
            .padding(.top, 0)

            if adjustable {
                HStack(spacing: 6) {
                    Image(systemName: "move.3d")
                    Text("Drag to move")
                        .font(.caption2)
                }
                .padding(6)
                .background(.thinMaterial, in: Capsule())
                .padding(8)
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


}
