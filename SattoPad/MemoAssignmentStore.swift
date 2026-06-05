//
//  MemoAssignmentStore.swift
//  SattoPad
//
//  Persists default and per-desktop markdown file assignments.
//

import AppKit
import Foundation

struct MemoFileReference: Codable, Equatable, Identifiable {
    var id: UUID
    var displayName: String
    var path: String
    var bookmarkData: Data?

    var url: URL {
        URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
    }

    var shortPath: String {
        let home = NSHomeDirectory()
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    static func make(for url: URL, bookmarkData: Data?) -> MemoFileReference {
        MemoFileReference(
            id: UUID(),
            displayName: url.deletingPathExtension().lastPathComponent,
            path: url.path,
            bookmarkData: bookmarkData
        )
    }
}

struct DesktopMemoAssignment: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var memoFile: MemoFileReference?

    var usesDefaultFile: Bool {
        memoFile == nil
    }
}

final class MemoAssignmentStore: ObservableObject {
    static let shared = MemoAssignmentStore()

    @Published private(set) var defaultMemoFile: MemoFileReference
    @Published private(set) var desktops: [DesktopMemoAssignment]
    @Published private(set) var activeDesktopID: UUID?

    @Published var lastWarningMessage: String?

    private let defaults = UserDefaults.standard
    private let stateKey = "sattoPad.memoAssignments.v1"
    private let legacyPathKey = "sattoPad.markdownPath"
    private let legacyBookmarkKey = "sattoPad.markdownBookmark"
    private var markerWindows: [UUID: NSPanel] = [:]
    private var spaceObserver: NSObjectProtocol?

    private init() {
        let loaded = Self.loadState(
            from: defaults,
            stateKey: stateKey,
            legacyPathKey: legacyPathKey,
            legacyBookmarkKey: legacyBookmarkKey
        )
        defaultMemoFile = loaded.defaultMemoFile
        desktops = loaded.desktops
        activeDesktopID = loaded.activeDesktopID
    }

    // MARK: - Public API

    func startTrackingSpaces() {
        guard spaceObserver == nil else { return }
        spaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshActiveDesktopFromMarkers()
        }
        refreshActiveDesktopFromMarkers()
    }

    func memoFileForActiveDesktop() -> MemoFileReference {
        if let activeDesktopID,
           let desktop = desktops.first(where: { $0.id == activeDesktopID }),
           let memoFile = desktop.memoFile {
            return memoFile
        }
        return defaultMemoFile
    }

    func activeDesktopName() -> String {
        guard let activeDesktopID,
              let desktop = desktops.first(where: { $0.id == activeDesktopID }) else {
            return "未登録のデスクトップ"
        }
        return desktop.name
    }

    @discardableResult
    func registerCurrentDesktop() -> UUID {
        let name = nextDesktopName()
        let desktop = DesktopMemoAssignment(id: UUID(), name: name, memoFile: nil)
        desktops.append(desktop)
        bindDesktopToCurrentSpace(desktop.id)
        persist()
        return desktop.id
    }

    func bindDesktopToCurrentSpace(_ desktopID: UUID) {
        guard desktops.contains(where: { $0.id == desktopID }) else { return }
        markerWindows[desktopID]?.close()
        markerWindows[desktopID] = createMarkerWindow()
        activeDesktopID = desktopID
        persist()
    }

    func renameDesktop(_ desktopID: UUID, to name: String) {
        guard let index = desktops.firstIndex(where: { $0.id == desktopID }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        desktops[index].name = trimmed.isEmpty ? "Desktop" : trimmed
        persist()
    }

    func removeDesktop(_ desktopID: UUID) {
        markerWindows[desktopID]?.close()
        markerWindows[desktopID] = nil
        desktops.removeAll { $0.id == desktopID }
        if activeDesktopID == desktopID {
            activeDesktopID = nil
        }
        persist()
    }

    @discardableResult
    func updateDefaultMemoFile(to url: URL) -> MemoFileReference {
        let memoFile = makeMemoFile(for: url, existingID: defaultMemoFile.id)
        defaultMemoFile = memoFile
        defaults.set(memoFile.path, forKey: legacyPathKey)
        if let bookmarkData = memoFile.bookmarkData {
            defaults.set(bookmarkData, forKey: legacyBookmarkKey)
        }
        persist()
        return memoFile
    }

    @discardableResult
    func updateActiveMemoFileLocation(to url: URL) -> MemoFileReference {
        if let activeDesktopID,
           let index = desktops.firstIndex(where: { $0.id == activeDesktopID }),
           desktops[index].memoFile != nil {
            return updateDesktopMemoFile(activeDesktopID, to: url)
        }
        return updateDefaultMemoFile(to: url)
    }

    @discardableResult
    func updateDesktopMemoFile(_ desktopID: UUID, to url: URL) -> MemoFileReference {
        guard let index = desktops.firstIndex(where: { $0.id == desktopID }) else {
            return updateDefaultMemoFile(to: url)
        }
        let memoFile = makeMemoFile(for: url, existingID: desktops[index].memoFile?.id)
        desktops[index].memoFile = memoFile
        persist()
        return memoFile
    }

    func setDesktopUsesDefault(_ desktopID: UUID) {
        guard let index = desktops.firstIndex(where: { $0.id == desktopID }) else { return }
        desktops[index].memoFile = nil
        persist()
    }

    func updateBookmark(for memoFileID: UUID, bookmarkData: Data) {
        if defaultMemoFile.id == memoFileID {
            defaultMemoFile.bookmarkData = bookmarkData
            defaults.set(bookmarkData, forKey: legacyBookmarkKey)
        }

        for index in desktops.indices where desktops[index].memoFile?.id == memoFileID {
            desktops[index].memoFile?.bookmarkData = bookmarkData
        }

        persist()
    }

    // MARK: - Persistence

    private func persist() {
        let state = MemoAssignmentState(
            defaultMemoFile: defaultMemoFile,
            desktops: desktops,
            activeDesktopID: activeDesktopID
        )
        do {
            let data = try JSONEncoder().encode(state)
            defaults.set(data, forKey: stateKey)
        } catch {
            lastWarningMessage = "デスクトップ別メモ設定の保存に失敗しました: \(error.localizedDescription)"
        }
    }

    private static func loadState(
        from defaults: UserDefaults,
        stateKey: String,
        legacyPathKey: String,
        legacyBookmarkKey: String
    ) -> MemoAssignmentState {
        if let data = defaults.data(forKey: stateKey),
           let state = try? JSONDecoder().decode(MemoAssignmentState.self, from: data) {
            return state
        }

        let path = defaults.string(forKey: legacyPathKey) ?? defaultMarkdownURL().path
        let bookmarkData = defaults.data(forKey: legacyBookmarkKey)
        let defaultMemoFile = MemoFileReference(
            id: UUID(),
            displayName: URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent,
            path: path,
            bookmarkData: bookmarkData
        )
        return MemoAssignmentState(defaultMemoFile: defaultMemoFile, desktops: [], activeDesktopID: nil)
    }

    private static func defaultMarkdownURL() -> URL {
        URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Documents")
            .appendingPathComponent("SattoPad")
            .appendingPathComponent("SattoPad.md")
    }

    private func makeMemoFile(for url: URL, existingID: UUID?) -> MemoFileReference {
        let bookmarkData = createBookmark(for: url)
        var memoFile = MemoFileReference.make(for: url, bookmarkData: bookmarkData)
        if let existingID {
            memoFile.id = existingID
        }
        return memoFile
    }

    private func createBookmark(for url: URL) -> Data? {
        do {
            return try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        } catch {
            lastWarningMessage = "ファイルアクセス権の保存に失敗しました: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - Spaces

    private func refreshActiveDesktopFromMarkers() {
        if let match = markerWindows.first(where: { $0.value.isOnActiveSpace }) {
            activeDesktopID = match.key
        } else {
            activeDesktopID = nil
        }
        persist()
    }

    private func createMarkerWindow() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: -10_000, y: -10_000, width: 1, height: 1),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.alphaValue = 0.01
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.ignoresCycle, .stationary]
        panel.level = .normal
        panel.orderBack(nil)
        return panel
    }

    private func nextDesktopName() -> String {
        var index = desktops.count + 1
        var candidate = "Desktop \(index)"
        let existing = Set(desktops.map(\.name))
        while existing.contains(candidate) {
            index += 1
            candidate = "Desktop \(index)"
        }
        return candidate
    }
}

private struct MemoAssignmentState: Codable {
    var defaultMemoFile: MemoFileReference
    var desktops: [DesktopMemoAssignment]
    var activeDesktopID: UUID?
}
