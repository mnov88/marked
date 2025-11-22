//
//  FragmentCardView.swift
//  markdowned
//
//  Reusable card component for displaying a composition fragment
//

import SwiftUI

struct FragmentCardView: View {
    let fragment: CompositionFragment
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Color indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(platformColor: fragment.color))
                    .frame(width: 6)

                VStack(alignment: .leading, spacing: 8) {
                    // Source document label
                    HStack {
                        Image(systemName: "doc.text")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(fragment.documentTitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    // Text snippet
                    Text(fragment.textSnippet)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)

                    // Timestamp
                    Text(fragment.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(12)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: onTap) {
                Label("Go to Source", systemImage: "arrow.right.doc.on.clipboard")
            }

            Divider()

            Button(role: .destructive, action: onDelete) {
                Label("Remove from Composition", systemImage: "minus.circle")
            }
        }
    }
}

// MARK: - Compact Variant for Lists

struct FragmentRowView: View {
    let fragment: CompositionFragment
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Color indicator
                Circle()
                    .fill(Color(platformColor: fragment.color))
                    .frame(width: 12, height: 12)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(fragment.textSnippet)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(3)

                    HStack {
                        Text(fragment.documentTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("•")
                            .foregroundStyle(.tertiary)

                        Text(fragment.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Draggable Fragment Card

struct DraggableFragmentCard: View {
    let fragment: CompositionFragment
    let isReordering: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Drag handle (visible when reordering)
            if isReordering {
                Image(systemName: "line.3.horizontal")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
            }

            FragmentCardView(
                fragment: fragment,
                onTap: onTap,
                onDelete: onDelete
            )
        }
    }
}

#Preview("Fragment Card") {
    let fragment = CompositionFragment(
        id: UUID(),
        highlightId: UUID(),
        documentId: UUID(),
        documentTitle: "Sample Document Title",
        textSnippet: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.",
        range: NSRange(location: 0, length: 100),
        color: .systemYellow,
        sortOrder: 0,
        createdAt: Date().addingTimeInterval(-3600)
    )

    VStack(spacing: 16) {
        FragmentCardView(
            fragment: fragment,
            onTap: { print("Tapped") },
            onDelete: { print("Delete") }
        )

        FragmentRowView(
            fragment: fragment,
            onTap: { print("Tapped row") }
        )
    }
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}
