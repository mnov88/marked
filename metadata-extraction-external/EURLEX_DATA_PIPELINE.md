# EUR-Lex Data Pipeline

Complete workflow for building the EUR-Lex database for the Markdowned iOS app.

---

## Quick Start

```bash
# If you already have JSON metadata files, just run:
python3 eurlex_db_import_simple.py \
  --metadata-root /Users/milos/Coding/eurlex-organized \
  --case-root /Users/milos/Coding/eurlex-organized/CASE_LAW \
  --output ./eurlex.db \
  --verbose

# Then copy to app bundle:
cp ./eurlex.db ../markdowned/eurlex.db
```

---

## Full Pipeline Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          EUR-LEX DATA PIPELINE                           │
└──────────────────────────────────────────────────────────────────────────┘

STEP 1: Seed CSV                    STEP 2: Download XML
┌────────────────────┐             ┌────────────────────┐
│  EUR-Lex Bulk      │             │  CELLAR API        │
│  FMX + RDF Files   │             │  (EU Publications) │
└─────────┬──────────┘             └─────────┬──────────┘
          │                                  │
          ▼                                  ▼
┌────────────────────┐  feeds    ┌────────────────────┐
│ eurlex_metadata_   │─────────► │ cellar_downloader_ │
│ extractor.py       │           │ cli.py             │
└─────────┬──────────┘           └─────────┬──────────┘
          │                                │
          ▼                                ▼
    eurlex_metadata_              cellar_tree_notice.xml
    enhanced.csv                  (per document folder)
    (24K CELEX + UUIDs)

STEP 3-4: Extract JSON             STEP 5: Build Database
┌────────────────────┐             ┌────────────────────┐
│ cellar_metadata_   │             │ eurlex_db_import_  │
│ extractor.py       │─────────►   │ simple.py          │
│ case_metadata_     │  JSON       │                    │
│ extractor.py       │  files      │                    │
└─────────┬──────────┘             └─────────┬──────────┘
          │                                  │
          ▼                                  ▼
    {CELEX}_metadata.json              eurlex.db
    {CELEX}_case_metadata.json         (46MB SQLite)

STEP 6: Bundle with App
┌────────────────────┐
│  iOS App Bundle    │
│  (read-only)       │
└────────────────────┘
```

---

## Step-by-Step Commands

### Step 1: Create Seed CSV (One-Time)

Extract CELEX identifiers and UUIDs from EUR-Lex bulk download.

```bash
python3 eurlex_metadata_extractor_enhanced.py \
  --fmx-root /path/to/LEG_EN_FMX_* \
  --rdf-root /path/to/LEG_MTD_*
```

**Output:** `eurlex_metadata_enhanced.csv` (~24K rows)

**Format:**
```csv
celex,uuid,doc_type,year
32016R0679,abc123-def456-...,REG,2016
32019L1937,xyz789-...,DIR,2019
```

---

### Step 2: Download CELLAR XML Notices

Download metadata XML files from EU CELLAR repository.

```bash
python3 cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /Users/milos/Coding/eurlex-organized \
  --workers 30 \
  --document-types REG DIR DEC
```

**Options:**
- `--workers 30` - Parallel downloads (adjust based on network)
- `--document-types REG DIR DEC` - Filter by document type
- `--years 2020 2021 2022` - Filter by year
- `--limit 100` - Test with small batch first

**Output:** Folder structure:
```
/eurlex-organized/
├── REG/
│   └── REG-2016-679/
│       ├── cellar_tree_notice.xml
│       └── 32016R0679_metadata.json (after Step 3)
├── DIR/
│   └── DIR-2019-1937/
│       └── ...
```

---

### Step 3: Extract Legislation Metadata

Parse CELLAR XML into structured JSON.

```bash
python3 cellar_metadata_extractor.py \
  --root /Users/milos/Coding/eurlex-organized \
  --verbose
```

**Output:** `{CELEX}_metadata.json` per document

**JSON Structure:**
```json
{
  "document": {
    "identifiers": {
      "celex": "32016R0679",
      "eli": "http://data.europa.eu/eli/reg/2016/679/oj",
      "resourceType": "REG"
    },
    "title": {
      "primary": "Regulation (EU) 2016/679 of the European Parliament...",
      "short": ["GDPR"],
      "multilingual": { "eng": [...], "fra": [...], "deu": [...] }
    },
    "dates": {
      "document": "2016-04-27",
      "entryIntoForce": "2018-05-25",
      "endOfValidity": "9999-12-31"
    },
    "metadata": {
      "inForce": "true",
      "createdBy": "European Parliament and Council",
      "subjectMatter": "Data protection"
    },
    "eurovoc": {
      "concepts": [
        { "id": "3456", "label": "data protection" },
        { "id": "1234", "label": "personal data" }
      ]
    },
    "caselaw": [...]
  }
}
```

---

### Step 4: Download & Extract Case Law (Optional)

Download case law that references your legislation.

```bash
# Download cases
python3 case_downloader.py \
  --from-legislation-root /Users/milos/Coding/eurlex-organized \
  --output /Users/milos/Coding/eurlex-organized/CASE_LAW

# Extract case metadata
python3 case_metadata_extractor.py \
  --root /Users/milos/Coding/eurlex-organized/CASE_LAW \
  --verbose
```

**Output:** `{CELEX}_case_metadata.json` per case

**JSON Structure:**
```json
{
  "case": {
    "identifiers": {
      "celex": "62015CJ0582",
      "ecli": ["ECLI:EU:C:2019:123"],
      "caseNumber": "C-582/15"
    },
    "title": {
      "multilingual": {
        "en": ["Judgment of the Court..."],
        "de": ["Urteil des Gerichtshofs..."]
      }
    },
    "court": {
      "name": "Court of Justice",
      "procedureType": "Reference for a preliminary ruling",
      "originCountry": "Germany"
    },
    "dates": {
      "judgment": "2019-07-29",
      "request": "2015-11-05"
    },
    "interpretedLegislation": [
      {
        "celex": "32016R0679",
        "articles": ["A5P1LA"],
        "parsedArticles": [
          {
            "raw": "A5P1LA",
            "parsed": "Article 5, Paragraph 1, Point (a)",
            "components": { "article": 5, "paragraph": 1, "point": "a" }
          }
        ]
      }
    ],
    "participants": {
      "advocatesGeneral": ["AG Name"]
    }
  }
}
```

---

### Step 5: Build Database

Convert JSON metadata into SQLite database.

```bash
python3 eurlex_db_import_simple.py \
  --metadata-root /Users/milos/Coding/eurlex-organized \
  --case-root /Users/milos/Coding/eurlex-organized/CASE_LAW \
  --output ./eurlex.db \
  --verbose
```

**Options:**
- `--metadata-root` (required) - Legislation JSON files
- `--case-root` (optional) - Case law JSON files
- `--output` (required) - Output SQLite path
- `--limit 100` - Process subset for testing
- `--verbose` - Show progress

**Output:**
```
Database created: ./eurlex.db
  Legislation: 21,675
  Case Law: 5,946
  Articles: 3,530
  Interpretations: 3,542
  Eurovoc Concepts: 4,541
```

---

### Step 6: Bundle with App

Copy database to iOS app bundle.

```bash
cp ./eurlex.db ../markdowned/eurlex.db
```

The app loads this as read-only reference data via `EurlexDatabaseManager`.

---

## Data Model Summary

### Input Data Flow

```
EUR-Lex Bulk Data
    │
    ├── FMX Files (full-text markup)
    │   └── Used to extract: CELEX, titles, dates
    │
    └── RDF Files (metadata)
        └── Used to extract: UUIDs, relationships, Eurovoc
            │
            ▼
        CELLAR XML
            │
            ├── cellar_tree_notice.xml (legislation)
            │   └── Contains: titles (multilingual), dates, eurovoc,
            │                 legal relations, case references
            │
            └── cellar_case_notice.xml (case law)
                └── Contains: titles, parties, court info,
                              interpreted legislation, article refs
```

### Output Database Schema

```
┌─────────────────────────────────────────────────────────────────────┐
│                           eurlex.db                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  legislation (21,675 rows)                                          │
│  ├── id, celex, eli, doc_type, doc_year, doc_number                │
│  ├── title, short_title                                             │
│  ├── date_document, date_in_force, date_end_validity, in_force     │
│  └── created_by, subject_matter, imported_at, updated_at           │
│                                                                     │
│  case_law (5,946 rows)                                              │
│  ├── id, celex, ecli, case_number                                  │
│  ├── title, short_title, parties                                    │
│  ├── court, procedure_type, origin_country                         │
│  ├── date_judgment, date_request                                    │
│  └── has_ag_opinion, ag_opinion_ecli                               │
│                                                                     │
│  article (3,530 rows)                                               │
│  ├── id, legislation_id                                             │
│  ├── article_num, paragraph_num, point                              │
│  └── display_text, raw_reference                                    │
│                                                                     │
│  case_article_interpretation (3,542 rows)                           │
│  ├── id, case_id, article_id                                        │
│  └── interpretation_type                                            │
│                                                                     │
│  eurovoc_concept (4,541 rows)                                       │
│  └── id, label, domain_id, domain_label                            │
│                                                                     │
│  legislation_eurovoc (many-to-many)                                 │
│  └── legislation_id, eurovoc_id                                     │
│                                                                     │
│  legislation_fts (FTS5 virtual table)                               │
│  case_law_fts (FTS5 virtual table)                                  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Title Extraction Logic

The import script uses cascade fallback to ensure no empty titles:

**Legislation:**
1. `document.title.primary` (if not "Not found")
2. `document.title.short[0]`
3. `document.title.multilingual.eng[0]`
4. First available language from multilingual
5. Fallback: `"Document {CELEX}"`

**Case Law:**
1. `case.title.multilingual.en[0]` (2-letter code)
2. `case.title.multilingual.eng[0]` (3-letter code)
3. Common EU languages: de, fr, es, it, nl, pt
4. Any available language
5. `case.identifiers.caseNumber`
6. Fallback: `"Case {CELEX}"`

---

## Article Reference Parsing

The script parses various article reference formats:

| Format | Example | Parsed |
|--------|---------|--------|
| Simple | `A5P1LA` | Article 5, Para 1, Point (a) |
| Formal | `Art. 5(1)(a)` | Article 5, Para 1, Point (a) |
| Recital | `C17` | Recital 17 |
| URI | `{AR\|...} 5 {PA\|...} 1` | Article 5, Para 1 |
| Number only | `5` | Article 5 |

---

## Performance Notes

| Metric | Value |
|--------|-------|
| Full import time | ~2 minutes |
| Database size | ~46MB |
| FTS5 index rebuild | ~5 seconds |
| Search latency (app) | <50ms |

---

## Troubleshooting

### Empty titles in database?

The old `eurlex_db_import.py` had a bug. Use `eurlex_db_import_simple.py` instead.

### Cases not linked to articles?

Cases must be processed **after** legislation. The script handles this automatically.

### FTS5 search not working?

Check that virtual tables exist:
```bash
sqlite3 eurlex.db ".tables"
# Should show: legislation_fts  case_law_fts
```

Rebuild if needed:
```sql
INSERT INTO legislation_fts(legislation_fts) VALUES('rebuild');
INSERT INTO case_law_fts(case_law_fts) VALUES('rebuild');
```

---

## File Reference

| File | Purpose |
|------|---------|
| `eurlex_metadata_extractor_enhanced.py` | Step 1: Create seed CSV |
| `cellar_downloader_cli.py` | Step 2: Download CELLAR XML |
| `cellar_metadata_extractor.py` | Step 3: Extract legislation JSON |
| `case_downloader.py` | Step 4a: Download case law |
| `case_metadata_extractor.py` | Step 4b: Extract case law JSON |
| `eurlex_db_import_simple.py` | Step 5: Build SQLite database |
| `eurlex_db_import.py` | (deprecated) Old complex importer |
| `CLI_QUICK_REFERENCE.md` | Quick reference for downloader |
| `EURLEX_DATA_PIPELINE.md` | This document |

---

## SwiftUI Integration

The database is used in the app via:

- **`EurlexDatabaseManager`** - Database connection and queries
- **`DBLegislation`** / **`DBCaseLaw`** - GRDB models
- **`MainNavigationView`** - Search UI with FTS5

See `DATABASE_SCHEMA.md` for full schema documentation.
