//
//  DesktopMemoSettingsView.swift
//  SattoPad
//
//  Batch editor for default and per-desktop memo assignments.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DesktopMemoSettingsView: View {
    @ObservedObject private var assignmentStore = MemoAssignmentStore.shared
    @ObservedObject private var markdownStore = MarkdownStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Divider()

            defaultFileSection

            Divider()

            desktopSection

            Spacer(minLength: 0)

            HStack {
                Text("Space の識別はアプリ起動中のみ保持されます。再起動後は必要に応じて現在のデスクトップへ再紐付けしてください。")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button("閉じる") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 560, height: 500)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("デスクトップ別メモ")
                    .font(.headline)
                Text("現在: \(assignmentStore.activeDesktopName())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                _ = assignmentStore.registerCurrentDesktop()
                markdownStore.activateMemoFile(assignmentStore.memoFileForActiveDesktop())
            } label: {
                Label("現在を登録", systemImage: "plus")
            }
        }
    }

    private var defaultFileSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("既定の md ファイル")
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(assignmentStore.defaultMemoFile.displayName)
                        .lineLimit(1)
                    Text(assignmentStore.defaultMemoFile.shortPath)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
                Button {
                    if let url = MarkdownFilePicker.pickMarkdownFile() {
                        _ = assignmentStore.updateDefaultMemoFile(to: url)
                        markdownStore.activateMemoFile(assignmentStore.memoFileForActiveDesktop())
                    }
                } label: {
                    Label("変更", systemImage: "folder")
                }
            }
        }
    }

    private var desktopSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("デスクトップ割り当て")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    _ = assignmentStore.registerCurrentDesktop()
                    markdownStore.activateMemoFile(assignmentStore.memoFileForActiveDesktop())
                } label: {
                    Label("現在を追加", systemImage: "plus")
                }
                .buttonStyle(.borderless)
            }

            if assignmentStore.desktops.isEmpty {
                ContentUnavailableView(
                    "登録済みデスクトップなし",
                    systemImage: "macwindow",
                    description: Text("現在のデスクトップを登録すると、個別の md ファイルを割り当てられます。")
                )
                .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(assignmentStore.desktops) { desktop in
                            DesktopAssignmentRow(desktop: desktop)
                        }
                    }
                }
            }
        }
    }
}

private struct DesktopAssignmentRow: View {
    let desktop: DesktopMemoAssignment
    @ObservedObject private var assignmentStore = MemoAssignmentStore.shared
    @ObservedObject private var markdownStore = MarkdownStore.shared
    @State private var name: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("名前", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)
                    .onAppear { name = desktop.name }
                    .onChange(of: name) { _, newValue in
                        assignmentStore.renameDesktop(desktop.id, to: newValue)
                    }

                if assignmentStore.activeDesktopID == desktop.id {
                    Text("現在")
                        .font(.caption2)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.quaternary, in: Capsule())
                }

                Spacer()

                Button {
                    assignmentStore.bindDesktopToCurrentSpace(desktop.id)
                    markdownStore.activateMemoFile(assignmentStore.memoFileForActiveDesktop())
                } label: {
                    Label("現在に紐付け", systemImage: "link")
                }
                .buttonStyle(.borderless)

                Button(role: .destructive) {
                    assignmentStore.removeDesktop(desktop.id)
                    markdownStore.activateMemoFile(assignmentStore.memoFileForActiveDesktop())
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }

            HStack(spacing: 8) {
                Toggle("既定を使用", isOn: Binding(
                    get: { desktop.usesDefaultFile },
                    set: { usesDefault in
                        if usesDefault {
                            assignmentStore.setDesktopUsesDefault(desktop.id)
                            markdownStore.activateMemoFile(assignmentStore.memoFileForActiveDesktop())
                        } else if let url = MarkdownFilePicker.pickMarkdownFile() {
                            _ = assignmentStore.updateDesktopMemoFile(desktop.id, to: url)
                            markdownStore.activateMemoFile(assignmentStore.memoFileForActiveDesktop())
                        }
                    }
                ))
                .toggleStyle(.checkbox)
                .frame(width: 110, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    let memoFile = desktop.memoFile
                    Text(memoFile?.displayName ?? assignmentStore.defaultMemoFile.displayName)
                        .lineLimit(1)
                    Text(memoFile?.shortPath ?? "既定: \(assignmentStore.defaultMemoFile.shortPath)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                Button {
                    if let url = MarkdownFilePicker.pickMarkdownFile() {
                        _ = assignmentStore.updateDesktopMemoFile(desktop.id, to: url)
                        markdownStore.activateMemoFile(assignmentStore.memoFileForActiveDesktop())
                    }
                } label: {
                    Label(desktop.memoFile == nil ? "個別指定" : "変更", systemImage: "folder")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary)
        )
    }
}

enum MarkdownFilePicker {
    static func pickMarkdownFile() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "md ファイルを選択"
        panel.prompt = "選択"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if #available(macOS 12.0, *) {
            var types: [UTType] = [.plainText]
            if let md = UTType(filenameExtension: "md") { types.insert(md, at: 0) }
            if let markdown = UTType(filenameExtension: "markdown") { types.append(markdown) }
            panel.allowedContentTypes = types
        } else {
            panel.allowedFileTypes = ["md", "markdown", "txt"]
        }

        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }
}

#Preview {
    DesktopMemoSettingsView()
}
