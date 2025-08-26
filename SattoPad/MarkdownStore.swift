//
//  MarkdownStore.swift
//  SattoPad
//
//  Manages autosave/load of a Markdown file with debounced writes.
//

import Foundation
import AppKit
import Darwin
import UniformTypeIdentifiers

final class MarkdownStore: ObservableObject {
    static let shared = MarkdownStore()

    @Published private(set) var text: String = ""
    @Published var isSaving: Bool = false
    @Published var lastErrorMessage: String?
    @Published var lastWarningMessage: String?

    private let ioQueue = DispatchQueue(label: "dev.sattopad.markdown.io", qos: .utility)
    private var pendingSaveWorkItem: DispatchWorkItem?

    private let defaults = UserDefaults.standard
    private let pathKey = "sattoPad.markdownPath"
    private let bookmarkKey = "sattoPad.markdownBookmark"
    private var lastSavedText: String = ""
    private var lastWriteAt: Date?

    // File monitoring (external changes)
    private var fileMonitor: DispatchSourceFileSystemObject?
    private var monitoredFD: Int32 = -1
    private var monitoredURL: URL?

    private init() {}

    // MARK: - Public API

    func loadOnLaunch() {
        readCurrentFile()
    }

    func setTextAndScheduleAutosave(_ newText: String) {
        DispatchQueue.main.async { [weak self] in
            self?.text = newText
        }
        scheduleDebouncedSave()
    }

    func saveNow() {
        pendingSaveWorkItem?.cancel()
        performSave()
    }

    func reloadFromDisk() {
        readCurrentFile()
    }

    func selectSaveLocation() {
        let panel = NSOpenPanel()
        panel.title = "保存先を選択"
        panel.prompt = "選択"
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        if #available(macOS 12.0, *) {
            var types: [UTType] = [.plainText]
            if let md = UTType(filenameExtension: "md") { types.insert(md, at: 0) }
            if let mdx = UTType(filenameExtension: "markdown") { types.append(mdx) }
            panel.allowedContentTypes = types
        } else {
            panel.allowedFileTypes = ["md", "markdown", "txt"]
        }

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }

        // If a directory was selected, use SattoPad.md inside it
        var isDir: ObjCBool = false
        var targetURL = url
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            targetURL = url.appendingPathComponent("SattoPad.md")
        }

        // Persist path and security-scoped bookmark (for sandbox配布も考慮)
        defaults.set(targetURL.path, forKey: pathKey)
        do {
            let data = try targetURL.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            defaults.set(data, forKey: bookmarkKey)
        } catch {
            #if DEBUG
            print("[SattoPad] bookmark create failed: \(error)")
            #endif
            // 失敗してもパス保存でフォールバック
            defaults.removeObject(forKey: bookmarkKey)
        }

        // If file exists, load it. If not, create it with current text
        accessURL(targetURL) { accessibleURL in
            if FileManager.default.fileExists(atPath: accessibleURL.path) {
                readFile(at: accessibleURL)
            } else {
                ensureParentDirectoryExists(for: accessibleURL)
                _ = writeString(text, to: accessibleURL)
            }
            startFileMonitor(for: accessibleURL)
        }
    }

    // MARK: - Internal

    private func scheduleDebouncedSave(delaySeconds: TimeInterval = 1.0) {
        pendingSaveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.performSave()
        }
        pendingSaveWorkItem = work
        ioQueue.asyncAfter(deadline: .now() + delaySeconds, execute: work)
    }

    private func performSave() {
        let currentText = text
        // 差分なしなら保存スキップ
        if currentText == lastSavedText {
            return
        }
        isSavingOnMain(true)
        ioQueue.async { [weak self] in
            guard let self else { return }
            guard let url = self.resolveSaveURL() else { return }
            self.accessURL(url) { accessibleURL in
                self.ensureParentDirectoryExists(for: accessibleURL)
                var ok = self.writeString(currentText, to: accessibleURL)
                if !ok {
                    // Retry up to 2 more times with backoff
                    for attempt in 1...2 {
                        let delaySeconds = pow(2.0, Double(attempt)) * 0.2
                        Thread.sleep(forTimeInterval: delaySeconds)
                        ok = self.writeString(currentText, to: accessibleURL)
                        if ok { break }
                    }
                }
                DispatchQueue.main.async {
                    self.isSaving = false
                    if ok {
                        self.lastSavedText = currentText
                    } else {
                        self.lastErrorMessage = "保存に失敗しました"
                    }
                }
            }
        }
    }

    private func readFile(at url: URL) {
        ioQueue.async { [weak self] in
            guard let self else { return }
            var loaded = ""
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    let data = try Data(contentsOf: url)
                    if data.count > 5_000_000 {
                        // Large, but still try to decode
                        #if DEBUG
                        print("[SattoPad] Warning: file size > 5MB (", data.count, ")")
                        #endif
                        DispatchQueue.main.async { self.lastWarningMessage = "ファイルサイズが大きい可能性があります (\(data.count) bytes)" }
                    }
                    loaded = String(data: data, encoding: .utf8) ?? ""
                } catch {
                    DispatchQueue.main.async {
                        self.lastErrorMessage = "読み込みに失敗しました: \(error.localizedDescription)"
                    }
                }
            }
            // Normalize newlines to \n for editor consistency
            let normalized = loaded.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
            DispatchQueue.main.async {
                self.text = normalized
                self.lastSavedText = normalized
            }
        }
    }

    // MARK: - URL resolution

    private func resolveSaveURL() -> URL? {
        // Prefer security-scoped bookmark if available
        if let data = defaults.data(forKey: bookmarkKey) {
            do {
                var stale = false
                let url = try URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &stale)
                if stale {
                    // Refresh bookmark
                    let newData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                    defaults.set(newData, forKey: bookmarkKey)
                }
                return url
            } catch {
                #if DEBUG
                print("[SattoPad] bookmark resolve failed: \(error)")
                #endif
            }
        }
        if let path = defaults.string(forKey: pathKey), !path.isEmpty {
            return URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        }
        // Default path: ~/Documents/SattoPad.md
        let home = NSHomeDirectory()
        let url = URL(fileURLWithPath: home).appendingPathComponent("Documents").appendingPathComponent("SattoPad.md")
        return url
    }

    // MARK: - Helpers

    private func isSavingOnMain(_ saving: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isSaving = saving
        }
    }

    private func ensureParentDirectoryExists(for url: URL) {
        let parent = url.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        } catch {
            #if DEBUG
            print("[SattoPad] createDirectory error: \(error)")
            #endif
        }
    }

    @discardableResult
    private func writeString(_ string: String, to url: URL) -> Bool {
        do {
            try string.write(to: url, atomically: true, encoding: .utf8)
            lastWriteAt = Date()
            return true
        } catch {
            #if DEBUG
            print("[SattoPad] write error: \(error)")
            #endif
            return false
        }
    }

    // MARK: - Security scope access helper
    private func accessURL(_ url: URL, perform: (URL) -> Void) {
        var needsStop = false
        if url.startAccessingSecurityScopedResource() {
            needsStop = true
        }
        defer {
            if needsStop { url.stopAccessingSecurityScopedResource() }
        }
        perform(url)
    }

    // Expose pending changes state for UI confirm
    var hasPendingChanges: Bool {
        return text != lastSavedText || pendingSaveWorkItem != nil
    }

    private func readCurrentFile() {
        guard let url = resolveSaveURL() else { return }
        startFileMonitor(for: url)
        accessURL(url) { accessibleURL in
            readFile(at: accessibleURL)
        }
    }

    // MARK: - File monitoring
    private func startFileMonitor(for url: URL) {
        stopFileMonitor()
        monitoredURL = url
        var fd: Int32 = -1
        accessURL(url) { u in
            fd = open(u.path, O_EVTONLY)
        }
        guard fd >= 0 else {
            #if DEBUG
            print("[SattoPad] open for monitor failed: \(url.path)")
            #endif
            return
        }
        monitoredFD = fd
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: [.write, .delete, .rename, .attrib, .extend], queue: ioQueue)
        source.setEventHandler { [weak self] in
            self?.handleFileEvent()
        }
        source.setCancelHandler { [weak self] in
            if let fd = self?.monitoredFD, fd >= 0 { close(fd) }
        }
        fileMonitor = source
        source.resume()
    }

    private func stopFileMonitor() {
        fileMonitor?.cancel()
        fileMonitor = nil
        if monitoredFD >= 0 { close(monitoredFD); monitoredFD = -1 }
        monitoredURL = nil
    }

    private func handleFileEvent() {
        guard let url = monitoredURL else { return }
        // Ignore our own writes for a short window
        if let ts = lastWriteAt, Date().timeIntervalSince(ts) < 1.0 {
            return
        }
        // If file was removed/renamed, attempt to restart monitor later
        if !FileManager.default.fileExists(atPath: url.path) {
            stopFileMonitor()
            // Try to restart after short delay
            ioQueue.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self, let newURL = self.resolveSaveURL() else { return }
                self.startFileMonitor(for: newURL)
            }
            return
        }
        // External change: reload if no pending changes; otherwise warn
        if hasPendingChanges {
            DispatchQueue.main.async { [weak self] in
                self?.lastWarningMessage = "外部で変更が検出されました。未保存の変更があります。『ファイルから再読み込み』で反映できます。"
            }
        } else {
            readFile(at: url)
        }
    }
}
