//
//  OverlayTypography.swift
//  SattoPad
//
//  Typography settings for overlay preview rendering.
//

import SwiftUI
import Foundation

struct OverlayTypography {
    // MARK: - Font Configuration
    static let baseFontSize: Double = 13.0
    static let codeFontSize: Double = 12.0
    static let lineSpacing: Double = 2.0
    
    // MARK: - Heading Font Sizes (relative to base)
    static let headingSizeOffsets: [Int: Double] = [
        1: 9.0,  // H1: base + 9
        2: 7.0,  // H2: base + 7
        3: 5.0,  // H3: base + 5
        4: 3.0,  // H4: base + 3
        5: 1.0,  // H5: base + 1
        6: 1.0   // H6: base + 1
    ]
    
    // MARK: - Font Weights
    static let headingWeights: [Int: Font.Weight] = [
        1: .bold,
        2: .bold,
        3: .semibold,
        4: .semibold,
        5: .semibold,
        6: .semibold
    ]
    
    // MARK: - Layout Constants
    static let bulletIndent: CGFloat = 14.0
    static let bulletSpacing: CGFloat = 6.0
    static let taskListSpacing: CGFloat = 8.0
    static let codeBlockPadding: CGFloat = 8.0
    static let codeBlockCornerRadius: CGFloat = 6.0
    
    // MARK: - Font Generation
    static func fontForHeading(_ level: Int, baseSize: Double) -> Font {
        let offset = headingSizeOffsets[level] ?? 1.0
        let weight = headingWeights[level] ?? .semibold
        return .system(size: CGFloat(baseSize + offset), weight: weight)
    }
    
    static func fontForBody(baseSize: Double) -> Font {
        return .system(size: CGFloat(baseSize))
    }
    
    static func fontForCode(baseSize: Double) -> Font {
        return .system(size: CGFloat(baseSize), design: .monospaced)
    }
}