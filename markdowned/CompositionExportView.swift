//
//  CompositionExportView.swift
//  markdowned
//
//  Export options for compositions
//

import SwiftUI

enum ExportFormat: String, CaseIterable, Identifiable {
    case plainText = "Plain Text"
    case markdown = "Markdown"
    case richText = "Rich Text"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .plainText: return "doc.text"
        case .markdown: return "text.badge.checkmark"
        case .richText: return "doc.richtext"
        }
    }

    var fileExtension: String {
        switch self {
        case .plainText: return "txt"
        case .markdown: return "md"
        case .richText: return "rtf"
        }
    }

    var description: String {
        switch self {
        case .plainText: return "Simple text without formatting"
        case .markdown: return "Formatted text with source citations"
        case .richText: return "Preserves highlight colors"
        }
    }
}

struct CompositionExportView: View {
    let composition: Composition

    @ObservedObject private var compositionsManager = CompositionsManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFormat: ExportFormat = .markdown
    @State private var previewText = ""
    @State private var showingShareSheet = false

    var body: some View {
        NavigationStack {
            List {
                // Format selection
                Section("Format") {
                    ForEach(ExportFormat.allCases) { format in
                        Button {
                            selectedFormat = format
                            updatePreview()
                        } label: {
                            HStack {
                                Image(systemName: format.icon)
                                    .frame(width: 24)
                                    .foregroundStyle(.primary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(format.rawValue)
                                        .foregroundStyle(.primary)
                                    Text(format.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if selectedFormat == format {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Preview
                Section("Preview") {
                    Text(previewText)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        shareExport()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .onAppear {
                updatePreview()
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [getExportContent()])
            }
        }
    }

    private func updatePreview() {
        switch selectedFormat {
        case .plainText:
            previewText = compositionsManager.exportAsPlainText(composition)
        case .markdown:
            previewText = compositionsManager.exportAsMarkdown(composition)
        case .richText:
            // Show plain text preview for rich text
            previewText = compositionsManager.exportAsPlainText(composition) + "\n\n(Colors preserved in exported file)"
        }

        // Limit preview length
        if previewText.count > 1000 {
            previewText = String(previewText.prefix(1000)) + "\n\n[Preview truncated...]"
        }
    }

    private func getExportContent() -> Any {
        switch selectedFormat {
        case .plainText:
            return compositionsManager.exportAsPlainText(composition)
        case .markdown:
            return compositionsManager.exportAsMarkdown(composition)
        case .richText:
            return compositionsManager.exportAsAttributedString(composition)
        }
    }

    private func shareExport() {
        showingShareSheet = true
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    CompositionExportView(
        composition: Composition(
            id: UUID(),
            title: "Sample Export",
            sortMode: .manual,
            fragments: [],
            createdAt: Date(),
            modifiedAt: Date()
        )
    )
}
