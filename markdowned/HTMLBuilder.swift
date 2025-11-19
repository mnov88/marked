import Foundation
import Markdown

/// Builds HTML for export with embedded styles
/// Maps to web app's export-html.tsx
class HTMLBuilder {
    private let theme: Theme

    init(theme: Theme) {
        self.theme = theme
    }

    /// Build complete HTML document with theme and highlights
    func build(
        document: Document,
        highlights: [Highlight]
    ) -> String {
        let htmlBody = convertMarkdownToHTML(document.content)
        let htmlWithHighlights = applyHighlights(to: htmlBody, highlights: highlights)
        let css = theme.generateCSS()

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <meta name="generator" content="Markdown Studio iOS">
            <title>\(document.name)</title>
            <style>
        \(css)
            </style>
        </head>
        <body>
            <article>
        \(htmlWithHighlights)
            </article>
            <footer style="margin-top: 3rem; padding-top: 1rem; border-top: 1px solid #e5e7eb; color: #6b7280; font-size: 0.875rem;">
                <p>Created: \(document.createdAt.readableFormatted)</p>
                \(document.isFromURL && document.sourceUrl != nil ? "<p>Source: <a href=\"\(document.sourceUrl!)\">\(document.sourceUrl!)</a></p>" : "")
            </footer>
        </body>
        </html>
        """
    }

    /// Build HTML for multiple documents
    func buildMultiple(
        documents: [Document],
        highlightsMap: [String: [Highlight]]
    ) -> String {
        var allHTML = ""

        for (index, document) in documents.enumerated() {
            let highlights = highlightsMap[document.id] ?? []
            let htmlBody = convertMarkdownToHTML(document.content)
            let htmlWithHighlights = applyHighlights(to: htmlBody, highlights: highlights)

            allHTML += """
            <section class="document" id="document-\(index)">
                <h1 class="document-title">\(document.name)</h1>
                \(htmlWithHighlights)
            </section>

            """

            if index < documents.count - 1 {
                allHTML += "<hr class=\"document-separator\">\n"
            }
        }

        let css = theme.generateCSS() + """

        .document {
            margin-bottom: 3rem;
        }

        .document-title {
            border-bottom: 2px solid #e5e7eb;
            padding-bottom: 0.5rem;
            margin-bottom: 1.5rem;
        }

        .document-separator {
            border: none;
            border-top: 3px double #e5e7eb;
            margin: 3rem 0;
        }

        @media print {
            .document {
                page-break-after: always;
            }
        }
        """

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <meta name="generator" content="Markdown Studio iOS">
            <title>Markdown Studio Export</title>
            <style>
        \(css)
            </style>
        </head>
        <body>
        \(allHTML)
        </body>
        </html>
        """
    }

    // MARK: - Private Methods

    /// Convert markdown to HTML using swift-markdown
    private func convertMarkdownToHTML(_ markdown: String) -> String {
        let document = Document(parsing: markdown)
        let visitor = HTMLVisitor()
        return visitor.visit(document)
    }

    /// Apply highlight markup to HTML
    private func applyHighlights(to html: String, highlights: [Highlight]) -> String {
        // This is a simplified approach
        // In a real implementation, you'd parse the HTML and apply highlights more carefully
        var result = html

        // Sort highlights by position (reverse order to maintain offsets)
        let sortedHighlights = highlights.sorted { $0.rangeStart > $1.rangeStart }

        for highlight in sortedHighlights {
            guard let color = highlight.highlightColor else { continue }

            // Escape the text for HTML
            let escapedText = highlight.text
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")

            // Wrap in mark tag
            let markedText = "<mark class=\"highlight-\(color.rawValue)\">\(escapedText)</mark>"

            // Replace in HTML (simple string replacement)
            // Note: This is simplified - real implementation should parse HTML properly
            result = result.replacingOccurrences(of: escapedText, with: markedText)
        }

        return result
    }
}

// MARK: - HTML Visitor
/// Converts markdown AST to HTML
private class HTMLVisitor: MarkupVisitor {
    typealias Result = String

    private var listLevel = 0
    private var orderedListCounters: [Int] = []

    func defaultVisit(_ markup: Markup) -> String {
        var result = ""
        for child in markup.children {
            result += visit(child)
        }
        return result
    }

    func visitDocument(_ document: Document) -> String {
        var result = ""
        for child in document.children {
            result += visit(child)
        }
        return result
    }

    func visitHeading(_ heading: Heading) -> String {
        let level = heading.level
        let text = heading.plainText.escapedHTML()
        return "<h\(level)>\(text)</h\(level)>\n"
    }

    func visitParagraph(_ paragraph: Paragraph) -> String {
        var content = ""
        for child in paragraph.children {
            content += visit(child)
        }
        return "<p>\(content)</p>\n"
    }

    func visitText(_ text: Text) -> String {
        return text.string.escapedHTML()
    }

    func visitEmphasis(_ emphasis: Emphasis) -> String {
        var content = ""
        for child in emphasis.children {
            content += visit(child)
        }
        return "<em>\(content)</em>"
    }

    func visitStrong(_ strong: Strong) -> String {
        var content = ""
        for child in strong.children {
            content += visit(child)
        }
        return "<strong>\(content)</strong>"
    }

    func visitStrikethrough(_ strikethrough: Strikethrough) -> String {
        var content = ""
        for child in strikethrough.children {
            content += visit(child)
        }
        return "<del>\(content)</del>"
    }

    func visitLink(_ link: Link) -> String {
        let text = link.plainText.escapedHTML()
        let href = (link.destination ?? "").escapedHTML()
        return "<a href=\"\(href)\">\(text)</a>"
    }

    func visitInlineCode(_ inlineCode: InlineCode) -> String {
        let code = inlineCode.code.escapedHTML()
        return "<code>\(code)</code>"
    }

    func visitCodeBlock(_ codeBlock: CodeBlock) -> String {
        let code = codeBlock.code.escapedHTML()
        let language = codeBlock.language ?? ""
        return """
        <pre><code class="language-\(language)">\(code)</code></pre>
        """
    }

    func visitUnorderedList(_ unorderedList: UnorderedList) -> String {
        listLevel += 1
        var items = ""
        for item in unorderedList.listItems {
            items += visit(item)
        }
        listLevel -= 1
        return "<ul>\n\(items)</ul>\n"
    }

    func visitOrderedList(_ orderedList: OrderedList) -> String {
        listLevel += 1
        orderedListCounters.append(orderedList.startIndex)

        var items = ""
        for item in orderedList.listItems {
            items += visit(item)
        }

        orderedListCounters.removeLast()
        listLevel -= 1

        let start = orderedList.startIndex != 1 ? " start=\"\(orderedList.startIndex)\"" : ""
        return "<ol\(start)>\n\(items)</ol>\n"
    }

    func visitListItem(_ listItem: ListItem) -> String {
        var content = ""
        for child in listItem.children {
            content += visit(child)
        }
        return "<li>\(content)</li>\n"
    }

    func visitBlockQuote(_ blockQuote: BlockQuote) -> String {
        var content = ""
        for child in blockQuote.children {
            content += visit(child)
        }
        return "<blockquote>\n\(content)</blockquote>\n"
    }

    func visitLineBreak(_ lineBreak: LineBreak) -> String {
        return "<br>\n"
    }

    func visitSoftBreak(_ softBreak: SoftBreak) -> String {
        return "\n"
    }

    func visitThematicBreak(_ thematicBreak: ThematicBreak) -> String {
        return "<hr>\n"
    }

    func visitHTMLBlock(_ html: HTMLBlock) -> String {
        return html.rawHTML + "\n"
    }

    func visitInlineHTML(_ inlineHTML: InlineHTML) -> String {
        return inlineHTML.rawHTML
    }

    func visitImage(_ image: Image) -> String {
        let alt = image.plainText.escapedHTML()
        let src = (image.source ?? "").escapedHTML()
        let title = (image.title ?? "").escapedHTML()
        let titleAttr = title.isEmpty ? "" : " title=\"\(title)\""
        return "<img src=\"\(src)\" alt=\"\(alt)\"\(titleAttr)>"
    }

    func visitTable(_ table: Table) -> String {
        var html = "<table>\n"
        for child in table.children {
            html += visit(child)
        }
        html += "</table>\n"
        return html
    }

    func visitTableHead(_ tableHead: Table.Head) -> String {
        var html = "<thead>\n<tr>\n"
        for cell in tableHead.cells {
            html += "<th>" + visit(cell) + "</th>\n"
        }
        html += "</tr>\n</thead>\n"
        return html
    }

    func visitTableBody(_ tableBody: Table.Body) -> String {
        var html = "<tbody>\n"
        for row in tableBody.rows {
            html += visit(row)
        }
        html += "</tbody>\n"
        return html
    }

    func visitTableRow(_ tableRow: Table.Row) -> String {
        var html = "<tr>\n"
        for cell in tableRow.cells {
            html += "<td>" + visit(cell) + "</td>\n"
        }
        html += "</tr>\n"
        return html
    }

    func visitTableCell(_ tableCell: Table.Cell) -> String {
        var content = ""
        for child in tableCell.children {
            content += visit(child)
        }
        return content
    }
}

// MARK: - String Extensions for HTML
private extension String {
    func escapedHTML() -> String {
        return self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
