//
//  MarkdownStore.swift
//  SattoPad
//
//  Manages autosave/load of a Markdown file with debounced writes.
//  Refactored for improved readability and maintainability with separated concerns.
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
        cancelPendingSave()
        performSave()
    }

    func reloadFromDisk() {
        readCurrentFile()
    }

    func selectSaveLocation() {
        // First, ask user what they want to do
        let alert = NSAlert()
        alert.messageText = "保存先を選択"
        alert.informativeText = "既存のファイルを選択するか，新しいファイルを作成するかを選択してください．"
        alert.addButton(withTitle: "既存ファイルを選択")
        alert.addButton(withTitle: "新しいファイルを作成")
        alert.addButton(withTitle: "キャンセル")
        
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn || response == .alertSecondButtonReturn else { return }
        
        if response == .alertFirstButtonReturn {
            // Select existing file
            selectExistingFile()
        } else {
            // Create new file
            createNewFile()
        }
    }
    
    private func selectExistingFile() {
        let panel = NSOpenPanel()
        panel.title = "既存ファイルを選択"
        panel.prompt = "選択"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
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
        
        let targetURL = url

        // Persist path and security-scoped bookmark (for sandbox配布も考慮)
        defaults.set(targetURL.path, forKey: pathKey)
        _ = createBookmark(for: targetURL)

        // Load existing file
        accessURL(targetURL) { accessibleURL in
            readFile(at: accessibleURL)
            startFileMonitor(for: accessibleURL)
        }
    }
    
    private func createNewFile() {
        // First select directory
        let panel = NSOpenPanel()
        panel.title = "保存先ディレクトリを選択"
        panel.prompt = "選択"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }
        
        // Then ask for filename with existence check
        var filename = "SattoPad.md"
        var targetURL = url.appendingPathComponent(filename)
        
        // Check if file already exists and ask for different name if needed
        while FileManager.default.fileExists(atPath: targetURL.path) {
            let conflictAlert = NSAlert()
            conflictAlert.messageText = "ファイルが既に存在します"
            conflictAlert.informativeText = "「\(filename)」は既に存在します．別の名前を入力するか，自動で番号を付けて作成できます．"
            
            let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
            textField.stringValue = filename
            conflictAlert.accessoryView = textField
            
            conflictAlert.addButton(withTitle: "作成")
            conflictAlert.addButton(withTitle: "番号を付けて作成")
            conflictAlert.addButton(withTitle: "キャンセル")
            
            let conflictResponse = conflictAlert.runModal()
            guard conflictResponse == .alertFirstButtonReturn || conflictResponse == .alertSecondButtonReturn else { return }
            
            if conflictResponse == .alertSecondButtonReturn {
                // Auto-generate filename with number
                filename = generateUniqueFilename(baseName: filename, in: url)
                targetURL = url.appendingPathComponent(filename)
            } else {
                // User provided custom filename
                let newFilename = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !newFilename.isEmpty else {
                    // Show error for empty filename
                    let errorAlert = NSAlert()
                    errorAlert.messageText = "ファイル名が空です"
                    errorAlert.informativeText = "有効なファイル名を入力してください．"
                    errorAlert.addButton(withTitle: "OK")
                    errorAlert.runModal()
                    continue
                }
                
                filename = newFilename
                targetURL = url.appendingPathComponent(filename)
            }
        }
        
        // Persist path and security-scoped bookmark
        defaults.set(targetURL.path, forKey: pathKey)
        _ = createBookmark(for: targetURL)

        // Create new file with current text
        accessURL(targetURL) { accessibleURL in
            ensureParentDirectoryExists(for: accessibleURL)
            _ = writeString(text, to: accessibleURL)
            startFileMonitor(for: accessibleURL)
        }
    }


    // MARK: - File Name Helpers
    
    private func generateUniqueFilename(baseName: String, in directory: URL) -> String {
        let fileExtension = (baseName as NSString).pathExtension
        let nameWithoutExtension = (baseName as NSString).deletingPathExtension
        
        var counter = 1
        var candidateName = baseName
        
        while FileManager.default.fileExists(atPath: directory.appendingPathComponent(candidateName).path) {
            if fileExtension.isEmpty {
                candidateName = "\(nameWithoutExtension) \(counter)"
            } else {
                candidateName = "\(nameWithoutExtension) \(counter).\(fileExtension)"
            }
            counter += 1
        }
        
        return candidateName
    }

    // MARK: - Debounce Management
    
    private func scheduleDebouncedSave(delaySeconds: TimeInterval = 1.0) {
        cancelPendingSave()
        let work = createSaveWorkItem()
        pendingSaveWorkItem = work
        ioQueue.asyncAfter(deadline: .now() + delaySeconds, execute: work)
    }
    
    private func cancelPendingSave() {
        pendingSaveWorkItem?.cancel()
        DispatchQueue.main.async { [weak self] in 
            self?.pendingSaveWorkItem = nil 
        }
    }
    
    private func createSaveWorkItem() -> DispatchWorkItem {
        return DispatchWorkItem { [weak self] in
            self?.performSave()
        }
    }

    // MARK: - Save Operations
    
    private func performSave() {
        let currentText = text
        clearPendingSaveWorkItem()
        
        guard shouldSaveText(currentText) else {
            isSavingOnMain(false)
            return
        }
        
        isSavingOnMain(true)
        saveTextToFile(currentText)
    }
    
    private func clearPendingSaveWorkItem() {
        DispatchQueue.main.async { [weak self] in 
            self?.pendingSaveWorkItem = nil 
        }
    }
    
    private func shouldSaveText(_ currentText: String) -> Bool {
        return currentText != lastSavedText
    }
    
    private func saveTextToFile(_ text: String) {
        ioQueue.async { [weak self] in
            guard let self, let url = self.resolveSaveURL() else { return }
            self.accessURL(url) { accessibleURL in
                let success = self.writeTextWithRetry(text, to: accessibleURL)
                self.handleSaveResult(success: success, text: text)
            }
        }
    }
    
    private func writeTextWithRetry(_ text: String, to url: URL) -> Bool {
        ensureParentDirectoryExists(for: url)
        var success = writeString(text, to: url)
        
        if !success {
            success = retryWriteWithBackoff(text, to: url)
        }
        
        return success
    }
    
    private func retryWriteWithBackoff(_ text: String, to url: URL) -> Bool {
        for attempt in 1...2 {
            let delaySeconds = pow(2.0, Double(attempt)) * 0.2
            Thread.sleep(forTimeInterval: delaySeconds)
            let success = writeString(text, to: url)
            if success { return true }
        }
        return false
    }
    
    private func handleSaveResult(success: Bool, text: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isSaving = false
            if success {
                self.lastSavedText = text
            } else {
                self.lastErrorMessage = "保存に失敗しました"
            }
        }
    }

    // MARK: - Read Operations
    
    private func readFile(at url: URL) {
        ioQueue.async { [weak self] in
            guard let self else { return }
            let content = self.loadFileContent(from: url)
            let normalized = self.normalizeTextContent(content)
            self.updateTextOnMain(normalized)
        }
    }
    
    private func loadFileContent(from url: URL) -> String {
        guard FileManager.default.fileExists(atPath: url.path) else { return "" }
        
        do {
            let data = try Data(contentsOf: url)
            checkFileSize(data)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            handleReadError(error)
            return ""
        }
    }
    
    private func checkFileSize(_ data: Data) {
        if data.count > 5_000_000 {
            #if DEBUG
            print("[SattoPad] Warning: file size > 5MB (", data.count, ")")
            #endif
            DispatchQueue.main.async { [weak self] in
                self?.lastWarningMessage = "ファイルサイズが大きい可能性があります (\(data.count) bytes)"
            }
        }
    }
    
    private func handleReadError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.lastErrorMessage = "読み込みに失敗しました: \(error.localizedDescription)"
        }
    }
    
    private func normalizeTextContent(_ content: String) -> String {
        return content.replacingOccurrences(of: "\r\n", with: "\n")
                     .replacingOccurrences(of: "\r", with: "\n")
    }
    
    private func updateTextOnMain(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            self?.text = text
            self?.lastSavedText = text
        }
    }

    // MARK: - URL Resolution and Bookmark Management
    
    private func resolveSaveURL() -> URL? {
        if let url = resolveFromBookmark() {
            return url
        }
        if let url = resolveFromPath() {
            return url
        }
        return createDefaultURL()
    }
    
    private func resolveFromBookmark() -> URL? {
        guard let data = defaults.data(forKey: bookmarkKey) else { return nil }
        
        do {
            var stale = false
            let url = try URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &stale)
            if stale {
                refreshBookmark(for: url)
            }
            return url
        } catch {
            logBookmarkError("resolve failed", error: error)
            return nil
        }
    }
    
    private func resolveFromPath() -> URL? {
        guard let path = defaults.string(forKey: pathKey), !path.isEmpty else { return nil }
        return URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
    }
    
    private func createDefaultURL() -> URL {
        let home = NSHomeDirectory()
        return URL(fileURLWithPath: home)
            .appendingPathComponent("Documents")
            .appendingPathComponent("SattoPad")
            .appendingPathComponent("SattoPad.md")
    }
    
    private func refreshBookmark(for url: URL) {
        do {
            let newData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            defaults.set(newData, forKey: bookmarkKey)
        } catch {
            logBookmarkError("refresh failed", error: error)
        }
    }
    
    private func createBookmark(for url: URL) -> Bool {
        do {
            let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            defaults.set(data, forKey: bookmarkKey)
            return true
        } catch {
            logBookmarkError("create failed", error: error)
            defaults.removeObject(forKey: bookmarkKey)
            return false
        }
    }
    
    private func logBookmarkError(_ operation: String, error: Error) {
        #if DEBUG
        print("[SattoPad] bookmark \(operation) failed: \(error)")
        #endif
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
        // pendingSaveWorkItem が残っていても、テキスト差分が無ければ未保存扱いにしない
        if text == lastSavedText { return false }
        return true
    }

    private func readCurrentFile() {
        guard let url = resolveSaveURL() else { return }
        startFileMonitor(for: url)
        accessURL(url) { accessibleURL in
            readFile(at: accessibleURL)
        }
    }

    // MARK: - File Monitoring
    
    private func startFileMonitor(for url: URL) {
        stopFileMonitor()
        monitoredURL = url
        
        guard let fd = openFileForMonitoring(url) else { return }
        monitoredFD = fd
        
        let source = createFileMonitorSource(fd: fd)
        fileMonitor = source
        source.resume()
    }
    
    private func openFileForMonitoring(_ url: URL) -> Int32? {
        var fd: Int32 = -1
        accessURL(url) { u in
            fd = open(u.path, O_EVTONLY)
        }
        
        guard fd >= 0 else {
            logMonitorError("open failed", url: url)
            return nil
        }
        
        return fd
    }
    
    private func createFileMonitorSource(fd: Int32) -> DispatchSourceFileSystemObject {
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .attrib, .extend],
            queue: ioQueue
        )
        
        source.setEventHandler { [weak self] in
            self?.handleFileEvent()
        }
        
        source.setCancelHandler { [weak self] in
            self?.closeMonitorFileDescriptor()
        }
        
        return source
    }
    
    private func stopFileMonitor() {
        fileMonitor?.cancel()
        fileMonitor = nil
        closeMonitorFileDescriptor()
        monitoredURL = nil
    }
    
    private func closeMonitorFileDescriptor() {
        if monitoredFD >= 0 {
            close(monitoredFD)
            monitoredFD = -1
        }
    }
    
    private func logMonitorError(_ operation: String, url: URL) {
        #if DEBUG
        print("[SattoPad] monitor \(operation): \(url.path)")
        #endif
    }

    private func handleFileEvent() {
        guard let url = monitoredURL else { return }
        
        if shouldIgnoreFileEvent() { return }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            handleFileRemoved()
            return
        }
        
        handleExternalFileChange(at: url)
    }
    
    private func shouldIgnoreFileEvent() -> Bool {
        guard let ts = lastWriteAt else { return false }
        return Date().timeIntervalSince(ts) < 1.0
    }
    
    private func handleFileRemoved() {
        stopFileMonitor()
        scheduleMonitorRestart()
    }
    
    private func scheduleMonitorRestart() {
        ioQueue.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self, let newURL = self.resolveSaveURL() else { return }
            self.startFileMonitor(for: newURL)
        }
    }
    
    private func handleExternalFileChange(at url: URL) {
        if hasPendingChanges {
            showExternalChangeWarning()
        } else {
            readFile(at: url)
        }
    }
    
    private func showExternalChangeWarning() {
        DispatchQueue.main.async { [weak self] in
            self?.lastWarningMessage = "外部で変更が検出されました。未保存の変更があります。『ファイルから再読み込み』で反映できます。"
        }
    }
}
