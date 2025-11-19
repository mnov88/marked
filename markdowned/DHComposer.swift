
import SwiftUI
import UIKit
import Combine



// MARK: - Composer

struct DHComposer {
    // Compose once per render. Callers should cache link/indent spans.
    static func compose(
        base: NSAttributedString,
        config: DHConfig,
        links: [DHLinkSpan],
        indents: [DHIndentSpan],
        highlights: [DHTextHighlight]
    ) -> NSAttributedString {
        let out = NSMutableAttributedString(attributedString: base)
        let full = NSRange(location: 0, length: out.length)

        // Base style
        let p = NSMutableParagraphStyle()
        if config.style.lineHeightMultiple > 0 { p.lineHeightMultiple = config.style.lineHeightMultiple }
        p.paragraphSpacing = config.style.paragraphSpacing
        p.alignment = config.style.alignment
        p.lineBreakStrategy = config.style.lineBreakStrategy

        out.addAttributes([
            .font: config.style.font,
            .foregroundColor: config.style.textColor,
            .paragraphStyle: p
        ], range: full)

        // Indentation
        for ind in indents {
            guard ind.range.location >= 0,
                  NSMaxRange(ind.range) <= out.length else { continue }
            let ps = (out.attribute(.paragraphStyle, at: ind.range.location, effectiveRange: nil) as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle ?? p.mutableCopy() as! NSMutableParagraphStyle
            ps.headIndent = ind.headIndent
            ps.tailIndent = ind.tailIndent
            ps.firstLineHeadIndent = ind.firstLineHeadIndent
            out.addAttribute(.paragraphStyle, value: ps, range: ind.range)
        }

        // Links via .link attribute
        for l in links {
            guard l.range.location >= 0,
                  NSMaxRange(l.range) <= out.length else { continue }
            out.addAttribute(.link, value: l.url, range: l.range)
            out.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: l.range)
            out.addAttribute(.foregroundColor, value: UIColor.link, range: l.range)
        }

        // Highlights: background only to avoid clobbering link underline
        for h in highlights {
            guard h.range.location >= 0,
                  NSMaxRange(h.range) <= out.length else { continue }
            out.addAttributes([
                .backgroundColor: h.color.withAlphaComponent(0.25)
            ], range: h.range)
        }

        return out
    }
}
