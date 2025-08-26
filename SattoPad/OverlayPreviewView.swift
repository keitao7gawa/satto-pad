//
//  OverlayPreviewView.swift
//  SattoPad
//
//  SwiftUI preview content for the overlay window.
//

import SwiftUI
import Foundation

struct OverlayPreviewView: View {
    let text: String
    let adjustable: Bool
    @AppStorage("sattoPad.overlay.opacity") private var overlayOpacity: Double = 0.95
    @State private var dragOffset: CGSize = .zero

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
                        ForEach(parseMarkdownBlocks(text: text)) { block in
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
        .frame(width: OverlaySettingsStore.width, height: OverlaySettingsStore.height)
        .contentShape(Rectangle())
        .clipped()
    }

    // MARK: - Minimal markdown renderer (headings, bullets, code, paragraphs)
    private struct MDLine: Identifiable { let id = UUID(); let kind: Kind
        enum Kind { case heading(Int, String), bullet(String), code(String), paragraph(String) }
    }

    private func parseMarkdownBlocks(text: String) -> [MDLine] {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        var lines: [MDLine] = []
        var inCode = false
        var codeBuffer: [String] = []
        for rawLine in normalized.components(separatedBy: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("```") {
                if inCode {
                    // End code block
                    lines.append(MDLine(kind: .code(codeBuffer.joined(separator: "\n"))))
                    codeBuffer.removeAll()
                    inCode = false
                } else {
                    inCode = true
                }
                continue
            }
            if inCode {
                codeBuffer.append(rawLine)
                continue
            }
            if line.isEmpty { continue }
            if let heading = parseHeading(line) {
                lines.append(heading)
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                let content = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                lines.append(MDLine(kind: .bullet(content)))
            } else {
                lines.append(MDLine(kind: .paragraph(rawLine)))
            }
        }
        // Close dangling code block
        if inCode {
            lines.append(MDLine(kind: .code(codeBuffer.joined(separator: "\n"))))
        }
        return lines
    }

    private func parseHeading(_ line: String) -> MDLine? {
        var level = 0
        var idx = line.startIndex
        while idx < line.endIndex && line[idx] == "#" && level < 6 {
            level += 1
            idx = line.index(after: idx)
        }
        if level > 0 {
            let content = line[idx...].trimmingCharacters(in: .whitespaces)
            return MDLine(kind: .heading(level, String(content)))
        }
        return nil
    }

    @ViewBuilder
    private func blockView(_ block: MDLine) -> some View {
        switch block.kind {
        case let .heading(level, text):
            Text(text)
                .font(fontForHeading(level))
                .fontWeight(.semibold)
        case let .bullet(text):
            // Detect GitHub-style task list: [ ] label or [x] label
            let trimmed = text.trimmingCharacters(in: .whitespaces)
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
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: checked ? "checkmark.square" : "square")
                        .foregroundStyle(.secondary)
                    Text(label)
                }
                .font(.system(size: 13))
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("•")
                    Text(text)
                }
                .font(.system(size: 13))
            }
        case let .code(code):
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code.isEmpty ? "\u{00A0}" : code)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .windowBackgroundColor)))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
            }
        case let .paragraph(text):
            Text(text)
                .font(.system(size: 13))
                .lineSpacing(2)
        }
    }

    private func fontForHeading(_ level: Int) -> Font {
        switch level {
        case 1: return .system(size: 22, weight: .bold)
        case 2: return .system(size: 20, weight: .bold)
        case 3: return .system(size: 18, weight: .semibold)
        case 4: return .system(size: 16, weight: .semibold)
        default: return .system(size: 14, weight: .semibold)
        }
    }
}
