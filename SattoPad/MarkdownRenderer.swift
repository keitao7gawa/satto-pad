//
//  MarkdownRenderer.swift
//  SattoPad
//
//  Extracted markdown rendering logic for overlay preview.
//

import SwiftUI
import Foundation

struct MarkdownRenderer {
    // MARK: - Markdown Line Types
    struct MDLine: Identifiable {
        let id = UUID()
        let kind: Kind
        
        enum Kind {
            case heading(Int, String)
            case bullet(Int, String) // level, text
            case code(String)
            case paragraph(String)
        }
    }
    
    // MARK: - Parsing
    static func parseMarkdownBlocks(text: String) -> [MDLine] {
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
                let level = leadingIndentLevel(for: rawLine)
                let content = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                lines.append(MDLine(kind: .bullet(level, content)))
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
    
    // MARK: - Helper Functions
    private static func leadingIndentLevel(for rawLine: String) -> Int {
        var spaces = 0
        for ch in rawLine {
            if ch == " " { spaces += 1 }
            else if ch == "\t" { spaces += 4 }
            else { break }
        }
        return max(0, min(8, spaces / 2))
    }
    
    private static func parseHeading(_ line: String) -> MDLine? {
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
}