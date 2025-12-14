# EUR-Lex Database Schema Proposals

> **Goal**: Support queries like "GDPR → which judgments interpret Article 5?"

This document proposes three schema levels: MVP, Standard, and Comprehensive. Each builds on the previous.

---

## Key Query Patterns to Support

| Query Type | Example | Priority |
|------------|---------|----------|
| **Article interpretation** | "Which cases interpret GDPR Article 5?" | P0 |
| **Case ↔ Legislation** | "What legislation does case C-673/17 interpret?" | P0 |
| **Legal relations** | "What amends GDPR?" / "What did GDPR repeal?" | P1 |
| **Topic search** | "All regulations about 'data protection'" | P1 |
| **Timeline** | "Cases interpreting GDPR by year" | P2 |
| **Network traversal** | "All acts 2 hops from GDPR" | P3 |

---

## Data Model Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ENTITY RELATIONSHIP DIAGRAM                          │
└─────────────────────────────────────────────────────────────────────────────┘

                              ┌──────────────┐
                              │   Eurovoc    │
                              │   Concept    │
                              └──────┬───────┘
                                     │ M:N
                                     │
┌──────────────┐    1:N    ┌─────────┴────────┐    M:N    ┌──────────────┐
│  Legislation │◄─────────▶│     Article      │◄─────────▶│     Case     │
│  (REG/DIR/   │           │  (within leg.)   │           │   (CJEU)     │
│   DEC)       │           └──────────────────┘           └──────────────┘
└──────┬───────┘                                                  │
       │ M:N (amends, cites, repeals, etc.)                      │
       └─────────────────────┬───────────────────────────────────┘
                             │
                    ┌────────┴────────┐
                    │ LegalRelation   │
                    │ (generic links) │
                    └─────────────────┘
```

---

## Proposal 1: MVP (Minimum Viable Product)

**Goal**: Get article-level case interpretation working with minimal tables.

### Schema

```sql
-- ============================================================================
-- MVP SCHEMA (4 tables + 1 junction)
-- ============================================================================

-- Core legislation documents (regulations, directives, decisions)
CREATE TABLE legislation (
    id              TEXT PRIMARY KEY,  -- UUID for internal use
    celex           TEXT NOT NULL UNIQUE,  -- e.g., "32016R0679"
    eli             TEXT,              -- e.g., "http://data.europa.eu/eli/reg/2016/679/oj"

    -- Classification
    doc_type        TEXT NOT NULL,     -- "REG", "DIR", "DEC", etc.
    doc_year        INTEGER NOT NULL,  -- 2016
    doc_number      INTEGER,           -- 679

    -- Title (store primary English, other langs can be separate or JSON)
    title           TEXT NOT NULL,
    short_title     TEXT,              -- e.g., "GDPR"

    -- Key dates
    date_document   TEXT,              -- "2016-04-27"
    date_in_force   TEXT,              -- "2016-05-24"
    date_end_validity TEXT,            -- "9999-12-31" means still valid

    -- Status
    in_force        INTEGER DEFAULT 1, -- boolean

    -- Metadata
    created_by      TEXT,              -- "European Parliament and Council"
    subject_matter  TEXT,              -- "Data protection"

    -- Timestamps
    imported_at     TEXT NOT NULL,
    updated_at      TEXT NOT NULL
);

CREATE INDEX idx_legislation_celex ON legislation(celex);
CREATE INDEX idx_legislation_type_year ON legislation(doc_type, doc_year);


-- EU Case Law (CJEU judgments, orders, opinions)
CREATE TABLE case_law (
    id              TEXT PRIMARY KEY,  -- UUID
    celex           TEXT NOT NULL UNIQUE,  -- e.g., "62017CJ0673"
    ecli            TEXT,              -- e.g., "ECLI:EU:C:2019:801"
    case_number     TEXT,              -- e.g., "C-673/17"

    -- Title
    title           TEXT,
    short_title     TEXT,              -- e.g., "Planet49"
    parties         TEXT,              -- "Bundesverband v Planet49 GmbH"

    -- Court info
    court           TEXT,              -- "Court of Justice"
    procedure_type  TEXT,              -- "Reference for a preliminary ruling"
    origin_country  TEXT,              -- "Germany"

    -- Key dates
    date_judgment   TEXT,              -- "2019-10-01"
    date_request    TEXT,              -- "2017-12-21"

    -- Metadata
    has_ag_opinion  INTEGER DEFAULT 0,
    ag_opinion_ecli TEXT,

    -- Timestamps
    imported_at     TEXT NOT NULL,
    updated_at      TEXT NOT NULL
);

CREATE INDEX idx_case_law_celex ON case_law(celex);
CREATE INDEX idx_case_law_ecli ON case_law(ecli);
CREATE INDEX idx_case_law_date ON case_law(date_judgment);


-- Articles within legislation (normalized from parsed references)
CREATE TABLE article (
    id              TEXT PRIMARY KEY,  -- UUID
    legislation_id  TEXT NOT NULL REFERENCES legislation(id) ON DELETE CASCADE,

    -- Article identification
    article_num     INTEGER NOT NULL,  -- e.g., 5
    paragraph_num   INTEGER,           -- e.g., 1 (NULL if whole article)
    point           TEXT,              -- e.g., "a" or "11"

    -- Display
    display_text    TEXT NOT NULL,     -- "Article 5, Paragraph 1, Point (a)"
    raw_reference   TEXT,              -- Original: "A05P1PTA"

    UNIQUE(legislation_id, article_num, paragraph_num, point)
);

CREATE INDEX idx_article_legislation ON article(legislation_id);
CREATE INDEX idx_article_num ON article(article_num);


-- Junction: Case interprets specific articles of legislation
CREATE TABLE case_article_interpretation (
    id              TEXT PRIMARY KEY,
    case_id         TEXT NOT NULL REFERENCES case_law(id) ON DELETE CASCADE,
    article_id      TEXT NOT NULL REFERENCES article(id) ON DELETE CASCADE,

    -- Interpretation type (for future use)
    interpretation_type TEXT DEFAULT 'interprets',  -- interprets, applies, etc.

    UNIQUE(case_id, article_id)
);

CREATE INDEX idx_cai_case ON case_article_interpretation(case_id);
CREATE INDEX idx_cai_article ON case_article_interpretation(article_id);
```

### Key Queries MVP Enables

```sql
-- QUERY: "Which cases interpret GDPR Article 5?"
SELECT cl.case_number, cl.short_title, cl.date_judgment, a.display_text
FROM case_law cl
JOIN case_article_interpretation cai ON cl.id = cai.case_id
JOIN article a ON cai.article_id = a.id
JOIN legislation l ON a.legislation_id = l.id
WHERE l.celex = '32016R0679'
  AND a.article_num = 5
ORDER BY cl.date_judgment;

-- QUERY: "What legislation does case C-673/17 interpret?"
SELECT l.celex, l.short_title, a.display_text
FROM legislation l
JOIN article a ON l.id = a.legislation_id
JOIN case_article_interpretation cai ON a.id = cai.article_id
JOIN case_law cl ON cai.case_id = cl.id
WHERE cl.case_number = 'C-673/17';

-- QUERY: "All cases for GDPR, grouped by article"
SELECT a.article_num, COUNT(DISTINCT cl.id) as case_count
FROM article a
JOIN case_article_interpretation cai ON a.id = cai.article_id
JOIN case_law cl ON cai.case_id = cl.id
JOIN legislation l ON a.legislation_id = l.id
WHERE l.celex = '32016R0679'
GROUP BY a.article_num
ORDER BY a.article_num;
```

### MVP Pros/Cons

| Pros | Cons |
|------|------|
| Simple, 4 tables | No legal relations (amends/repeals) |
| Covers core use case | No Eurovoc topics |
| Fast queries | Single language titles only |
| Easy to implement | No case citations |

---

## Proposal 2: Standard (Recommended)

**Goal**: Add legal relations, Eurovoc topics, and basic multilingual support.

### Additional Tables (on top of MVP)

```sql
-- ============================================================================
-- STANDARD SCHEMA ADDITIONS (MVP + 4 more tables)
-- ============================================================================

-- Legal relationships between legislation documents
CREATE TABLE legal_relation (
    id              TEXT PRIMARY KEY,
    source_id       TEXT NOT NULL REFERENCES legislation(id) ON DELETE CASCADE,
    target_celex    TEXT NOT NULL,     -- May reference non-imported docs
    target_id       TEXT REFERENCES legislation(id) ON DELETE SET NULL,  -- If imported

    -- Relation type
    relation_type   TEXT NOT NULL,     -- 'amends', 'repeals', 'cites', 'based_on',
                                       -- 'consolidated_by', 'corrected_by'

    UNIQUE(source_id, target_celex, relation_type)
);

CREATE INDEX idx_legal_relation_source ON legal_relation(source_id);
CREATE INDEX idx_legal_relation_target ON legal_relation(target_id);
CREATE INDEX idx_legal_relation_type ON legal_relation(relation_type);


-- Eurovoc controlled vocabulary concepts
CREATE TABLE eurovoc_concept (
    id              TEXT PRIMARY KEY,  -- Eurovoc ID, e.g., "5595"
    label           TEXT NOT NULL,     -- "personal data"
    domain_id       TEXT,
    domain_label    TEXT
);

CREATE INDEX idx_eurovoc_label ON eurovoc_concept(label);


-- Junction: Legislation tagged with Eurovoc concepts
CREATE TABLE legislation_eurovoc (
    legislation_id  TEXT NOT NULL REFERENCES legislation(id) ON DELETE CASCADE,
    eurovoc_id      TEXT NOT NULL REFERENCES eurovoc_concept(id) ON DELETE CASCADE,
    PRIMARY KEY (legislation_id, eurovoc_id)
);

CREATE INDEX idx_leg_eurovoc_leg ON legislation_eurovoc(legislation_id);
CREATE INDEX idx_leg_eurovoc_ev ON legislation_eurovoc(eurovoc_id);


-- Multilingual titles (optional, for key legislation)
CREATE TABLE legislation_title (
    id              TEXT PRIMARY KEY,
    legislation_id  TEXT NOT NULL REFERENCES legislation(id) ON DELETE CASCADE,
    language        TEXT NOT NULL,     -- ISO 639-3: "eng", "fra", "deu"
    title           TEXT NOT NULL,

    UNIQUE(legislation_id, language)
);

CREATE INDEX idx_leg_title_leg ON legislation_title(legislation_id);
CREATE INDEX idx_leg_title_lang ON legislation_title(language);


-- Case law citations (case cites other cases)
CREATE TABLE case_citation (
    id              TEXT PRIMARY KEY,
    citing_case_id  TEXT NOT NULL REFERENCES case_law(id) ON DELETE CASCADE,
    cited_celex     TEXT NOT NULL,     -- May not be imported
    cited_case_id   TEXT REFERENCES case_law(id) ON DELETE SET NULL,
    cited_ecli      TEXT,

    UNIQUE(citing_case_id, cited_celex)
);

CREATE INDEX idx_case_citation_citing ON case_citation(citing_case_id);
CREATE INDEX idx_case_citation_cited ON case_citation(cited_case_id);
```

### Additional Queries Standard Enables

```sql
-- QUERY: "What amends GDPR?"
SELECT l2.celex, l2.title, l2.date_document
FROM legislation l1
JOIN legal_relation lr ON l1.id = lr.target_id
JOIN legislation l2 ON lr.source_id = l2.id
WHERE l1.celex = '32016R0679'
  AND lr.relation_type = 'amends'
ORDER BY l2.date_document;

-- QUERY: "What did GDPR repeal?"
SELECT lr.target_celex, l2.title
FROM legislation l1
JOIN legal_relation lr ON l1.id = lr.source_id
LEFT JOIN legislation l2 ON lr.target_id = l2.id  -- May not be imported
WHERE l1.celex = '32016R0679'
  AND lr.relation_type = 'repeals';

-- QUERY: "All legislation about 'data protection'"
SELECT l.celex, l.title, l.date_document
FROM legislation l
JOIN legislation_eurovoc le ON l.id = le.legislation_id
JOIN eurovoc_concept ec ON le.eurovoc_id = ec.id
WHERE ec.label = 'data protection'
ORDER BY l.date_document DESC;

-- QUERY: "Topics covered by GDPR"
SELECT ec.label, ec.domain_label
FROM eurovoc_concept ec
JOIN legislation_eurovoc le ON ec.id = le.eurovoc_id
JOIN legislation l ON le.legislation_id = l.id
WHERE l.celex = '32016R0679';

-- QUERY: "Cases citing Planet49"
SELECT c2.case_number, c2.short_title, c2.date_judgment
FROM case_law c1
JOIN case_citation cc ON c1.id = cc.cited_case_id
JOIN case_law c2 ON cc.citing_case_id = c2.id
WHERE c1.short_title = 'Planet49';
```

### Standard Pros/Cons

| Pros | Cons |
|------|------|
| Full legal relations | More complex import |
| Topic-based search | ~8 tables to manage |
| Case citation network | Needs Eurovoc vocabulary |
| Multilingual support | Larger database |

---

## Proposal 3: Comprehensive

**Goal**: Full metadata storage for advanced analytics and complete provenance.

### Additional Tables (on top of Standard)

```sql
-- ============================================================================
-- COMPREHENSIVE SCHEMA ADDITIONS (Standard + advanced features)
-- ============================================================================

-- Full case participant information
CREATE TABLE case_participant (
    id              TEXT PRIMARY KEY,
    case_id         TEXT NOT NULL REFERENCES case_law(id) ON DELETE CASCADE,
    role            TEXT NOT NULL,     -- 'judge', 'advocate_general', 'party'
    name            TEXT NOT NULL,
    side            TEXT               -- 'applicant', 'defendant' for parties
);

CREATE INDEX idx_case_participant_case ON case_participant(case_id);
CREATE INDEX idx_case_participant_role ON case_participant(role);


-- Consolidated versions of legislation
CREATE TABLE consolidated_version (
    id              TEXT PRIMARY KEY,
    legislation_id  TEXT NOT NULL REFERENCES legislation(id) ON DELETE CASCADE,
    celex           TEXT NOT NULL,     -- e.g., "02016R0679-20180525"
    date_consolidated TEXT NOT NULL,   -- "2018-05-25"

    UNIQUE(legislation_id, date_consolidated)
);

CREATE INDEX idx_consolidated_leg ON consolidated_version(legislation_id);


-- National implementation measures (for Directives)
CREATE TABLE national_implementation (
    id              TEXT PRIMARY KEY,
    legislation_id  TEXT NOT NULL REFERENCES legislation(id) ON DELETE CASCADE,
    country_code    TEXT NOT NULL,     -- "DE", "FR", etc.
    measure_id      TEXT NOT NULL,     -- National identifier
    title           TEXT
);

CREATE INDEX idx_natl_impl_leg ON national_implementation(legislation_id);
CREATE INDEX idx_natl_impl_country ON national_implementation(country_code);


-- OJ Publication details
CREATE TABLE oj_publication (
    id              TEXT PRIMARY KEY,
    legislation_id  TEXT NOT NULL REFERENCES legislation(id) ON DELETE CASCADE,
    oj_reference    TEXT NOT NULL,     -- "JOL_2016_119_R_0001"
    oj_number       TEXT,
    oj_collection   TEXT,
    page_first      INTEGER,
    date_publication TEXT
);


-- Article full text (if needed later)
CREATE TABLE article_text (
    id              TEXT PRIMARY KEY,
    article_id      TEXT NOT NULL REFERENCES article(id) ON DELETE CASCADE,
    language        TEXT NOT NULL,     -- "eng"
    text_content    TEXT NOT NULL,     -- Full article text

    UNIQUE(article_id, language)
);


-- Import/sync tracking
CREATE TABLE import_log (
    id              TEXT PRIMARY KEY,
    entity_type     TEXT NOT NULL,     -- 'legislation', 'case_law'
    entity_id       TEXT NOT NULL,
    celex           TEXT NOT NULL,
    source_file     TEXT,              -- JSON filename
    imported_at     TEXT NOT NULL,
    status          TEXT NOT NULL,     -- 'success', 'partial', 'failed'
    error_message   TEXT
);

CREATE INDEX idx_import_log_celex ON import_log(celex);
CREATE INDEX idx_import_log_status ON import_log(status);


-- FTS5 full-text search (extending existing pattern)
CREATE VIRTUAL TABLE legislation_fts USING fts5(
    celex,
    title,
    short_title,
    subject_matter,
    content='legislation',
    content_rowid='rowid'
);

CREATE VIRTUAL TABLE case_law_fts USING fts5(
    celex,
    ecli,
    case_number,
    title,
    short_title,
    parties,
    content='case_law',
    content_rowid='rowid'
);
```

### Comprehensive View Queries

```sql
-- VIEW: Legislation with all interpretations (denormalized for UI)
CREATE VIEW v_legislation_interpretations AS
SELECT
    l.celex,
    l.title,
    l.short_title,
    a.article_num,
    a.paragraph_num,
    a.display_text as article_display,
    cl.case_number,
    cl.short_title as case_short_title,
    cl.date_judgment,
    cl.ecli
FROM legislation l
JOIN article a ON l.id = a.legislation_id
JOIN case_article_interpretation cai ON a.id = cai.article_id
JOIN case_law cl ON cai.case_id = cl.id;

-- QUERY: "Complete interpretation map for GDPR"
SELECT * FROM v_legislation_interpretations
WHERE celex = '32016R0679'
ORDER BY article_num, paragraph_num, date_judgment;

-- VIEW: Legal network for graph visualization
CREATE VIEW v_legal_network AS
SELECT
    l1.celex as source_celex,
    l1.title as source_title,
    lr.relation_type,
    lr.target_celex,
    l2.title as target_title,
    l2.id IS NOT NULL as target_imported
FROM legislation l1
JOIN legal_relation lr ON l1.id = lr.source_id
LEFT JOIN legislation l2 ON lr.target_id = l2.id;

-- QUERY: "Full network 2 hops from GDPR"
WITH RECURSIVE network AS (
    SELECT celex, 0 as depth FROM legislation WHERE celex = '32016R0679'
    UNION
    SELECT lr.target_celex, n.depth + 1
    FROM network n
    JOIN legislation l ON n.celex = l.celex
    JOIN legal_relation lr ON l.id = lr.source_id
    WHERE n.depth < 2
)
SELECT DISTINCT celex, depth FROM network ORDER BY depth, celex;
```

---

## Schema Comparison Summary

| Feature | MVP | Standard | Comprehensive |
|---------|-----|----------|---------------|
| **Tables** | 4 | 8 | 14+ |
| **Article interpretation** | ✅ | ✅ | ✅ |
| **Case ↔ Legislation** | ✅ | ✅ | ✅ |
| **Legal relations** | ❌ | ✅ | ✅ |
| **Eurovoc topics** | ❌ | ✅ | ✅ |
| **Multilingual titles** | ❌ | ✅ | ✅ |
| **Case citations** | ❌ | ✅ | ✅ |
| **Judges/AG names** | ❌ | ❌ | ✅ |
| **Consolidated versions** | ❌ | ❌ | ✅ |
| **National implementations** | ❌ | ❌ | ✅ |
| **Full-text search** | ❌ | ❌ | ✅ |
| **Import tracking** | ❌ | ❌ | ✅ |

---

## Recommendation: Start with Standard

**Why Standard is the sweet spot:**

1. **Covers 90% of use cases** - Article interpretation + legal relations + topics
2. **Reasonable complexity** - 8 tables vs 14+
3. **Aligns with extracted data** - All fields exist in JSON
4. **Future-proof** - Easy to add Comprehensive tables later
5. **Good query performance** - Proper indexes, reasonable joins

**Migration path:**
```
MVP (week 1) → Standard (week 2-3) → Comprehensive (as needed)
```

---

## GRDB/Swift Implementation Notes

The existing app uses GRDB with this pattern:

```swift
// Example: Article record for GRDB
struct DBArticle: Identifiable, Codable, FetchableRecord, PersistableRecord {
    var id: String
    var legislationId: String
    var articleNum: Int
    var paragraphNum: Int?
    var point: String?
    var displayText: String
    var rawReference: String?

    static var databaseTableName: String { "article" }

    // Foreign key association
    static let legislation = belongsTo(DBLegislation.self)
    static let interpretations = hasMany(DBCaseArticleInterpretation.self)
}

// Query: Cases interpreting GDPR Article 5
let gdprArticle5Cases = try dbQueue.read { db in
    try DBCaseLaw
        .joining(required: DBCaseLaw.interpretations
            .joining(required: DBCaseArticleInterpretation.article
                .filter(DBArticle.Columns.articleNum == 5)
                .joining(required: DBArticle.legislation
                    .filter(DBLegislation.Columns.celex == "32016R0679"))))
        .order(DBCaseLaw.Columns.dateJudgment)
        .fetchAll(db)
}
```

---

## Data Import Strategy

### Import Script: `eurlex_db_import.py`

A complete import script is available that reads JSON metadata and exports to **three formats**:

```bash
# Export all formats (SQLite + CSV + JSON)
python3 eurlex_db_import.py \
  --metadata-root /path/to/eurlex-organized \
  --output-dir ./output \
  --format all \
  --verbose

# SQLite only (for app bundling)
python3 eurlex_db_import.py \
  --metadata-root /path/to/eurlex-organized \
  --output-dir ./output \
  --format sqlite

# CSV only (for pandas, R, external tools)
python3 eurlex_db_import.py \
  --metadata-root /path/to/eurlex-organized \
  --output-dir ./output \
  --format csv

# Include case law metadata
python3 eurlex_db_import.py \
  --metadata-root /path/to/eurlex-organized \
  --case-root /path/to/case-cache \
  --output-dir ./output
```

### Output Files

```
output/
├── eurlex.db              # SQLite database (Standard schema)
├── eurlex_export.json     # Single JSON with all tables
└── csv/
    ├── legislation.csv
    ├── case_law.csv
    ├── article.csv
    ├── case_article_interpretation.csv
    ├── legal_relation.csv
    ├── eurovoc_concept.csv
    ├── legislation_eurovoc.csv
    ├── legislation_title.csv
    └── case_citation.csv
```

### Script Options

| Option | Description |
|--------|-------------|
| `--metadata-root` | Root directory with `*_metadata.json` files |
| `--case-root` | Optional: directory with `*_case_metadata.json` |
| `--output-dir` | Where to write output files |
| `--format` | `all`, `sqlite`, `csv`, or `json` |
| `--limit` | Process only N files (for testing) |
| `--verbose` | Show detailed progress |

### Import Logic (How It Works)

```python
# Simplified logic from eurlex_db_import.py
def import_legislation(json_path):
    data = json.load(json_path)
    doc = data['document']

    # 1. Insert legislation
    leg_id = insert_legislation(
        celex=doc['identifiers']['celex'],
        title=doc['title']['primary'],
        ...
    )

    # 2. Insert articles from case law references
    for case_ref in doc['caselaw']:
        for parsed_art in case_ref['parsedArticles']:
            art_id = upsert_article(
                legislation_id=leg_id,
                article_num=parsed_art['components']['article'],
                paragraph_num=parsed_art['components'].get('paragraph'),
                display_text=parsed_art['parsed']
            )

            # 3. Insert case if not exists
            case_id = upsert_case(celex=case_ref['celex'], ecli=case_ref.get('ecli'))

            # 4. Link case to article
            insert_interpretation(case_id=case_id, article_id=art_id)

    # 5. Insert legal relations
    for rel_type, targets in doc['legalRelations'].items():
        for target in targets:
            insert_relation(source_id=leg_id, target_celex=target, type=rel_type)
```

---

## Example: GDPR Query Results

### "Which cases interpret GDPR Article 5?"

```
┌─────────────────┬────────────────────┬────────────────┬────────────────────────────┐
│ case_number     │ short_title        │ date_judgment  │ article_display            │
├─────────────────┼────────────────────┼────────────────┼────────────────────────────┤
│ C-673/17        │ Planet49           │ 2019-10-01     │ Article 5, Paragraph 1     │
│ C-311/18        │ Schrems II         │ 2020-07-16     │ Article 5                  │
│ C-645/19        │ Facebook Ireland   │ 2021-06-15     │ Article 5, Paragraph 1, a  │
│ C-252/21        │ Meta Platforms     │ 2023-07-04     │ Article 5, Paragraph 1     │
└─────────────────┴────────────────────┴────────────────┴────────────────────────────┘
```

### "Legal relations network from GDPR"

```
GDPR (32016R0679)
├── REPEALS
│   └── 31995L0046 (Data Protection Directive 95/46/EC)
├── BASED ON
│   ├── 12016E016 (TFEU Art. 16)
│   └── 12016P/TXT (Charter of Fundamental Rights)
├── CITED BY
│   ├── 32018R1725 (EU institutions data protection)
│   └── 32019R0881 (Cybersecurity Act)
└── AMENDED BY
    └── (none yet)
```

---

## Next Steps

1. **Choose schema level** (recommend: Standard)
2. **Add migration to DatabaseManager.swift**
3. **Create GRDB record types** (DBLegislation, DBCaseLaw, etc.)
4. **Build import script** (Python → JSON → SQLite)
5. **Add UI for browsing** legislation/cases

---

**Document Version**: 1.0
**Created**: December 2024
**For**: Markdowned EUR-Lex Integration
