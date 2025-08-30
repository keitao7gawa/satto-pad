//
//  OverlayHeaderView.swift
//  SattoPad
//
//  Extracted header view for the popover. Keeps layout compact and responsive
//  without introducing a second row.
//

import SwiftUI
import AppKit
#if canImport(KeyboardShortcuts)
import KeyboardShortcuts
#endif

struct OverlayHeaderView: View {
    @Binding var overlayOpacity: Double
    @Binding var overlayFontSize: Double
    @State private var showAboutSheet: Bool = false

    var saveLocation: () -> Void
    var reloadFromDisk: () -> Void
    var close: () -> Void

    var body: some View {
        HStack(spacing: HeaderLayoutConstants.headerSpacing) {
            Spacer(minLength: 0)

            // Opacity
            VStack(spacing: 2) {
                Text("透明度 \(Int((overlayOpacity * 100).rounded()))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(width: HeaderLayoutConstants.opacitySliderWidth)
                    .multilineTextAlignment(.center)
                NativeSlider(value: $overlayOpacity, range: 0.05...1.0, isContinuous: true)
                    .frame(width: HeaderLayoutConstants.opacitySliderWidth)
            }

            // Font stepper (compact)
            HStack(spacing: HeaderLayoutConstants.headerSpacing - 2) {
                RepeatButton(onTap: { stepFont(-1) }, onRepeat: { stepFont(-1) }) {
                    Image(systemName: "textformat.size.smaller").imageScale(.small)
                }
                Text("\(Int(overlayFontSize))pt")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: HeaderLayoutConstants.fontLabelMinWidth)
                RepeatButton(onTap: { stepFont(+1) }, onRepeat: { stepFont(+1) }) {
                    Image(systemName: "textformat.size.larger").imageScale(.small)
                }
            }

            // Hotkey recorder (when available)
            #if canImport(KeyboardShortcuts)
            KeyboardShortcuts.Recorder(for: .toggleSattoPad)
            #endif

            // Trailing pair: … + ×
            HStack(spacing: HeaderLayoutConstants.trailingPairSpacing) {
                Menu {
                    Button("保存先を選択…", action: saveLocation)
                    Button("ファイルから再読み込み", action: reloadFromDisk)
                    Divider()
                    Button("About SattoPad", action: { showAboutSheet = true })
                    Divider()
                    Button("終了する", action: { NSApplication.shared.terminate(nil) })
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 12))
                        .frame(width: HeaderLayoutConstants.trailingIconSize, height: HeaderLayoutConstants.trailingIconSize)
                        .contentShape(Circle())
                }
                .menuStyle(.borderlessButton)

                Button(action: close) { Image(systemName: "xmark") }
                    .buttonStyle(.borderless)
            }
        }
        .sheet(isPresented: $showAboutSheet) {
            AboutView()
        }
    }

    private func stepFont(_ delta: Double) {
        overlayFontSize = max(8.0, min(36.0, overlayFontSize + delta))
    }
}
