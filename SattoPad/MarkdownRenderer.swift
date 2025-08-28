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
            case heading(Int, [InlineElement])
            case bullet(Int, [InlineElement]) // level, text elements
            case numbered(Int, Int, [InlineElement]) // level, number, text elements
            case code(String)
            case paragraph([InlineElement])
        }
    }
    
    // MARK: - Inline Elements
    struct InlineElement: Identifiable {
        let id = UUID()
        let kind: InlineKind
        
        enum InlineKind {
            case text(String)
            case bold(String)
            case italic(String)
            case code(String)
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
            } else if let numberedList = parseNumberedList(line, rawLine: rawLine) {
                lines.append(numberedList)
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                let level = leadingIndentLevel(for: rawLine)
                let content = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                let elements = parseInlineElements(content)
                lines.append(MDLine(kind: .bullet(level, elements)))
            } else {
                let elements = parseInlineElements(rawLine)
                lines.append(MDLine(kind: .paragraph(elements)))
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
            let elements = parseInlineElements(String(content))
            return MDLine(kind: .heading(level, elements))
        }
        
        return nil
    }
    
    private static func parseNumberedList(_ line: String, rawLine: String) -> MDLine? {
        // Match patterns like "1. ", "2. ", "10. ", etc.
        let pattern = "^\\s*(\\d+)\\.\\s+(.+)$"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: line.utf16.count)
        
        if let match = regex?.firstMatch(in: line, options: [], range: range) {
            let numberRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            
            let numberString = (line as NSString).substring(with: numberRange)
            let content = (line as NSString).substring(with: contentRange)
            
            if let number = Int(numberString) {
                let level = leadingIndentLevel(for: rawLine)
                let elements = parseInlineElements(content)
                return MDLine(kind: .numbered(level, number, elements))
            }
        }
        
        return nil
    }
    
    // MARK: - Inline Parsing
    static func parseInlineElements(_ text: String) -> [InlineElement] {
        var elements: [InlineElement] = []
        var remainingText = text
        
        // Process in order: bold, italic, code
        while !remainingText.isEmpty {
            var found = false
            
            // Check for bold (**text**)
            if let (content, startIndex, endIndex) = findBold(remainingText) {
                // Add text before bold
                if startIndex > remainingText.startIndex {
                    let beforeText = String(remainingText[remainingText.startIndex..<startIndex])
                    if !beforeText.isEmpty {
                        elements.append(InlineElement(kind: .text(beforeText)))
                    }
                }
                
                // Add bold content
                elements.append(InlineElement(kind: .bold(content)))
                
                // Update remaining text
                remainingText = String(remainingText[endIndex...])
                found = true
            }
            // Check for italic (*text*)
            else if let (content, startIndex, endIndex) = findItalic(remainingText) {
                // Add text before italic
                if startIndex > remainingText.startIndex {
                    let beforeText = String(remainingText[remainingText.startIndex..<startIndex])
                    if !beforeText.isEmpty {
                        elements.append(InlineElement(kind: .text(beforeText)))
                    }
                }
                
                // Add italic content
                elements.append(InlineElement(kind: .italic(content)))
                
                // Update remaining text
                remainingText = String(remainingText[endIndex...])
                found = true
            }
            // Check for inline code (`text`)
            else if let (content, startIndex, endIndex) = findInlineCode(remainingText) {
                // Add text before code
                if startIndex > remainingText.startIndex {
                    let beforeText = String(remainingText[remainingText.startIndex..<startIndex])
                    if !beforeText.isEmpty {
                        elements.append(InlineElement(kind: .text(beforeText)))
                    }
                }
                
                // Add code content
                elements.append(InlineElement(kind: .code(content)))
                
                // Update remaining text
                remainingText = String(remainingText[endIndex...])
                found = true
            }
            
            if !found {
                // No special formatting found, add remaining text
                elements.append(InlineElement(kind: .text(remainingText)))
                break
            }
        }
        
        return elements.isEmpty ? [InlineElement(kind: .text(text))] : elements
    }
    
    private static func findBold(_ text: String) -> (content: String, startIndex: String.Index, endIndex: String.Index)? {
        if let start = text.range(of: "**") {
            let contentStart = start.upperBound
            if let end = text.range(of: "**", range: contentStart..<text.endIndex) {
                let content = String(text[contentStart..<end.lowerBound])
                if !content.isEmpty {
                    return (content, start.lowerBound, end.upperBound)
                }
            }
        }
        return nil
    }
    
    private static func findItalic(_ text: String) -> (content: String, startIndex: String.Index, endIndex: String.Index)? {
        if let start = text.range(of: "*") {
            let contentStart = start.upperBound
            
            // Skip if this is part of bold (**)
            if contentStart < text.endIndex && text[contentStart] == "*" {
                return nil
            }
            
            if let end = text.range(of: "*", range: contentStart..<text.endIndex) {
                let content = String(text[contentStart..<end.lowerBound])
                if !content.isEmpty {
                    return (content, start.lowerBound, end.upperBound)
                }
            }
        }
        return nil
    }
    
    private static func findInlineCode(_ text: String) -> (content: String, startIndex: String.Index, endIndex: String.Index)? {
        if let start = text.range(of: "`") {
            let contentStart = start.upperBound
            if let end = text.range(of: "`", range: contentStart..<text.endIndex) {
                let content = String(text[contentStart..<end.lowerBound])
                if !content.isEmpty {
                    return (content, start.lowerBound, end.upperBound)
                }
            }
        }
        return nil
    }
}