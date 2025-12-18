# EUR-Lex Database Schema Documentation

## Overview

This document describes the relational database schema for EUR-Lex legal document metadata. The schema supports legislation documents, EU case law, legal relationships, Eurovoc classifications, and article-level interpretations.

**Schema Version:** `standard_v1`  
**Generated From:** `eurlex_db_import.py`  
**Database Format:** SQLite 3  
**Export Formats:** SQLite (`.db`), CSV (per table), JSON (combined)

---

## Table of Contents

1. [legislation](#1-legislation) - Core legislation documents
2. [case_law](#2-case_law) - EU Case Law
3. [article](#3-article) - Articles within legislation
4. [case_article_interpretation](#4-case_article_interpretation) - Case interpretations of articles
5. [legal_relation](#5-legal_relation) - Legal relationships between legislation
6. [eurovoc_concept](#6-eurovoc_concept) - Eurovoc thesaurus concepts
7. [legislation_eurovoc](#7-legislation_eurovoc) - Legislation-Eurovoc links
8. [legislation_title](#8-legislation_title) - Multilingual titles
9. [case_citation](#9-case_citation) - Case-to-case citations

---

## 1. legislation

**Description:** Core legislation documents including regulations, directives, decisions, and other EU legal acts.

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
| `date_end_validity` | TEXT | | End of validity date (`9999-12-31` for active) |
| `in_force` | INTEGER | DEFAULT 1 | Boolean: 1 = in force, 0 = repealed |
| `created_by` | TEXT | | Originating institution |
| `subject_matter` | TEXT | | Subject matter classification |
| `imported_at` | TEXT | NOT NULL | Import timestamp (ISO 8601) |
| `updated_at` | TEXT | NOT NULL | Last update timestamp |

### Indexes

- `idx_legislation_celex` on `celex`
- `idx_legislation_type_year` on `doc_type, doc_year`

### Sample Rows

| id | celex | doc_type | doc_year | title | date_document | in_force |
|----|-------|----------|----------|-------|---------------|----------|
| 0c8f42c4-21a8-44ed-acbe-b8e6dc5e7e92 | 32010L0006 | DIR | 2010 | Commission Directive 2010/6/EU of 9 February 2010 amending Annex I to Directive 2002/32/EC... | 2010-02-09 | 1 |
| 916b4294-cb19-4b62-a27d-4cb1947bc7b8 | 32010L0088 | DIR | 2010 | Council Directive 2010/88/EU of 7 December 2010 amending Directive 2006/112/EC... | 2010-12-07 | 1 |

---

## 2. case_law

**Description:** EU Court of Justice and General Court case law, including judgments and opinions.

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
| `court` | TEXT | | Court name (CJEU, General Court) |
| `procedure_type` | TEXT | | Type of procedure |
| `origin_country` | TEXT | | Referring country (for preliminary rulings) |
| `date_judgment` | TEXT | | Judgment date (ISO 8601) |
| `date_request` | TEXT | | Request/application date |
| `has_ag_opinion` | INTEGER | DEFAULT 0 | Boolean: has Advocate General opinion |
| `ag_opinion_ecli` | TEXT | | ECLI of AG opinion if separate |
| `imported_at` | TEXT | NOT NULL | Import timestamp |
| `updated_at` | TEXT | NOT NULL | Last update timestamp |

### Indexes

- `idx_case_law_celex` on `celex`
- `idx_case_law_ecli` on `ecli`
- `idx_case_law_date` on `date_judgment`

### Sample Rows

| id | celex | ecli | case_number | has_ag_opinion |
|----|-------|------|-------------|----------------|
| 0897e610-f360-4d68-a7a4-f3799dc405b8 | 62025CN0328 | | | 0 |
| 16c0d7d6-f0a8-4c75-a937-7acb07771179 | 62022CJ0395 | ECLI:EU:C:2024:374 | | 0 |

---

## 3. article

**Description:** Structured references to specific articles, paragraphs, and points within legislation.

### Fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique UUID identifier |
| `legislation_id` | TEXT | NOT NULL, FOREIGN KEY | References `legislation(id)` |
| `article_num` | INTEGER | NOT NULL | Article number |
| `paragraph_num` | INTEGER | | Paragraph number (optional) |
| `point` | TEXT | | Point/subpoint identifier (e.g., "a", "i") |
| `display_text` | TEXT | NOT NULL | Human-readable reference (e.g., "Article 9, Paragraph 2") |
| `raw_reference` | TEXT | | Original unparsed reference string |
| **UNIQUE** | | | `(legislation_id, article_num, paragraph_num, point)` |

### Indexes

- `idx_article_legislation` on `legislation_id`
- `idx_article_num` on `article_num`

### Sample Rows

| id | legislation_id | article_num | paragraph_num | point | display_text | raw_reference |
|----|----------------|-------------|---------------|-------|--------------|---------------|
| ab8111db-cbdc-42e4-8df1-784ce921607a | d3d6adfb-702c-4912-adee-515b5f4cf411 | 9 | | | Article 9 | {CONSID...} 9 |
| b61433e8-054a-4ad8-beb4-a1fd7132e1df | e7ad99c1-f2b7-4d58-96ee-2187f8de6eeb | 3 | | | Article 3 | A03 |

---

## 4. case_article_interpretation

**Description:** Links EU case law to specific articles of legislation that are interpreted, cited, or referenced.

### Fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique UUID identifier |
| `case_id` | TEXT | NOT NULL, FOREIGN KEY | References `case_law(id)` |
| `article_id` | TEXT | NOT NULL, FOREIGN KEY | References `article(id)` |
| `interpretation_type` | TEXT | DEFAULT 'interprets' | Type: `interprets`, `preliminary_question`, `interpreted_by` |
| **UNIQUE** | | | `(case_id, article_id)` |

### Indexes

- `idx_cai_case` on `case_id`
- `idx_cai_article` on `article_id`

### Sample Rows

| id | case_id | article_id | interpretation_type |
|----|---------|------------|---------------------|
| ad586682-afa8-4b84-a968-1fe6b04e592f | 0897e610-f360-4d68-a7a4-f3799dc405b8 | ab8111db-cbdc-42e4-8df1-784ce921607a | preliminary_question |
| 3503d5dc-7175-4545-94b4-22b1216d2576 | 16c0d7d6-f0a8-4c75-a937-7acb07771179 | b61433e8-054a-4ad8-beb4-a1fd7132e1df | interpreted_by |

---

## 5. legal_relation

**Description:** Legal relationships between legislation documents (amendments, repeals, consolidations, etc.).

### Fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique UUID identifier |
| `source_id` | TEXT | NOT NULL, FOREIGN KEY | Source legislation ID (references `legislation(id)`) |
| `target_celex` | TEXT | NOT NULL | Target document CELEX |
| `target_id` | TEXT | FOREIGN KEY | Target legislation ID if imported (references `legislation(id)`) |
| `relation_type` | TEXT | NOT NULL | Relation type (see below) |
| **UNIQUE** | | | `(source_id, target_celex, relation_type)` |

**Relation Types:**
- `based_on` - Legal basis
- `cites` - General citation
- `amends` - Amendment
- `repeals` - Repeal/abrogation
- `consolidated_by` - Consolidated version
- `corrected_by` - Corrigendum
- `treaty_basis` - Treaty article basis

### Indexes

- `idx_legal_relation_source` on `source_id`
- `idx_legal_relation_target` on `target_id`
- `idx_legal_relation_type` on `relation_type`

### Sample Rows

| id | source_id | target_celex | relation_type |
|----|-----------|--------------|---------------|
| 035de24f-b04b-4438-8367-ac263ebbff4d | 0c8f42c4-21a8-44ed-acbe-b8e6dc5e7e92 | 32002L0032 | based_on |
| a4f8e6e3-85e7-4d8d-bdfd-caf7b085f6df | 0c8f42c4-21a8-44ed-acbe-b8e6dc5e7e92 | JOL_2002_140_R_0010_01 | based_on |

---

## 6. eurovoc_concept

**Description:** Eurovoc thesaurus concepts for subject matter classification.

### Fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Eurovoc concept ID |
| `label` | TEXT | NOT NULL | Concept label (English) |
| `domain_id` | TEXT | | Domain/microthesaurus ID |
| `domain_label` | TEXT | | Domain label |

### Indexes

- `idx_eurovoc_label` on `label`

### Sample Rows

| id | label | domain_id | domain_label |
|----|-------|-----------|--------------|
| 5877 | animal health | | |
| 1277 | animal nutrition | | |

---

## 7. legislation_eurovoc

**Description:** Many-to-many relationship linking legislation to Eurovoc concepts.

### Fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `legislation_id` | TEXT | PRIMARY KEY, FOREIGN KEY | References `legislation(id)` |
| `eurovoc_id` | TEXT | PRIMARY KEY, FOREIGN KEY | References `eurovoc_concept(id)` |

### Indexes

- `idx_leg_eurovoc_leg` on `legislation_id`
- `idx_leg_eurovoc_ev` on `eurovoc_id`

### Sample Rows

| legislation_id | eurovoc_id |
|----------------|------------|
| 0c8f42c4-21a8-44ed-acbe-b8e6dc5e7e92 | 5877 |
| 0c8f42c4-21a8-44ed-acbe-b8e6dc5e7e92 | 1277 |

---

## 8. legislation_title

**Description:** Multilingual titles for legislation (top 5 EU languages: English, French, German, Spanish, Italian).

### Fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique UUID identifier |
| `legislation_id` | TEXT | NOT NULL, FOREIGN KEY | References `legislation(id)` |
| `language` | TEXT | NOT NULL | ISO 639-2 code (`eng`, `fra`, `deu`, `spa`, `ita`) |
| `title` | TEXT | NOT NULL | Title in specified language |
| **UNIQUE** | | | `(legislation_id, language)` |

### Indexes

- `idx_leg_title_leg` on `legislation_id`

### Sample Rows

| id | legislation_id | language | title |
|----|----------------|----------|-------|
| d3b33f48-32db-4b88-bdb8-ed2d3d2a4e92 | 0c8f42c4-21a8-44ed-acbe-b8e6dc5e7e92 | eng | Commission Directive 2010/6/EU of 9 February 2010... |
| 18ebbc37-7f7b-4953-a70a-5e70acb5c50b | 0c8f42c4-21a8-44ed-acbe-b8e6dc5e7e92 | fra | Directive 2010/6/UE de la Commission du 9 février 2010... |

---

## 9. case_citation

**Description:** Citations between cases (case-to-case references in judgments).

### Fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique UUID identifier |
| `citing_case_id` | TEXT | NOT NULL, FOREIGN KEY | Citing case ID (references `case_law(id)`) |
| `cited_celex` | TEXT | NOT NULL | CELEX of cited case |
| `cited_case_id` | TEXT | FOREIGN KEY | Cited case ID if imported (references `case_law(id)`) |
| `cited_ecli` | TEXT | | ECLI of cited case |
| **UNIQUE** | | | `(citing_case_id, cited_celex)` |

### Indexes

- `idx_case_citation_citing` on `citing_case_id`
- `idx_case_citation_cited` on `cited_case_id`

### Sample Rows

| id | citing_case_id | cited_celex | cited_case_id | cited_ecli |
|----|----------------|-------------|---------------|------------|
| 21c1a854-bbf3-4c50-9006-478216339adf | cb0556f2-a882-4c9b-abcd-453de4ad996e | 12008E267 | | |
| 61018bc6-70db-4720-bfe7-ae5f2e9409d4 | cb0556f2-a882-4c9b-abcd-453de4ad996e | 62009CJ0261 | | |

---

## Schema Diagram (Entity Relationships)

```
┌─────────────────┐
│   legislation   │◄──┐
└─────────────────┘   │
         │            │
         ├───────────►│ legal_relation (self-referencing)
         │            │
         ▼            │
    ┌─────────┐      │
    │ article │      │
    └─────────┘      │
         │           │
         ▼           │
┌────────────────────────────┐
│ case_article_interpretation│
└────────────────────────────┘
         │
         ▼
   ┌──────────┐
   │ case_law │◄────────────┐
   └──────────┘             │
         │                  │
         └──────────────────┘ case_citation (self-referencing)

   ┌──────────────────┐
   │ eurovoc_concept  │
   └──────────────────┘
            │
            ▼
   ┌────────────────────┐
   │ legislation_eurovoc│ (join table)
   └────────────────────┘
            │
            ▼
      legislation

   ┌────────────────────┐
   │ legislation_title  │
   └────────────────────┘
            │
            ▼
      legislation
```

---

## Data Statistics (Sample Dataset)

- **Legislation:** ~893 documents
- **Case Law:** ~5,948 cases
- **Articles:** ~341 parsed articles
- **Interpretations:** ~1,009 case-article links
- **Legal Relations:** ~14,965 relationships
- **Eurovoc Concepts:** ~1,479 concepts
- **Multilingual Titles:** ~4,461 translations
- **Case Citations:** ~32,106 citations

---

## Usage Examples

### Query 1: Find all cases interpreting GDPR Article 6

```sql
SELECT 
  c.celex,
  c.case_number,
  c.date_judgment,
  a.display_text
FROM 
  case_law c
JOIN 
  case_article_interpretation cai ON c.id = cai.case_id
JOIN 
  article a ON cai.article_id = a.id
JOIN 
  legislation l ON a.legislation_id = l.id
WHERE 
  l.celex = '32016R0679'
  AND a.article_num = 6;
```

### Query 2: Find all legislation that amends a specific regulation

```sql
SELECT 
  l.celex,
  l.title,
  l.date_document
FROM 
  legislation l
JOIN 
  legal_relation lr ON l.id = lr.source_id
WHERE 
  lr.target_celex = '32016R0679'
  AND lr.relation_type = 'amends'
ORDER BY 
  l.date_document DESC;
```

### Query 3: Get all Eurovoc subject classifications for a document

```sql
SELECT 
  l.celex,
  l.title,
  ec.label AS eurovoc_label
FROM 
  legislation l
JOIN 
  legislation_eurovoc le ON l.id = le.legislation_id
JOIN 
  eurovoc_concept ec ON le.eurovoc_id = ec.id
WHERE 
  l.celex = '32010L0006';
```

### Query 4: Find most cited cases

```sql
SELECT 
  c.celex,
  c.case_number,
  COUNT(cc.id) AS citation_count
FROM 
  case_law c
JOIN 
  case_citation cc ON c.id = cc.cited_case_id
GROUP BY 
  c.id, c.celex, c.case_number
ORDER BY 
  citation_count DESC
LIMIT 10;
```

---

## Import & Export

### Import Command

```bash
python3 eurlex_db_import.py \
  --metadata-root /path/to/eurlex-organized \
  --case-root /path/to/case-cache \
  --output-dir ./output \
  --format all
```

### Export Formats

1. **SQLite Database:** `output/eurlex.db`
2. **CSV Files:** `output/csv/{table_name}.csv`
3. **JSON Export:** `output/eurlex_export.json`

### Filtering Options

```bash
# Import only Regulations and Directives
python3 eurlex_db_import.py \
  --metadata-root /path/to/eurlex-organized \
  --output-dir ./output \
  --types REG DIR

# Limit to 100 files for testing
python3 eurlex_db_import.py \
  --metadata-root /path/to/eurlex-organized \
  --output-dir ./output \
  --limit 100
```

---

## Notes

- **UUID Format:** All primary keys use UUID v4 format
- **Date Format:** ISO 8601 (`YYYY-MM-DD` or `YYYY-MM-DDTHH:MM:SS.mmmmmm`)
- **Active Documents:** Use `date_end_validity = '9999-12-31'` for documents still in force
- **Foreign Key Handling:** Target references may be NULL if referenced document not imported
- **Case Sensitivity:** CELEX IDs are case-sensitive; use exact format from EUR-Lex
- **Deduplication:** Enforced via UNIQUE constraints on natural keys (CELEX, article components)

---

## Changelog

**Version 1.0** (2025-12-18)
- Initial schema documentation
- 9 tables with full relational integrity
- Support for legislation, case law, and cross-references
- Eurovoc classification support
- Multilingual title support (5 languages)

---

## References

- **EUR-Lex:** https://eur-lex.europa.eu
- **CELEX Format:** https://eur-lex.europa.eu/content/tools/TableOfSectors/types_of_documents_in_eurlex.html
- **Eurovoc:** https://op.europa.eu/en/web/eu-vocabularies/th-concept-scheme/-/resource/eurovoc
- **ECLI:** https://e-justice.europa.eu/content_european_case_law_identifier_ecli-175-en.do

---

*Generated from `eurlex_db_import.py` schema definition.*

