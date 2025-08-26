//
//  MarkdownStore.swift
//  SattoPad
//
//  Manages autosave/load of a Markdown file with debounced writes.
//

import Foundation
import AppKit

final class MarkdownStore: ObservableObject {
    static let shared = MarkdownStore()

    @Published private(set) var text: String = ""
    @Published var isSaving: Bool = false
    @Published var lastErrorMessage: String?

    private let ioQueue = DispatchQueue(label: "dev.sattopad.markdown.io", qos: .utility)
    private var pendingSaveWorkItem: DispatchWorkItem?

    private let defaults = UserDefaults.standard
    private let pathKey = "sattoPad.markdownPath"
    private let bookmarkKey = "sattoPad.markdownBookmark"

    private init() {}

    // MARK: - Public API

    func loadOnLaunch() {
        guard let url = resolveSaveURL() else { return }
        readFile(at: url)
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
        guard let url = resolveSaveURL() else { return }
        readFile(at: url)
    }

    func selectSaveLocation() {
        let panel = NSOpenPanel()
        panel.title = "保存先を選択"
        panel.prompt = "選択"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.allowedFileTypes = ["md", "markdown", "txt"]

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }

        // Persist plain path for non-sandbox case
        defaults.set(url.path, forKey: pathKey)
        defaults.removeObject(forKey: bookmarkKey)

        // If file exists, load it. If not, create it with current text
        if FileManager.default.fileExists(atPath: url.path) {
            readFile(at: url)
        } else {
            ensureParentDirectoryExists(for: url)
            writeString(text, to: url)
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
        guard let url = resolveSaveURL() else { return }
        let currentText = text
        isSavingOnMain(true)
        ioQueue.async { [weak self] in
            guard let self else { return }
            self.ensureParentDirectoryExists(for: url)
            let ok = self.writeString(currentText, to: url)
            DispatchQueue.main.async {
                self.isSaving = false
                if !ok {
                    self.lastErrorMessage = "保存に失敗しました"
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
            }
        }
    }

    // MARK: - URL resolution

    private func resolveSaveURL() -> URL? {
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
            return true
        } catch {
            #if DEBUG
            print("[SattoPad] write error: \(error)")
            #endif
            return false
        }
    }
}
