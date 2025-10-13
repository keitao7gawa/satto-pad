//
//  OverlayTypography.swift
//  SattoPad
//
//  Typography settings for overlay preview rendering.
//

import SwiftUI
import Foundation
import MarkdownUI

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

extension Theme {
    static func sattoPad(baseSize: Double) -> Theme {
        let base = CGFloat(baseSize)
        return Theme()
            .text {
                FontSize(base)
            }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(base - 1)
            }
            .heading1 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.bold)
                        FontSize(base + 9)
                    }
                    .markdownMargin(top: .em(1.2), bottom: .em(0.6))
            }
            .heading2 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.semibold)
                        FontSize(base + 7)
                    }
                    .markdownMargin(top: .em(1.1), bottom: .em(0.5))
            }
            .heading3 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.semibold)
                        FontSize(base + 5)
                    }
                    .markdownMargin(top: .em(1.0), bottom: .em(0.4))
            }
            .heading4 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.semibold)
                        FontSize(base + 3)
                    }
                    .markdownMargin(top: .em(0.9), bottom: .em(0.35))
            }
            .heading5 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.semibold)
                        FontSize(base + 1.5)
                    }
                    .markdownMargin(top: .em(0.8), bottom: .em(0.3))
            }
            .heading6 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.semibold)
                        FontSize(base + 1)
                    }
                    .markdownMargin(top: .em(0.8), bottom: .em(0.3))
            }
            .paragraph { configuration in
                configuration.label
                    .lineSpacing(OverlayTypography.lineSpacing)
                    .markdownTextStyle {
                        FontSize(base)
                    }
            }
            .list { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontSize(base)
                    }
            }
            .listItem { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontSize(base)
                    }
            }
            .codeBlock { configuration in
                ScrollView(.horizontal, showsIndicators: false) {
                    configuration.label
                        .markdownTextStyle {
                            FontFamilyVariant(.monospaced)
                            FontSize(base - 1)
                        }
                        .padding(OverlayTypography.codeBlockPadding)
                        .background(
                            RoundedRectangle(cornerRadius: OverlayTypography.codeBlockCornerRadius)
                                .fill(Color(nsColor: .textBackgroundColor))
                        )
                }
            }
            .blockquote { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontStyle(.italic)
                        FontSize(base)
                    }
                    .padding(.leading, 12)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.4))
                            .frame(width: 3)
                            .padding(.vertical, 4)
                    }
            }
    }
}
