# Document data flow

This guide follows a document from ingestion (upload or URL import) through preview and export. It
focuses on the transformations, the reasons behind them, and the modules that perform each step.

## Core data model

- **`UploadedFile` (`lib/documents.ts`)** – canonical shape for every document once it enters the
  app. It stores a generated `id`, the sanitized `name`, raw markdown `content`, byte `size`, the
  `source` (`"upload" | "url"`), and timestamps. All pipeline stages accept this shape so uploads
  and URL imports behave identically.

## Upload ingestion path

1. **User interaction (`components/file-upload.tsx`)** – drag/drop or file picker returns a
   `FileList`. Non-markdown extensions and files over 10 MB are rejected early to keep the preview
   safe and responsive.
2. **File normalization (`createDocumentFromFile`)** – reads the file text, forces a markdown
   extension (`ensureMarkdownExtension`), generates a stable id prefixed with `upload-`, and records
   the byte size. This guarantees the rest of the pipeline always sees `.md` content with consistent
   metadata.
3. **State registration (`app/page.tsx`)** – `appendFiles` stores each `UploadedFile` in component
   state, selects the newest document (when appropriate), and persists the array to
   `localStorage` (keys: `markdown-studio-files`). During hydration `normalizeStoredFile` re-applies
   the same sanitation in case older cache entries predate current rules.
4. **Table of contents (`lib/markdown.tsx`)** – `extractHeadings` parses the markdown to build the
   sidebar outline as soon as the document becomes active.

## URL ingestion path

1. **User interaction (`components/url-import.tsx`)** – validates the entered URL and POSTs it to the
   `/api/fetch-url` route.
2. **Remote fetch (`app/api/fetch-url/route.ts`)** – streams the article with a browser-like
   `fetch`, strips scripts/styles/nav/aside chrome, then attempts to isolate `<main>`, `<article>`, or
   `<body>` to focus on primary content.
3. **Markdown conversion (Turndown)** – the cleaned HTML is passed through `TurndownService` (heading
   style: ATX, fenced code blocks, dash bullets) to produce markdown. We do this because the rest of
   the app assumes markdown input, so URL imports gain parity with uploaded `.md` files.
4. **Document creation (`createDocumentFromUrl`)** – wraps the markdown in an `UploadedFile`, ensuring
   the title becomes a sanitized `.md` filename, the byte length is measured, and the resolved URL is
   stored for traceability.
5. **State registration** – identical to the upload path via `appendFiles`, including persistence and
   table-of-contents generation.

## Shared preview pipeline

1. **Markdown → HTML (`convertMarkdownToHtml`)** – executed inside `components/preview-pane.tsx` for
   the selected document. The configured `markdown-it` instance enables inline HTML, smart
   typography, anchor links, footnotes, and task lists to maintain fidelity with GitHub-flavored
   markdown expectations.
2. **Theming (`getThemeStyles`)** – the preview injects CSS for the active theme (preset or custom),
   so the rendered document matches exported artifacts.
3. **Highlights (`ensureRangy` + `createHighlighter`)** – the preview loads Rangy once, attaches
   class-appliers for the curated highlight palette, and serializes selections. The serialized string and
   derived `HighlightDescriptor[]` sync back to `app/page.tsx` via `onHighlightsChange`, ensuring
   highlights persist per document across reloads.
4. **Experimental regex styling** – when the preview’s “Regex styling” toggle is enabled, the proof
   of concept scans rendered text nodes for punctuation-free lines containing the word “question”.
   Matches receive the `.pattern-question-emphasis` class so the team can evaluate automated styling
   ideas without mutating stored markdown.

## Export pipeline

1. **DOM capture (`components/export-panel.tsx`)** – retrieves the current preview HTML (including
   highlights and experimental styling) via the `preview-content-<id>` element.
2. **HTML export (`lib/export-html.tsx`)** – wraps the captured markup with theme styles, fonts, and
   metadata before prompting a download. We keep the preview DOM intact so what-you-see is what you
   export.
3. **PDF export (`lib/export-pdf.tsx`)** – hydrates a hidden iframe with the same template, then uses
   Playwright’s headless Chromium to generate PDFs in selectable sizes (A4, Letter, Legal). The
   highlighted/styled HTML travels unchanged, giving parity between HTML and PDF outputs.

## Why markdown remains canonical

- Highlights, TOC extraction, and exports all rely on markdown as the source of truth. Even when
  styling experiments (like regex-based emphasis) adjust the preview DOM, the stored markdown stays
  untouched so users can always return to the original content.
- Sanitizing filenames and keeping byte sizes ensures exported filenames and progress indicators are
  predictable across browsers and operating systems.
