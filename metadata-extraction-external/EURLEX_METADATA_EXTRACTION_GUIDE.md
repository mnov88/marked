# EUR-Lex Metadata Extraction - Complete Guide

> **Purpose**: Centralized, AI-friendly documentation for extracting structured metadata from EU legislation and case law via the CELLAR repository.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Data Sources](#2-data-sources)
3. [Workflow Summary](#3-workflow-summary)
4. [Step 1: Seed List Creation](#4-step-1-seed-list-creation)
5. [Step 2: Download CELLAR XML Notices](#5-step-2-download-cellar-xml-notices)
6. [Step 3: Extract Legislation Metadata](#6-step-3-extract-legislation-metadata)
7. [Step 4: Case Law Enrichment](#7-step-4-case-law-enrichment)
8. [Complete Metadata Schemas](#8-complete-metadata-schemas)
9. [All Available Fields Reference](#9-all-available-fields-reference)
10. [Example Outputs](#10-example-outputs)
11. [Tools Reference](#11-tools-reference)
12. [Common Use Cases](#12-common-use-cases)

---

## 1. Overview

### What This System Does

This extraction pipeline retrieves and structures metadata from the **EU Publications Office CELLAR repository** for:

- **EU Legislation**: Regulations (REG), Directives (DIR), Decisions (DEC), and their implementing acts
- **EU Case Law**: Court of Justice (CJEU) judgments, opinions, and orders

### What You Get

| Data Type | Output Format | Key Fields |
|-----------|---------------|------------|
| **Legislation** | `{CELEX}_metadata.json` | Titles (24 languages), dates, identifiers, Eurovoc topics, legal relations, case law references |
| **Case Law** | `{CELEX}_case_metadata.json` | ECLI, parties, judges, interpreted legislation, article references, citations |

### Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           EUR-LEX DATA EXTRACTION                            │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐     ┌──────────────────┐     ┌──────────────────────────┐
│  EUR-Lex Bulk    │     │  CELLAR REST     │     │  Output                  │
│  Data Dump       │────▶│  API             │────▶│  Structured JSON         │
│  (FMX + RDF)     │     │  (Tree Notices)  │     │  per document            │
└──────────────────┘     └──────────────────┘     └──────────────────────────┘
        │                        │                         │
        ▼                        ▼                         ▼
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────────────┐
│ Create seed CSV  │     │ Download XML     │     │ Extract via XPath        │
│ with CELEX IDs   │     │ tree notices     │     │ to JSON schema           │
└──────────────────┘     └──────────────────┘     └──────────────────────────┘
```

---

## 2. Data Sources

### 2.1 EUR-Lex Bulk Data Dump

The EU Publications Office provides **free bulk data downloads** containing:

| Archive Type | Contents | Use |
|--------------|----------|-----|
| `LEG_EN_FMX_*` | FMX document XMLs (full text + structure) | Extract type/number/year/title |
| `LEG_MTD_*` | RDF metadata files | Extract CELEX, ELI, in-force status, Eurovoc |

**Download from**: [EU Open Data Portal](https://data.europa.eu/data/datasets) - search for "EUR-Lex"

### 2.2 CELLAR REST API

The **CELLAR repository** provides rich XML "tree notices" via REST API:

```
Base URL: http://publications.europa.eu/resource/cellar/{UUID}
Content-Type: application/xml;notice=tree
Accept-Language: eng (ISO 639-3)
```

**Key advantage**: CELLAR XML contains **20-40x more metadata** than basic RDF, including:
- All 24 EU language titles
- Full case law references with article citations
- Detailed Eurovoc classifications
- Complete legal relationship network

### 2.3 Data Richness Comparison

| Metadata Type | RDF Files | CELLAR Tree XML |
|---------------|-----------|-----------------|
| Case law references | 0-5 | **138+** (for GDPR) |
| Language versions | Limited | **All 24 EU languages** |
| Article citations | Basic | **Detailed with annotations** |
| Alternative titles | Some | **Full multilingual** |
| Typical file size | ~50 KB | 1-2 MB (much richer) |

---

## 3. Workflow Summary

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         COMPLETE WORKFLOW                                    │
└─────────────────────────────────────────────────────────────────────────────┘

Step 1: SEED LIST CREATION
    Input:  EUR-Lex bulk dump (FMX + RDF archives)
    Script: eurlex_metadata_extractor_enhanced.py
    Output: eurlex_metadata_enhanced.csv (CELEX IDs, types, years, UUIDs)

                              ▼

Step 2: DOWNLOAD CELLAR XMLs
    Input:  eurlex_metadata_enhanced.csv
    Script: cellar_downloader_cli.py (fastest) or cellar_downloader_fast.py (UI)
    Output: cellar_tree_notice.xml per document folder

                              ▼

Step 3: EXTRACT LEGISLATION METADATA
    Input:  cellar_tree_notice.xml files
    Script: cellar_metadata_extractor.py
    Config: cellar_xpath_config.json
    Output: {CELEX}_metadata.json per document

                              ▼

Step 4: CASE LAW ENRICHMENT (Optional)
    Input:  Case CELEX IDs from legislation metadata
    Script: case_downloader.py → case_metadata_extractor.py
    Config: case_xpath_config.json
    Output: {CELEX}_case_metadata.json per case
```

---

## 4. Step 1: Seed List Creation

### Purpose
Parse the EUR-Lex bulk data dump to create a CSV inventory of all available documents with their CELEX IDs and UUIDs.

### Script
```bash
python eurlex_metadata_extractor_enhanced.py \
  /path/to/LEG_EN_FMX_* \
  /path/to/LEG_MTD_*
```

### Input Files
- **FMX archives**: `LEG_EN_FMX_{timestamp}/{uuid}/fmx4/*.doc.xml`
- **RDF metadata**: `LEG_MTD_{timestamp}/{uuid}/tree_non_inferred.rdf`

### Output: `eurlex_metadata_enhanced.csv`

| Column | Description | Example |
|--------|-------------|---------|
| `celex` | CELEX identifier | `32016R0679` |
| `uuid` | CELLAR UUID | `0f4e43b0-3b34-11e6-afb6-01aa75ed71a1` |
| `type` | Document type code | `REG`, `DIR`, `DEC` |
| `year` | Document year | `2016` |
| `number` | Document number | `679` |
| `title` | Primary title | `Regulation (EU) 2016/679...` |
| `eli` | European Legislation Identifier | `http://data.europa.eu/eli/reg/2016/679/oj` |
| `in_force` | Currently in force | `true` / `false` |
| `proposed_filename` | Suggested folder name | `REG-2016-679` |

---

## 5. Step 2: Download CELLAR XML Notices

### Purpose
Fetch the comprehensive XML tree notices from CELLAR for each document in the seed list.

### Recommended Tool: CLI Downloader (Fastest)

```bash
python3 cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /path/to/eurlex-organized \
  --types REG DIR \
  --years 2020 2021 2022 \
  --workers 20 \
  --limit 1000
```

### CLI Options

| Option | Description | Default |
|--------|-------------|---------|
| `--csv` | Path to seed CSV | Required |
| `--output` | Output root directory | Required |
| `--types` | Filter by document types | All |
| `--years` | Filter by years | All |
| `--workers` | Concurrent download threads | 10 |
| `--limit` | Max documents to download | All |
| `--start` | Resume from index N | 0 |
| `--timeout` | Request timeout (seconds) | 30 |

### Alternative Tools

| Tool | Use Case | Speed |
|------|----------|-------|
| `cellar_downloader_cli.py` | Bulk downloads, scripting | **50-100 docs/sec** |
| `cellar_downloader_fast.py` | Interactive UI, monitoring | 10-15 docs/sec |
| `cellar_downloader_ui.py` | Safe, conservative | 1-2 docs/sec |

### Output Structure

```
/eurlex-organized/
├── REG/
│   ├── REG-2016-679/
│   │   ├── fmx4/                      # Original FMX files (if preserved)
│   │   └── cellar_tree_notice.xml     # Downloaded CELLAR XML
│   └── REG-2021-479/
│       └── cellar_tree_notice.xml
├── DIR/
│   └── DIR-2024-1234/
│       └── cellar_tree_notice.xml
└── DEC/
    └── ...
```

### Performance Benchmarks

| Documents | CLI (20 workers) | Streamlit Fast | Streamlit Standard |
|-----------|------------------|----------------|-------------------|
| 100 | ~10 sec | ~2 min | ~2 min |
| 1,000 | ~2 min | ~16 min | ~16 min |
| 24,000 (all) | ~50 min | ~6.5 hrs | ~13 hrs |

---

## 6. Step 3: Extract Legislation Metadata

### Purpose
Parse downloaded CELLAR XMLs and extract structured metadata into JSON files.

### Script

```bash
# Process all documents
python3 cellar_metadata_extractor.py \
  --root /path/to/eurlex-organized \
  --verbose

# Process single document
python3 cellar_metadata_extractor.py \
  --folder /path/to/eurlex-organized/REG/REG-2016-679

# Process with limit
python3 cellar_metadata_extractor.py \
  --root /path/to/eurlex-organized \
  --limit 100 \
  --verbose
```

### Configuration: `cellar_xpath_config.json`

The extraction is driven by XPath expressions defined in `cellar_xpath_config.json`:

```json
{
  "title": {
    "primary": "/NOTICE/EXPRESSION/EXPRESSION_TITLE/VALUE",
    "work": "//WORK_TITLE/VALUE",
    "alternative": "//EXPRESSION_TITLE_ALTERNATIVE/VALUE",
    "multilingual": "..."
  },
  "dates": {
    "document": "//WORK_DATE_DOCUMENT/VALUE",
    "publication": "//DATE_PUBLICATION/VALUE",
    "entryIntoForce": "//RESOURCE_LEGAL_DATE_ENTRY-INTO-FORCE/VALUE",
    "endOfValidity": "//RESOURCE_LEGAL_DATE_END-OF-VALIDITY/VALUE"
  },
  "identifiers": {
    "celex": "//ID_CELEX/VALUE",
    "eli": "//ELI/VALUE",
    "ojReference": "//SAMEAS[URI/TYPE='oj']/URI/IDENTIFIER"
  },
  "eurovoc": {
    "concept_id": "//WORK_IS_ABOUT_CONCEPT_EUROVOC/.../IDENTIFIER",
    "concept_label": "//WORK_IS_ABOUT_CONCEPT_EUROVOC/.../PREFLABEL"
  },
  "caselaw": {
    "interpreted_by": {
      "xpath": "//RESOURCE_LEGAL_INTERPRETED_BY_CASE-LAW",
      "celex": "./SAMEAS[URI/TYPE='celex']/URI/IDENTIFIER",
      "ecli": "./SAMEAS[URI/TYPE='ecli']/URI/IDENTIFIER",
      "articles": "./ANNOTATION/REFERENCE_TO_MODIFIED_LOCATION"
    }
  },
  "legalRelations": {
    "basedOn": "//BASED_ON/SAMEAS/URI/IDENTIFIER",
    "amends": "//RESOURCE_LEGAL_AMENDS_RESOURCE_LEGAL/SAMEAS/URI/IDENTIFIER",
    "repeals": "//RESOURCE_LEGAL_REPEALS_RESOURCE_LEGAL/SAMEAS/URI/IDENTIFIER"
  }
}
```

### Output: `{CELEX}_metadata.json`

Each document folder receives a structured JSON file. See [Section 8](#8-complete-metadata-schemas) for the full schema.

---

## 7. Step 4: Case Law Enrichment

### Purpose
Download and extract metadata for Court of Justice cases referenced by legislation.

### 7.1 Download Case Law Notices

```bash
# From legislation metadata (extracts case CELEX IDs automatically)
python3 case_downloader.py \
  --from-legislation-root /path/to/eurlex-organized \
  --output /path/to/case-cache \
  --workers 10 \
  --limit 100

# From explicit case list
python3 case_downloader.py \
  --cases-file cases.txt \
  --output /path/to/case-cache
```

### 7.2 Extract Case Metadata

```bash
python3 case_metadata_extractor.py \
  --root /path/to/case-cache \
  --verbose
```

### Configuration: `case_xpath_config.json`

```json
{
  "identifiers": {
    "ecli": "//ECLI/VALUE | //SAMEAS[URI/TYPE='ecli']/URI/IDENTIFIER",
    "celex": "//ID_CELEX/VALUE",
    "case_number": "//EXPRESSION_CASE-LAW_IDENTIFIER_CASE/VALUE"
  },
  "title_and_parties": {
    "title": "//EXPRESSION_TITLE/VALUE",
    "parties": "//EXPRESSION_CASE-LAW_PARTIES/VALUE"
  },
  "dates": {
    "judgment_date": "//WORK_DATE_DOCUMENT/VALUE",
    "request_date": "//RESOURCE_LEGAL_DATE_REQUEST_OPINION/VALUE"
  },
  "court_info": {
    "court": "//WORK_CREATED_BY_AGENT/PREFLABEL",
    "procedure_type": "//CASE-LAW_HAS_TYPE_PROCEDURE_CONCEPT_TYPE_PROCEDURE/PREFLABEL",
    "procedure_language": "//CASE-LAW_USES_PROCEDURE_LANGUAGE/PREFLABEL"
  },
  "interpreted_legislation": {
    "interpreted_celex": "//CASE-LAW_INTERPRETES_RESOURCE_LEGAL//SAMEAS[URI/TYPE='celex']/URI/IDENTIFIER",
    "interpreted_articles": "//CASE-LAW_INTERPRETES_RESOURCE_LEGAL//ANNOTATION/REFERENCE_TO_MODIFIED_LOCATION"
  },
  "judges_and_ag": {
    "judge_names": "//CASE-LAW_DELIVERED_BY_JUDGE/EMBEDDED_NOTICE/AGENT",
    "ag_names": "//CASE-LAW_DELIVERED_BY_ADVOCATE-GENERAL/EMBEDDED_NOTICE/AGENT"
  }
}
```

---

## 8. Complete Metadata Schemas

### 8.1 Legislation Metadata Schema (`*_metadata.json`)

```json
{
  "extraction_timestamp": "2024-07-01T12:00:00Z",
  "selected_language": "eng",
  "available_languages": ["bul", "ces", "dan", "deu", "ell", "eng", "est", "fin",
                         "fra", "gle", "hrv", "hun", "ita", "lav", "lit", "mlt",
                         "nld", "pol", "por", "ron", "slk", "slv", "spa", "swe"],

  "document": {
    "languages": ["bul", "ces", "..."],

    "title": {
      "primary": "Regulation (EU) 2016/679 of the European Parliament...",
      "work": "General Data Protection Regulation",
      "alternative": ["GDPR"],
      "subtitle": [],
      "short": ["GDPR"],
      "multilingual": {
        "eng": ["Regulation (EU) 2016/679..."],
        "fra": ["Règlement (UE) 2016/679..."],
        "deu": ["Verordnung (EU) 2016/679..."]
      }
    },

    "dates": {
      "document": "2016-04-27",
      "publication": "2016-05-04",
      "signature": "2016-04-27",
      "entryIntoForce": "2016-05-24",
      "endOfValidity": "9999-12-31",
      "transpositionDeadline": "2018-05-25"
    },

    "identifiers": {
      "celex": "32016R0679",
      "natural_number": "0679",
      "type": "R",
      "year": "2016",
      "sector": "3",
      "eli": "http://data.europa.eu/eli/reg/2016/679/oj",
      "ojReference": "JOL_2016_119_R_0001",
      "immc": ""
    },

    "eurovoc": {
      "concepts": [
        {"id": "5595", "label": "personal data", "language": "eng"},
        {"id": "3480", "label": "data protection", "language": "eng"}
      ],
      "domains": [
        {"id": "32", "label": "Education and communications", "language": "eng"}
      ],
      "microthesaurus": [],
      "terms": []
    },

    "caselaw": [
      {
        "celex": "62017CJ0673",
        "ecli": "ECLI:EU:C:2019:801",
        "articles": ["A04PT11", "A06P1LA"],
        "parsedArticles": [
          {
            "raw": "A04PT11",
            "parsed": "Article 4, Point 11",
            "type": "simple",
            "components": {"article": 4, "point": 11}
          },
          {
            "raw": "A06P1LA",
            "parsed": "Article 6, Paragraph 1",
            "type": "simple",
            "components": {"article": 6, "paragraph": 1}
          }
        ],
        "type": "Interpreted by"
      }
    ],

    "implementation": [
      {
        "identifier": "...",
        "country": "DE"
      }
    ],

    "legalRelations": {
      "basedOn": ["12012M/TXT", "treaty:tfeu_2016:art_16:oj"],
      "cites": ["32002L0058", "31995L0046"],
      "amends": [],
      "repeals": ["31995L0046"],
      "consolidatedBy": ["02016R0679-20180525"],
      "correctedBy": [],
      "treatyBasis": ["Treaty on the Functioning of the European Union"]
    },

    "metadata": {
      "createdBy": "European Parliament and Council",
      "responsibleAgent": "DG JUST",
      "inForce": "true",
      "subjectMatter": "Data protection",
      "dossierReference": "2012/0011(COD)",
      "version": "1.0",
      "lastModified": "2024-06-01",
      "directory_code": "13.10.10.00"
    }
  },

  "stats": {
    "languages": 24,
    "cases": 175,
    "eurovoc": 10,
    "articles": 659,
    "relations": 110,
    "implementations": 0
  }
}
```

### 8.2 Case Law Metadata Schema (`*_case_metadata.json`)

```json
{
  "extraction_timestamp": "2024-07-01T12:05:00Z",
  "selected_language": "eng",
  "available_languages": ["bul", "ces", "dan", "deu", "ell", "eng", "..."],

  "case": {
    "identifiers": {
      "celex": "62017CJ0673",
      "ecli": ["ECLI:EU:C:2019:801", "ECLI:EU:C:2019:26"],
      "caseNumber": "C-673/17",
      "cellarUri": "http://publications.europa.eu/resource/cellar/...",
      "nationalEcli": []
    },

    "title": {
      "multilingual": {
        "eng": ["Judgment of the Court (Grand Chamber) of 1 October 2019..."],
        "fra": ["Arrêt de la Cour (grande chambre) du 1 octobre 2019..."],
        "deu": ["Urteil des Gerichtshofs (Große Kammer) vom 1. Oktober 2019..."]
      },
      "short": ["Planet49"]
    },

    "parties": {
      "eng": ["Bundesverband der Verbraucherzentralen v Planet49 GmbH"],
      "deu": ["Bundesverband der Verbraucherzentralen gegen Planet49 GmbH"]
    },

    "dates": {
      "judgment": "2019-10-01",
      "request": "2017-12-21",
      "creation": "2019-10-01",
      "lastModified": "2024-06-01",
      "publication": "2019-10-15"
    },

    "court": {
      "name": "Court of Justice",
      "code": "CJEU",
      "procedureType": "Reference for a preliminary ruling",
      "procedureLanguage": "German",
      "originCountry": "Germany",
      "documentType": "Judgment"
    },

    "participants": {
      "judges": ["K. Lenaerts", "R. Silva de Lapuerta", "..."],
      "advocatesGeneral": ["M. Szpunar"]
    },

    "interpretedLegislation": [
      {
        "celex": "32016R0679",
        "articles": ["A04PT11", "A06P1LA"],
        "parsedArticles": [
          {
            "raw": "A04PT11",
            "parsed": "Article 4, Point 11",
            "type": "simple",
            "components": {"article": 4, "point": 11}
          }
        ],
        "type": "interprets"
      },
      {
        "celex": "32002L0058",
        "articles": ["A02FA", "A05P3"],
        "parsedArticles": [...]
      }
    ],

    "citations": {
      "celex": ["32002L0058", "32016R0679", "31995L0046"],
      "ecli": ["ECLI:EU:C:2017:994", "ECLI:EU:C:2016:779"],
      "works": ["http://publications.europa.eu/resource/celex/32002L0058"],
      "nationalJudgment": []
    },

    "subjectMatter": {
      "primary": ["Data protection", "Electronic communications"],
      "codes": ["13.10.10.00", "13.20.30.00"],
      "eurovoc": ["personal data", "consent", "cookies"]
    },

    "academicSources": [
      "Opinion of Advocate General Szpunar delivered on 21 March 2019"
    ],

    "metadata": {
      "sector": "6",
      "year": "2019",
      "version": "1.0",
      "publishedInErecueil": "true",
      "languages": ["eng", "deu", "fra"],
      "buildInfo": []
    }
  },

  "stats": {
    "languages": 9,
    "interpretedActs": 2,
    "citations": 5,
    "judges": 15,
    "advocatesGeneral": 1
  },

  "source_xml": "/path/to/case-cache/CASE/62017CJ0673/cellar_case_notice.xml"
}
```

---

## 9. All Available Fields Reference

### 9.1 Legislation Fields

#### Identifiers

| Field | XPath | Example | Notes |
|-------|-------|---------|-------|
| CELEX | `//ID_CELEX/VALUE` | `32016R0679` | Unique EU identifier |
| ELI | `//ELI/VALUE` | `http://data.europa.eu/eli/reg/2016/679/oj` | Permanent URI |
| OJ Reference | `//SAMEAS[URI/TYPE='oj']/URI/IDENTIFIER` | `JOL_2016_119_R_0001` | Official Journal ref |
| Natural Number | `//RESOURCE_LEGAL_NUMBER_NATURAL_CELEX/VALUE` | `0679` | Document number |
| Sector | `//ID_SECTOR/VALUE` | `3` | CELEX sector code |
| Type | `//RESOURCE_LEGAL_TYPE/VALUE` | `R` | R=Reg, L=Dir, D=Dec |
| Year | `//RESOURCE_LEGAL_YEAR/VALUE` | `2016` | Document year |

#### CELEX Format Explained

Format: `SYYYYTNNNN`
- **S** = Sector (3 = legislation, 6 = case law, 0 = consolidated)
- **YYYY** = Year
- **T** = Type (R = Regulation, L = Directive, D = Decision)
- **NNNN** = Sequential number

Examples:
- `32016R0679` = 2016 Regulation 679 (GDPR)
- `62017CJ0673` = 2017 Court of Justice case 673 (Planet49)
- `02016R0679-20180525` = Consolidated GDPR as of 2018-05-25

#### Dates

| Field | XPath | Format | Notes |
|-------|-------|--------|-------|
| Document date | `//WORK_DATE_DOCUMENT/VALUE` | YYYY-MM-DD | Official date |
| Publication | `//DATE_PUBLICATION/VALUE` | YYYY-MM-DD | OJ publication |
| Entry into force | `//RESOURCE_LEGAL_DATE_ENTRY-INTO-FORCE/VALUE` | YYYY-MM-DD | When binding |
| End of validity | `//RESOURCE_LEGAL_DATE_END-OF-VALIDITY/VALUE` | YYYY-MM-DD | `9999-12-31` = still valid |
| Signature | `//RESOURCE_LEGAL_DATE_SIGNATURE/VALUE` | YYYY-MM-DD | Signing date |
| Transposition deadline | `//RESOURCE_LEGAL_DATE_DEADLINE/VALUE` | YYYY-MM-DD | For directives |

#### Titles

| Field | XPath | Notes |
|-------|-------|-------|
| Primary title | `//EXPRESSION_TITLE/VALUE` | Main title in selected language |
| Work title | `//WORK_TITLE/VALUE` | Short/working title |
| Alternative | `//EXPRESSION_TITLE_ALTERNATIVE/VALUE` | Common names (e.g., "GDPR") |
| Short title | `//EXPRESSION_TITLE_SHORT/VALUE` | Abbreviated form |
| Subtitle | `//EXPRESSION_SUBTITLE/VALUE` | Additional title info |

#### Eurovoc Classifications

| Field | XPath | Notes |
|-------|-------|-------|
| Concept ID | `//WORK_IS_ABOUT_CONCEPT_EUROVOC/.../IDENTIFIER` | Eurovoc code |
| Concept Label | `//WORK_IS_ABOUT_CONCEPT_EUROVOC/.../PREFLABEL` | Human-readable term |
| Domain | `//WORK_IS_ABOUT_CONCEPT_EUROVOC_DOM/...` | Broader category |
| Microthesaurus | `//WORK_IS_ABOUT_CONCEPT_EUROVOC_MTH/...` | Detailed category |

#### Legal Relations

| Relation | XPath | Description |
|----------|-------|-------------|
| Based on | `//BASED_ON/SAMEAS/URI/IDENTIFIER` | Legal basis (treaties, etc.) |
| Cites | `//WORK_CITES_WORK/SAMEAS/URI/IDENTIFIER` | Referenced acts |
| Amends | `//RESOURCE_LEGAL_AMENDS_RESOURCE_LEGAL/...` | Acts this modifies |
| Repeals | `//RESOURCE_LEGAL_REPEALS_RESOURCE_LEGAL/...` | Acts this replaces |
| Consolidated by | `//RESOURCE_LEGAL_CONSOLIDATED_BY_ACT_CONSOLIDATED/...` | Consolidated versions |
| Corrected by | `//RESOURCE_LEGAL_CORRECTED_BY_RESOURCE_LEGAL/...` | Corrigenda |
| Treaty basis | `//RESOURCE_LEGAL_BASED_ON_CONCEPT_TREATY/PREFLABEL` | Treaty articles |

#### Case Law References (in Legislation)

| Relation Type | XPath | Notes |
|---------------|-------|-------|
| Interpreted by | `//RESOURCE_LEGAL_INTERPRETED_BY_CASE-LAW` | CJEU interpretations |
| Preliminary question | `//RESOURCE_LEGAL_PRELIMINARY_QUESTION-SUBMITTED_BY_...` | Preliminary rulings |
| Confirms | `//CASE-LAW_CONFIRMS_RESOURCE_LEGAL` | Confirmations |
| Declares valid | `//CASE-LAW_DECLARES_VALID_RESOURCE_LEGAL` | Validity rulings |
| Declares void | `//CASE-LAW_DECLARES_VOID_RESOURCE_LEGAL` | Nullity rulings |
| Amends | `//CASE-LAW_AMENDS_RESOURCE_LEGAL` | Case law amendments |
| Annulment requested | `//CASE-LAW_REQUESTS_ANNULMENT_OF_RESOURCE_LEGAL` | Annulment actions |

#### Article Reference Parsing

The system parses article references from case law into structured components:

**Simple Format**: `A58P5` → "Article 58, Paragraph 5"
- Pattern: `A{article}P{paragraph}` or `A{article}PT{point}`

**Complex URI Format**:
```
{AR|http://...} 23 {PA|http://...} 1 {PTA|http://...} (e)
→ "Article 23, Paragraph 1, Point (e)"
```

**Output Structure**:
```json
{
  "raw": "A58P5",
  "parsed": "Article 58, Paragraph 5",
  "type": "simple",
  "components": {
    "article": 58,
    "paragraph": 5
  }
}
```

### 9.2 Case Law Fields

#### Identifiers

| Field | XPath | Example |
|-------|-------|---------|
| ECLI | `//ECLI/VALUE` | `ECLI:EU:C:2019:801` |
| CELEX | `//ID_CELEX/VALUE` | `62017CJ0673` |
| Case number | `//EXPRESSION_CASE-LAW_IDENTIFIER_CASE/VALUE` | `C-673/17` |

#### Court Information

| Field | XPath | Example |
|-------|-------|---------|
| Court | `//WORK_CREATED_BY_AGENT/PREFLABEL` | `Court of Justice` |
| Procedure type | `//CASE-LAW_HAS_TYPE_PROCEDURE_CONCEPT_TYPE_PROCEDURE/PREFLABEL` | `Preliminary ruling` |
| Procedure language | `//CASE-LAW_USES_PROCEDURE_LANGUAGE/PREFLABEL` | `German` |
| Origin country | `//CASE-LAW_ORIGINATES_IN_COUNTRY/PREFLABEL` | `Germany` |

#### Participants

| Field | XPath | Notes |
|-------|-------|-------|
| Judges | `//CASE-LAW_DELIVERED_BY_JUDGE/EMBEDDED_NOTICE/AGENT` | List of judges |
| Advocates General | `//CASE-LAW_DELIVERED_BY_ADVOCATE-GENERAL/EMBEDDED_NOTICE/AGENT` | AG who gave opinion |
| Parties | `//EXPRESSION_CASE-LAW_PARTIES/VALUE` | Case parties |

#### Interpreted Legislation

| Field | XPath | Notes |
|-------|-------|-------|
| Interpreted CELEX | `//CASE-LAW_INTERPRETES_RESOURCE_LEGAL//SAMEAS[URI/TYPE='celex']/URI/IDENTIFIER` | Acts interpreted |
| Interpreted articles | `//CASE-LAW_INTERPRETES_RESOURCE_LEGAL//ANNOTATION/REFERENCE_TO_MODIFIED_LOCATION` | Specific articles |

---

## 10. Example Outputs

### 10.1 GDPR (Regulation 2016/679) - Legislation

```json
{
  "document": {
    "identifiers": {
      "celex": "32016R0679",
      "eli": "http://data.europa.eu/eli/reg/2016/679/oj"
    },
    "title": {
      "primary": "Regulation (EU) 2016/679 of the European Parliament and of the Council of 27 April 2016 on the protection of natural persons with regard to the processing of personal data...",
      "short": ["GDPR"]
    },
    "dates": {
      "document": "2016-04-27",
      "entryIntoForce": "2016-05-24",
      "endOfValidity": "9999-12-31"
    },
    "eurovoc": {
      "concepts": [
        {"id": "5595", "label": "personal data"},
        {"id": "3480", "label": "data protection"}
      ]
    },
    "caselaw": [
      {
        "celex": "62019CJ0645",
        "ecli": "ECLI:EU:C:2021:483",
        "articles": ["A66", "A61", "A62"],
        "type": "Interpreted by"
      }
    ]
  },
  "stats": {
    "languages": 24,
    "cases": 175,
    "eurovoc": 10,
    "articles": 659
  }
}
```

### 10.2 Planet49 Case (C-673/17) - Case Law

```json
{
  "case": {
    "identifiers": {
      "celex": "62017CJ0673",
      "ecli": ["ECLI:EU:C:2019:801"],
      "caseNumber": "C-673/17"
    },
    "title": {
      "short": ["Planet49"]
    },
    "court": {
      "name": "Court of Justice",
      "procedureType": "Reference for a preliminary ruling",
      "procedureLanguage": "German"
    },
    "participants": {
      "judges": ["K. Lenaerts"],
      "advocatesGeneral": ["M. Szpunar"]
    },
    "interpretedLegislation": [
      {
        "celex": "32016R0679",
        "articles": ["A04PT11", "A06P1LA"],
        "parsedArticles": [
          {"raw": "A04PT11", "parsed": "Article 4, Point 11"}
        ]
      }
    ],
    "dates": {
      "judgment": "2019-10-01"
    }
  }
}
```

---

## 11. Tools Reference

### Scripts Summary

| Script | Purpose | Input | Output |
|--------|---------|-------|--------|
| `eurlex_metadata_extractor_enhanced.py` | Create seed CSV from bulk dump | FMX + RDF archives | `eurlex_metadata_enhanced.csv` |
| `cellar_downloader_cli.py` | Download CELLAR XMLs (fastest) | Seed CSV | `cellar_tree_notice.xml` per doc |
| `cellar_downloader_fast.py` | Download with Streamlit UI | Seed CSV | `cellar_tree_notice.xml` per doc |
| `cellar_metadata_extractor.py` | Extract legislation metadata | CELLAR XMLs | `{CELEX}_metadata.json` |
| `cellar_metadata_extractor_ui.py` | Extract with Streamlit UI | CELLAR XMLs | `{CELEX}_metadata.json` |
| `case_downloader.py` | Download case law XMLs | Case CELEX list or legislation root | `cellar_case_notice.xml` |
| `case_metadata_extractor.py` | Extract case law metadata | Case XMLs | `{CELEX}_case_metadata.json` |

### Configuration Files

| File | Purpose |
|------|---------|
| `cellar_xpath_config.json` | XPath mappings for legislation extraction |
| `case_xpath_config.json` | XPath mappings for case law extraction |
| `eurlex_metadata_enhanced.csv` | Seed list of documents to process |

### Dependencies

```bash
pip3 install lxml tqdm requests streamlit
```

---

## 12. Common Use Cases

### Find all documents on a topic

```python
import json
from pathlib import Path

topic = "data protection"
results = []

for json_file in Path('/eurlex-organized').rglob('*_metadata.json'):
    with open(json_file) as f:
        data = json.load(f)
    concepts = [c['label'] for c in data['document']['eurovoc']['concepts']]
    if topic in ' '.join(concepts).lower():
        results.append({
            'celex': data['document']['identifiers']['celex'],
            'title': data['document']['title']['primary']
        })

print(f"Found {len(results)} documents about {topic}")
```

### Build legal relationship network

```python
import json
from pathlib import Path
from collections import defaultdict

# Build graph: document -> documents it amends
amendments = defaultdict(list)

for json_file in Path('/eurlex-organized').rglob('*_metadata.json'):
    with open(json_file) as f:
        data = json.load(f)
    celex = data['document']['identifiers']['celex']
    for amended in data['document']['legalRelations']['amends']:
        amendments[celex].append(amended)

print(f"Found {len(amendments)} documents that amend other acts")
```

### Extract all case law interpreting a regulation

```python
import json

with open('32016R0679_metadata.json') as f:
    gdpr = json.load(f)

cases = gdpr['document']['caselaw']
print(f"GDPR has been interpreted by {len(cases)} cases:")

for case in cases[:5]:
    print(f"  - {case['celex']} ({case.get('ecli', 'no ECLI')})")
    for art in case['parsedArticles'][:3]:
        print(f"    - {art['parsed']}")
```

### Get document title in all languages

```python
import json

with open('32016R0679_metadata.json') as f:
    data = json.load(f)

titles = data['document']['title']['multilingual']
for lang, title_list in titles.items():
    if title_list:
        print(f"{lang}: {title_list[0][:80]}...")
```

### Check document validity

```python
import json
from datetime import date

with open('32016R0679_metadata.json') as f:
    data = json.load(f)

end_validity = data['document']['dates']['endOfValidity']
in_force = data['document']['metadata']['inForce']

if end_validity == '9999-12-31' and in_force == 'true':
    print("Document is currently in force")
else:
    print(f"Document validity ends: {end_validity}")
```

---

## Quick Start Commands

```bash
# 1. Download CELLAR XMLs for 2020-2023 regulations
python3 cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /path/to/eurlex-organized \
  --types REG \
  --years 2020 2021 2022 2023 \
  --workers 20

# 2. Extract metadata from downloaded XMLs
python3 cellar_metadata_extractor.py \
  --root /path/to/eurlex-organized \
  --verbose

# 3. Download case law referenced by legislation
python3 case_downloader.py \
  --from-legislation-root /path/to/eurlex-organized \
  --output /path/to/case-cache \
  --workers 10

# 4. Extract case law metadata
python3 case_metadata_extractor.py \
  --root /path/to/case-cache \
  --verbose

# 5. Verify extraction (GDPR example)
cat /path/to/eurlex-organized/REG/REG-2016-679/32016R0679_metadata.json | \
  jq '.document.identifiers.celex, .document.dates.document, .stats'
```

---

**Last Updated**: December 2024
**Version**: 2.0
**Maintainer**: EUR-Lex Metadata Extraction Project
