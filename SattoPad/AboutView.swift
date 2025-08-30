//
//  AboutView.swift
//  SattoPad
//
//  About information and license details for SattoPad
//

import SwiftUI
import AppKit

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showLicenseSheet: Bool = false
    @State private var escapeKeyMonitor: Any?
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed Header with App Icon and Name
            VStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
                
                VStack(spacing: 4) {
                    Text("SattoPad")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 32)
            .padding(.bottom, 20)
            
            // Scrollable Content
            ScrollView {
                VStack(spacing: 20) {
                    // Description
                    Text("⚡ memo app specialized for quick viewing (satto)")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    
                    // System Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("System Information")
                            .font(.headline)
                        
                        InfoRow(label: "macOS Version", value: macOSVersion)
                        InfoRow(label: "App Sandbox", value: isSandboxed ? "Enabled" : "Disabled")
                        InfoRow(label: "Accessibility", value: accessibilityStatus)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Third-party Libraries
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Third-party Libraries")
                            .font(.headline)
                        
                        LibraryInfo(name: "KeyboardShortcuts", version: "2.3.0+", license: "MIT", showLicense: { showLicenseSheet = true })
                        LibraryInfo(name: "SwiftUI", version: "Built-in", license: "Apple")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                                // Author Information
            VStack(alignment: .leading, spacing: 8) {
                Text("Author")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Developer:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("@keitao7gawa") {
                            openTwitterProfile()
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .buttonStyle(.link)
                    }
                    
                    HStack {
                        Text("Repository:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("GitHub") {
                            openGitHubRepository()
                        }
                        .font(.caption)
                        .buttonStyle(.link)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Credits
            VStack(alignment: .leading, spacing: 8) {
                Text("Credits")
                    .font(.headline)
                
                Text("Developed with ❤️ for productivity")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("Built with SwiftUI and native macOS technologies")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Additional Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional Information")
                            .font(.headline)
                        
                        InfoRow(label: "Bundle ID", value: bundleIdentifier)
                        InfoRow(label: "Build Date", value: buildDate)
                        InfoRow(label: "Architecture", value: architecture)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            
            // Fixed Footer with Close Button
            VStack {
                Divider()
                Button("Close") {
                    closeAboutOnly()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .frame(width: 400, height: 600)
        .onAppear {
            setupEscapeKeyMonitor()
        }
        .onDisappear {
            removeEscapeKeyMonitor()
        }
        .sheet(isPresented: $showLicenseSheet) {
            LicenseView()
        }
    }
    
    // MARK: - Computed Properties
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    private var macOSVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
    
    private var isSandboxed: Bool {
        Bundle.main.object(forInfoDictionaryKey: "com.apple.security.app-sandbox") as? Bool ?? false
    }
    
    private var accessibilityStatus: String {
        // Check if accessibility permissions are granted
        let trusted = AXIsProcessTrusted()
        return trusted ? "Granted" : "Not Required"
    }
    
    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }
    
    private var buildDate: String {
        guard let buildDateString = Bundle.main.infoDictionary?["CFBundleBuildDate"] as? String else {
            // Fallback to file modification date
            if let executablePath = Bundle.main.executablePath,
               let attributes = try? FileManager.default.attributesOfItem(atPath: executablePath),
               let modificationDate = attributes[.modificationDate] as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                return formatter.string(from: modificationDate)
            }
            return "Unknown"
        }
        return buildDateString
    }
    
    private var architecture: String {
        #if arch(arm64)
        return "Apple Silicon (ARM64)"
        #elseif arch(x86_64)
        return "Intel (x86_64)"
        #else
        return "Unknown"
        #endif
    }
    
    private func openGitHubRepository() {
        guard let url = URL(string: "https://github.com/keitao7gawa/satto-pad") else { return }
        NSWorkspace.shared.open(url)
    }
    
    private func openTwitterProfile() {
        guard let url = URL(string: "https://twitter.com/keitao7gawa") else { return }
        NSWorkspace.shared.open(url)
    }
    
    // MARK: - Escape Key Handling
    
    private func setupEscapeKeyMonitor() {
        escapeKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // keyCode 53 == Escape
            if event.keyCode == 53 {
                DispatchQueue.main.async {
                    self.closeAboutAndPopover()
                }
                return nil // consume the key event
            }
            return event
        }
    }
    
    private func removeEscapeKeyMonitor() {
        if let monitor = escapeKeyMonitor {
            NSEvent.removeMonitor(monitor)
            escapeKeyMonitor = nil
        }
    }
    
    private func closeAboutOnly() {
        // Close only the About view (V_about) - Close button behavior
        dismiss()
    }
    
    private func closeAboutAndPopover() {
        // First, close the About view (V_about)
        dismiss()
        
        // Then, after a short delay, close the popup overlay and adjustment mode overlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Close adjustment mode overlay (O_adjust) if it's active
            OverlayManager.shared.setAdjustable(false)
            OverlayManager.shared.hide()
            
            // Close the popup overlay (O_popup) - ensure it's closed
            if let keyWindow = NSApp.keyWindow {
                keyWindow.performClose(nil)
            }
            // Also try to close any popover windows
            for window in NSApp.windows {
                if window.isVisible && window != NSApp.keyWindow {
                    window.performClose(nil)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct LibraryInfo: View {
    let name: String
    let version: String
    let license: String
    var showLicense: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text(version)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("License: \(license)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if showLicense != nil {
                    Button("View") {
                        showLicense?()
                    }
                    .font(.caption2)
                    .buttonStyle(.link)
                }
            }
        }
    }
}

// MARK: - License View

struct LicenseView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Third-party Licenses")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // KeyboardShortcuts License
                    LicenseSection(
                        title: "KeyboardShortcuts",
                        version: "2.3.0+",
                        license: keyboardShortcutsLicense
                    )
                    
                    Divider()
                    
                    // App License
                    LicenseSection(
                        title: "SattoPad",
                        version: "1.0",
                        license: sattoPadLicense
                    )
                }
                .padding()
            }
        }
        .padding(20)
        .frame(width: 600, height: 520)
    }
    
    private var keyboardShortcutsLicense: String {
        """
        MIT License

        Copyright (c) Sindre Sorhus <sindresorhus@gmail.com> (https://sindresorhus.com)

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
        """
    }
    
    private var sattoPadLicense: String {
        """
        SattoPad - A memo app specialized for quick viewing on macOS

        Copyright (c) 2025 SattoPad Contributors

        This software is provided as-is for personal and educational use.
        You may use, modify, and distribute this software for non-commercial purposes.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
        """
    }
}

struct LicenseSection: View {
    let title: String
    let version: String
    let license: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("v\(version)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(license)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    AboutView()
}