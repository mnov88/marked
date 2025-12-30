# EUR-Lex Database Schema Documentation

## Overview

This document describes the SQLite database schema for EUR-Lex legal document metadata used in the Markdowned iOS/macOS app. The schema supports legislation documents, EU case law, article-level interpretations, and Eurovoc classifications.

**Schema Version:** `simplified_v2`
**Generated From:** `eurlex_db_import_simple.py`
**Database Format:** SQLite 3 with FTS5
**Typical Size:** ~46MB (21K legislation, 6K cases)

---

## Data Pipeline Overview

```
EUR-Lex Bulk Data (FMX/RDF)
         │
         ▼
┌─────────────────────────────────┐
│ eurlex_metadata_extractor.py   │  Step 1: Create seed CSV
└─────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ cellar_downloader_cli.py       │  Step 2: Download CELLAR XML
└─────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ cellar_metadata_extractor.py   │  Step 3: Extract legislation JSON
│ case_metadata_extractor.py     │  Step 4: Extract case law JSON
└─────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ eurlex_db_import_simple.py     │  Step 5: Build SQLite database
└─────────────────────────────────┘
         │
         ▼
    eurlex.db → iOS App Bundle
```

---

## Table of Contents

1. [legislation](#1-legislation) - Core legislation documents
2. [case_law](#2-case_law) - EU Case Law
3. [article](#3-article) - Articles within legislation
4. [case_article_interpretation](#4-case_article_interpretation) - Case interpretations of articles
5. [eurovoc_concept](#5-eurovoc_concept) - Eurovoc thesaurus concepts
6. [legislation_eurovoc](#6-legislation_eurovoc) - Legislation-Eurovoc links
7. [legislation_fts](#7-legislation_fts-fts5-virtual-table) - FTS5 full-text search for legislation
8. [case_law_fts](#8-case_law_fts-fts5-virtual-table) - FTS5 full-text search for cases

---

## 1. legislation

**Description:** Core legislation documents including regulations, directives, decisions, and other EU legal acts.

**Swift Model:** `DBLegislation` in `markdowned/DBLegislation.swift`

### Fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique UUID identifier |
| `celex` | TEXT | NOT NULL, UNIQUE | CELEX identifier (e.g., `32016R0679`) |
| `eli` | TEXT | | European Legislation Identifier |
| `doc_type` | TEXT | NOT NULL | Document type (REG, DIR, DEC, etc.) |
| `doc_year` | INTEGER | NOT NULL | Year of document |
| `doc_number` | INTEGER | | Sequential document number |
| `title` | TEXT | NOT NULL | Primary title (English) |
| `short_title` | TEXT | | Abbreviated title if available |
| `date_document` | TEXT | | Date of document (ISO 8601) |
| `date_in_force` | TEXT | | Entry into force date |
| `date_end_validity` | TEXT | | End of validity date |
| `in_force` | INTEGER | DEFAULT 1 | Boolean: 1 = in force, 0 = repealed |
| `created_by` | TEXT | | Originating institution |
| `subject_matter` | TEXT | | Subject matter classification |
| `imported_at` | TEXT | NOT NULL | Import timestamp (ISO 8601) |
| `updated_at` | TEXT | NOT NULL | Last update timestamp |

### Document Types

| Code | Description | Swift Enum |
|------|-------------|------------|
| REG | Regulation | `.regulation` |
| DIR | Directive | `.directive` |
| DEC | Decision | `.decision` |
| REG-IMPL | Implementing Regulation | `.regulationImpl` |
| DEC-IMPL | Implementing Decision | `.decisionImpl` |
| REG-DEL | Delegated Regulation | `.regulationDel` |
| DEC-DEL | Delegated Decision | `.decisionDel` |

### Indexes

- `idx_legislation_celex` on `celex`
- `idx_legislation_doc_type` on `doc_type`
- `idx_legislation_doc_year` on `doc_year`

---

## 2. case_law

**Description:** EU Court of Justice and General Court case law, including judgments and opinions.

**Swift Model:** `DBCaseLaw` in `markdowned/DBCaseLaw.swift`

### Fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique UUID identifier |
| `celex` | TEXT | NOT NULL, UNIQUE | CELEX identifier (e.g., `62015CJ0582`) |
| `ecli` | TEXT | | European Case Law Identifier |
| `case_number` | TEXT | | Case reference number (e.g., `C-582/15`) |
| `title` | TEXT | | Case title |
| `short_title` | TEXT | | Short case name |
| `parties` | TEXT | | Party names |
| `court` | TEXT | | Court name (Court of Justice, General Court) |
| `procedure_type` | TEXT | | Type of procedure (e.g., "Reference for a preliminary ruling") |
| `origin_country` | TEXT | | Referring country (for preliminary rulings) |
| `date_judgment` | TEXT | | Judgment date (ISO 8601) |
| `date_request` | TEXT | | Request/application date |
| `has_ag_opinion` | INTEGER | DEFAULT 0 | Boolean: has Advocate General opinion |
| `ag_opinion_ecli` | TEXT | | ECLI of AG opinion if separate |
| `imported_at` | TEXT | NOT NULL | Import timestamp |
| `updated_at` | TEXT | NOT NULL | Last update timestamp |

### CELEX Format for Cases

Format: `6YYYYXXNNNN`
- `6` = Case law sector
- `YYYY` = Year
- `XX` = Court code (CJ=Court of Justice, CA=Appeals, TJ=General Court)
- `NNNN` = Case number

### Indexes

- `idx_case_law_celex` on `celex`

---

## 3. article

**Description:** Structured references to specific articles, paragraphs, and points within legislation.

**Swift Model:** `DBArticle` in `markdowned/DBEurlexRelations.swift`

### Fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique UUID identifier |
| `legislation_id` | TEXT | NOT NULL | References `legislation(id)` |
| `article_num` | INTEGER | NOT NULL | Article number |
| `paragraph_num` | INTEGER | | Paragraph number (optional) |
| `point` | TEXT | | Point/subpoint identifier (e.g., "a", "i") |
| `display_text` | TEXT | NOT NULL | Human-readable reference (e.g., "Article 9, Paragraph 2") |
| `raw_reference` | TEXT | | Original unparsed reference string |
| **UNIQUE** | | | `(legislation_id, article_num, paragraph_num, point)` |

### Indexes

- `idx_article_legislation` on `legislation_id`

---

## 4. case_article_interpretation

**Description:** Links EU case law to specific articles of legislation that are interpreted, cited, or referenced.

**Swift Model:** `DBCaseArticleInterpretation` in `markdowned/DBEurlexRelations.swift`

### Fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique UUID identifier |
| `case_id` | TEXT | NOT NULL | References `case_law(id)` |
| `article_id` | TEXT | NOT NULL | References `article(id)` |
| `interpretation_type` | TEXT | DEFAULT 'interprets' | Type: `interprets`, `preliminary_question`, `interpreted_by` |
| **UNIQUE** | | | `(case_id, article_id)` |

### Indexes

- `idx_interpretation_case` on `case_id`
- `idx_interpretation_article` on `article_id`

---

## 5. eurovoc_concept

**Description:** Eurovoc thesaurus concepts for subject matter classification.

**Swift Model:** `DBEurovocConcept` in `markdowned/DBEurlexRelations.swift`

### Fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Eurovoc concept ID |
| `label` | TEXT | NOT NULL, UNIQUE | Concept label (English) |
| `domain_id` | TEXT | | Domain/microthesaurus ID |
| `domain_label` | TEXT | | Domain label |

---

## 6. legislation_eurovoc

**Description:** Many-to-many relationship linking legislation to Eurovoc concepts.

**Swift Model:** `DBLegislationEurovoc` in `markdowned/DBEurlexRelations.swift`

### Fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `legislation_id` | TEXT | PRIMARY KEY | References `legislation(id)` |
| `eurovoc_id` | TEXT | PRIMARY KEY | References `eurovoc_concept(id)` |

---

## 7. legislation_fts (FTS5 Virtual Table)

**Description:** Full-text search index for legislation using SQLite FTS5 with BM25 ranking.

### Configuration

```sql
CREATE VIRTUAL TABLE legislation_fts USING fts5(
    celex, eli, title, short_title, subject_matter, created_by,
    content=legislation, content_rowid=rowid, tokenize='unicode61'
);
```

### Features

- **BM25 Ranking:** Relevance scoring (more negative = better match)
- **Snippet Generation:** Context highlighting with `snippet()` function
- **Prefix Matching:** Partial word search with `*` operator
- **Unicode Support:** `unicode61` tokenizer for EU language support

---

## 8. case_law_fts (FTS5 Virtual Table)

**Description:** Full-text search index for case law using SQLite FTS5 with BM25 ranking.

### Configuration

```sql
CREATE VIRTUAL TABLE case_law_fts USING fts5(
    celex, ecli, case_number, title, short_title, parties, court,
    content=case_law, content_rowid=rowid, tokenize='unicode61'
);
```

---

## Entity Relationship Diagram

```
┌─────────────────┐
│   legislation   │
└────────┬────────┘
         │
         │ 1:N
         ▼
    ┌─────────┐
    │ article │
    └────┬────┘
         │
         │ N:M via case_article_interpretation
         ▼
   ┌──────────┐
   │ case_law │
   └──────────┘

┌──────────────────┐       ┌────────────────────┐
│ eurovoc_concept  │◄─────►│ legislation_eurovoc│──► legislation
└──────────────────┘       └────────────────────┘
```

---

## Data Statistics (Production)

| Table | Count |
|-------|-------|
| Legislation | 21,675 |
| Case Law | 5,946 |
| Articles | 3,530 |
| Case-Article Interpretations | 3,542 |
| Eurovoc Concepts | 4,541 |
| **Database Size** | **~46MB** |

---

## Usage in SwiftUI App

### Manager

`EurlexDatabaseManager` in `markdowned/EurlexDatabaseManager.swift`

### Key Methods

```swift
// Search
func search(query: String, limit: Int) async throws -> [CaseLawSearchResult]
func searchLegislation(query: String, limit: Int) async throws -> [LegislationSearchResult]

// Fetch by ID
func fetchCase(byCelex: String) async throws -> DBCaseLaw?
func fetchLegislation(byCelex: String) async throws -> DBLegislation?

// Relationships
func fetchInterpretedArticles(forCase: DBCaseLaw) async throws -> [DBArticle]
func fetchCasesInterpreting(articleNum: Int, legislationCelex: String) async throws -> [DBCaseLaw]
func fetchEurovocConcepts(for: DBLegislation) async throws -> [DBEurovocConcept]
```

### Search Example (SwiftUI)

```swift
// In MainNavigationView.swift
let results = try await eurlexManager.search(query: searchText, limit: 50)
// Returns CaseLawSearchResult with: caseLaw, rank (BM25), snippet
```

---

## Import Command

```bash
python3 eurlex_db_import_simple.py \
  --metadata-root /Users/milos/Coding/eurlex-organized \
  --case-root /Users/milos/Coding/eurlex-organized/CASE_LAW \
  --output ./eurlex.db \
  --verbose
```

---

## Changelog

**Version 2.0** (2025-12-29)
- Simplified schema: 6 core tables + 2 FTS5 virtual tables
- Removed `legal_relation`, `case_citation`, `legislation_title` tables (not used in UI)
- New import script: `eurlex_db_import_simple.py` (520 lines vs 1028 lines)
- Fixed title extraction with cascade fallback (0 empty titles)
- Database size reduced to ~46MB

**Version 1.1** (2025-12-27)
- Added FTS5 virtual tables for full-text search

**Version 1.0** (2025-12-18)
- Initial schema documentation

---

## References

- **EUR-Lex:** https://eur-lex.europa.eu
- **CELEX Format:** https://eur-lex.europa.eu/content/tools/TableOfSectors/types_of_documents_in_eurlex.html
- **Eurovoc:** https://op.europa.eu/en/web/eu-vocabularies/th-concept-scheme/-/resource/eurovoc
- **ECLI:** https://e-justice.europa.eu/content_european_case_law_identifier_ecli-175-en.do
