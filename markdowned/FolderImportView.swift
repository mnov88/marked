//
//  FolderImportView.swift
//  markdowned
//
//  Bulk import documents from a folder with optional subfolder support
//

import SwiftUI
import UniformTypeIdentifiers

/// Supported file types for import
enum ImportableFileType: String, CaseIterable {
    case plainText = "txt"
    case markdown = "md"
    case richText = "rtf"

    var utType: UTType {
        switch self {
        case .plainText: return .plainText
        case .markdown: return .init(filenameExtension: "md") ?? .plainText
        case .richText: return .rtf
        }
    }

    var displayName: String {
        switch self {
        case .plainText: return "Plain Text (.txt)"
        case .markdown: return "Markdown (.md)"
        case .richText: return "Rich Text (.rtf)"
        }
    }
}

/// Import progress state
struct ImportProgress: Identifiable {
    let id = UUID()
    var total: Int = 0
    var completed: Int = 0
    var failed: Int = 0
    var currentFile: String = ""
    var errors: [String] = []

    var isComplete: Bool { completed + failed >= total }
    var successRate: Double { total > 0 ? Double(completed) / Double(total) : 0 }
}

/// View for importing documents from a folder
struct FolderImportView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var documentsManager = DocumentsManager.shared
    @ObservedObject private var categoriesManager = CategoriesManager.shared

    @State private var showFolderPicker = false
    @State private var selectedFolderURL: URL?
    @State private var includeSubfolders = true
    @State private var selectedFileTypes: Set<ImportableFileType> = Set(ImportableFileType.allCases)
    @State private var selectedCategoryId: UUID?
    @State private var isImporting = false
    @State private var importProgress: ImportProgress?
    @State private var discoveredFiles: [URL] = []

    var body: some View {
        NavigationStack {
            Form {
                // Folder Selection
                Section {
                    Button {
                        showFolderPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "folder")
                                .foregroundStyle(.blue)
                            if let url = selectedFolderURL {
                                Text(url.lastPathComponent)
                                    .lineLimit(1)
                            } else {
                                Text("Select Folder")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Source Folder")
                }

                // Options
                Section {
                    Toggle("Include Subfolders", isOn: $includeSubfolders)
                        .onChange(of: includeSubfolders) { _, _ in
                            if selectedFolderURL != nil {
                                discoverFiles()
                            }
                        }
                } header: {
                    Text("Options")
                }

                // File Types
                Section {
                    ForEach(ImportableFileType.allCases, id: \.rawValue) { fileType in
                        Toggle(fileType.displayName, isOn: Binding(
                            get: { selectedFileTypes.contains(fileType) },
                            set: { isSelected in
                                if isSelected {
                                    selectedFileTypes.insert(fileType)
                                } else if selectedFileTypes.count > 1 {
                                    selectedFileTypes.remove(fileType)
                                }
                            }
                        ))
                    }
                    .onChange(of: selectedFileTypes) { _, _ in
                        if selectedFolderURL != nil {
                            discoverFiles()
                        }
                    }
                } header: {
                    Text("File Types")
                } footer: {
                    Text("At least one file type must be selected")
                }

                // Category Assignment (optional)
                Section {
                    Picker("Assign to Category", selection: $selectedCategoryId) {
                        Text("None").tag(nil as UUID?)
                        ForEach(categoriesManager.categories) { category in
                            Label(category.name, systemImage: category.icon)
                                .tag(category.id as UUID?)
                        }
                    }
                } header: {
                    Text("Categorization")
                } footer: {
                    Text("Optionally assign all imported documents to a category")
                }

                // Preview
                if !discoveredFiles.isEmpty {
                    Section {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("\(discoveredFiles.count) files found")
                            Spacer()
                        }
                        .foregroundStyle(.secondary)

                        ForEach(discoveredFiles.prefix(5), id: \.absoluteString) { url in
                            Text(url.lastPathComponent)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if discoveredFiles.count > 5 {
                            Text("... and \(discoveredFiles.count - 5) more")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .italic()
                        }
                    } header: {
                        Text("Files to Import")
                    }
                }

                // Import Progress
                if let progress = importProgress {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            ProgressView(value: Double(progress.completed + progress.failed), total: Double(progress.total))

                            HStack {
                                Text("\(progress.completed) imported")
                                    .foregroundStyle(.green)
                                if progress.failed > 0 {
                                    Text("\(progress.failed) failed")
                                        .foregroundStyle(.red)
                                }
                                Spacer()
                                Text("\(progress.completed + progress.failed)/\(progress.total)")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.caption)

                            if !progress.currentFile.isEmpty && !progress.isComplete {
                                Text("Importing: \(progress.currentFile)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    } header: {
                        Text("Progress")
                    }

                    if !progress.errors.isEmpty {
                        Section {
                            ForEach(progress.errors, id: \.self) { error in
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        } header: {
                            Text("Errors")
                        }
                    }
                }
            }
            .navigationTitle("Import from Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isImporting)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if importProgress?.isComplete == true {
                        Button("Done") {
                            dismiss()
                        }
                    } else {
                        Button("Import") {
                            startImport()
                        }
                        .disabled(discoveredFiles.isEmpty || isImporting)
                    }
                }
            }
            .fileImporter(
                isPresented: $showFolderPicker,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                handleFolderSelection(result)
            }
        }
    }

    // MARK: - File Discovery

    private func handleFolderSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            selectedFolderURL = url
            discoverFiles()
        case .failure(let error):
            Logger.error("Folder selection failed", error: error)
        }
    }

    private func discoverFiles() {
        guard let folderURL = selectedFolderURL else {
            discoveredFiles = []
            return
        }

        // Start accessing security-scoped resource
        guard folderURL.startAccessingSecurityScopedResource() else {
            Logger.error("Failed to access folder: \(folderURL.path)")
            return
        }

        defer { folderURL.stopAccessingSecurityScopedResource() }

        let fileManager = FileManager.default
        let extensions = selectedFileTypes.map { $0.rawValue }
        var files: [URL] = []

        if includeSubfolders {
            // Recursive enumeration
            if let enumerator = fileManager.enumerator(
                at: folderURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) {
                for case let fileURL as URL in enumerator {
                    if extensions.contains(fileURL.pathExtension.lowercased()) {
                        files.append(fileURL)
                    }
                }
            }
        } else {
            // Single folder only
            if let contents = try? fileManager.contentsOfDirectory(
                at: folderURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) {
                files = contents.filter { extensions.contains($0.pathExtension.lowercased()) }
            }
        }

        discoveredFiles = files.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    // MARK: - Import

    private func startImport() {
        guard let folderURL = selectedFolderURL else { return }

        isImporting = true
        importProgress = ImportProgress(total: discoveredFiles.count)

        Task {
            // Start accessing security-scoped resource
            guard folderURL.startAccessingSecurityScopedResource() else {
                await MainActor.run {
                    importProgress?.errors.append("Failed to access folder")
                    isImporting = false
                }
                return
            }

            defer { folderURL.stopAccessingSecurityScopedResource() }

            for fileURL in discoveredFiles {
                await MainActor.run {
                    importProgress?.currentFile = fileURL.lastPathComponent
                }

                do {
                    let document = try await importFile(at: fileURL)
                    try documentsManager.addDocument(document)

                    // Assign to category if selected
                    if let categoryId = selectedCategoryId {
                        try categoriesManager.addDocument(document.id, toCategory: categoryId)
                    }

                    await MainActor.run {
                        importProgress?.completed += 1
                    }
                } catch {
                    await MainActor.run {
                        importProgress?.failed += 1
                        importProgress?.errors.append("\(fileURL.lastPathComponent): \(error.localizedDescription)")
                    }
                }
            }

            await MainActor.run {
                importProgress?.currentFile = ""
                isImporting = false
            }
        }
    }

    private func importFile(at url: URL) async throws -> Document {
        let title = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "txt", "md":
            let content = try String(contentsOf: url, encoding: .utf8)
            return Document.plain(content, title: title, sourceURL: url)

        case "rtf":
            let data = try Data(contentsOf: url)
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.rtf
            ]
            let attributedString = try NSAttributedString(data: data, options: options, documentAttributes: nil)
            return Document.attributed(attributedString, title: title, sourceURL: url)

        default:
            throw ImportError.unsupportedFormat(ext)
        }
    }
}

// MARK: - Import Error

enum ImportError: LocalizedError {
    case unsupportedFormat(String)
    case readFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let ext):
            return "Unsupported file format: .\(ext)"
        case .readFailed(let reason):
            return "Failed to read file: \(reason)"
        }
    }
}

#Preview {
    FolderImportView()
}
