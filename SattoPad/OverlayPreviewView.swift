//
//  OverlayPreviewView.swift
//  SattoPad
//
//  SwiftUI preview content for the overlay window.
//  Renders markdown content using MarkdownUI with SattoPad-specific styling.
//

import SwiftUI
import Foundation
import MarkdownUI

struct OverlayPreviewView: View {
    let text: String
    let adjustable: Bool
    @AppStorage("sattoPad.overlay.opacity") private var overlayOpacity: Double = 0.95
    @AppStorage("sattoPad.overlay.fontSize") private var baseFontSize: Double = OverlaySettingsStore.fontSize

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .opacity(overlayOpacity)
                .shadow(radius: 8)

            ScrollView {
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("No content")
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Markdown(text)
                        .markdownTheme(.sattoPad(baseSize: baseFontSize))
                        .markdownSoftBreakMode(.lineBreak)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .scrollIndicators(adjustable ? .visible : .hidden)
            .scrollDisabled(!adjustable)
            .padding(.top, 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

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
}

#Preview {
    OverlayPreviewView(text: "# SattoPad\n\n- Item", adjustable: true)
}
