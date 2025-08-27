//
//  UIComponents.swift
//  SattoPad
//
//  Shared lightweight UI components used across views.
//

import SwiftUI
import AppKit

// MARK: - NativeSlider (NSSlider wrapper) with no tick marks
struct NativeSlider: NSViewRepresentable {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var isContinuous: Bool = true

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSSlider {
        let slider = NSSlider()
        slider.minValue = range.lowerBound
        slider.maxValue = range.upperBound
        slider.numberOfTickMarks = 0
        slider.allowsTickMarkValuesOnly = false
        slider.isContinuous = isContinuous
        slider.target = context.coordinator
        slider.action = #selector(Coordinator.valueChanged(_:))
        slider.doubleValue = value
        return slider
    }

    func updateNSView(_ nsView: NSSlider, context: Context) {
        nsView.minValue = range.lowerBound
        nsView.maxValue = range.upperBound
        nsView.isContinuous = isContinuous
        if abs(nsView.doubleValue - value) > 0.000_001 {
            nsView.doubleValue = value
        }
    }

    final class Coordinator: NSObject {
        var parent: NativeSlider
        init(_ parent: NativeSlider) { self.parent = parent }
        @objc func valueChanged(_ sender: NSSlider) {
            parent.value = sender.doubleValue
        }
    }
}

// MARK: - RepeatButton (tap + long-press repeat)
struct RepeatButton<Label: View>: View {
    let onTap: () -> Void
    let onRepeat: () -> Void
    var initialDelay: TimeInterval = 0.35
    var repeatInterval: TimeInterval = 0.08
    @State private var isPressing = false
    @State private var timer: Timer?
    let label: () -> Label

    init(onTap: @escaping () -> Void,
         onRepeat: @escaping () -> Void,
         initialDelay: TimeInterval = 0.35,
         repeatInterval: TimeInterval = 0.08,
         @ViewBuilder label: @escaping () -> Label) {
        self.onTap = onTap
        self.onRepeat = onRepeat
        self.initialDelay = initialDelay
        self.repeatInterval = repeatInterval
        self.label = label
    }

    var body: some View {
        Button(action: { onTap() }) { label() }
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressing {
                        isPressing = true
                        startRepeating()
                    }
                }
                .onEnded { _ in
                    stopRepeating()
                }
            )
    }

    private func startRepeating() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: initialDelay, repeats: false) { _ in
            onRepeat()
            timer = Timer.scheduledTimer(withTimeInterval: repeatInterval, repeats: true) { _ in
                onRepeat()
            }
        }
    }

    private func stopRepeating() {
        isPressing = false
        timer?.invalidate()
        timer = nil
    }
}
