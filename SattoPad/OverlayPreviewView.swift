//
//  OverlayPreviewView.swift
//  SattoPad
//
//  SwiftUI preview content for the overlay window.
//

import SwiftUI

struct OverlayPreviewView: View {
    let text: String
    let adjustable: Bool
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .shadow(radius: 8)
            ScrollView {
                Text(text.isEmpty ? "No content" : text)
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .textSelection(.disabled)
                    .padding(12)
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
        .frame(width: 360, height: 220)
        .contentShape(Rectangle())
        .highPriorityGesture(adjustable ? dragGesture : nil)
        .clipped()
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                if dragOffset == .zero { OverlayManager.shared.beginDrag() }
                dragOffset = value.translation
                OverlayManager.shared.drag(to: value.translation)
            }
            .onEnded { value in
                OverlayManager.shared.endDrag(translation: value.translation)
                dragOffset = .zero
            }
    }
}
