# EUR-Lex Metadata Extraction Tools

Extract structured metadata from EU legislation and case law via the CELLAR repository.

## Quick Start

```bash
# 1. Download CELLAR XMLs
python3 cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /path/to/eurlex-organized \
  --types REG --years 2020 2021 \
  --workers 20

# 2. Extract metadata to JSON
python3 cellar_metadata_extractor.py \
  --root /path/to/eurlex-organized \
  --verbose

# 3. Build database (SQLite + CSV + JSON)
python3 eurlex_db_import.py \
  --metadata-root /path/to/eurlex-organized \
  --output-dir ./output \
  --format all
```

## Documentation

| Document | Purpose |
|----------|---------|
| **[EURLEX_METADATA_EXTRACTION_GUIDE.md](EURLEX_METADATA_EXTRACTION_GUIDE.md)** | Complete guide: workflow, schemas, all fields, examples |
| **[DATABASE_SCHEMA_PROPOSALS.md](DATABASE_SCHEMA_PROPOSALS.md)** | Database schemas (MVP → Standard → Comprehensive) |
| **[METADATA_QUICK_REFERENCE.md](METADATA_QUICK_REFERENCE.md)** | Field lookup tables, Python snippets |
| **[CLI_QUICK_REFERENCE.md](CLI_QUICK_REFERENCE.md)** | CLI downloader command reference |

## Tools

| Script | Purpose |
|--------|---------|
| `cellar_downloader_cli.py` | Download CELLAR XMLs (fastest, threaded) |
| `cellar_downloader_fast.py` | Download with Streamlit UI |
| `cellar_metadata_extractor.py` | Extract legislation metadata → JSON |
| `case_metadata_extractor.py` | Extract case law metadata → JSON |
| `eurlex_db_import.py` | Build SQLite/CSV/JSON from extracted metadata |

## Output

```
eurlex-organized/           # Downloaded + extracted
├── REG/REG-2016-679/
│   ├── cellar_tree_notice.xml
│   └── 32016R0679_metadata.json
└── ...

output/                     # Database export
├── eurlex.db               # SQLite (Standard schema)
├── eurlex_export.json      # Combined JSON
└── csv/                    # Per-table CSVs
    ├── legislation.csv
    ├── case_law.csv
    ├── article.csv
    └── ...
```

## Key Query: "GDPR → Article 5 cases?"

```sql
SELECT cl.case_number, cl.short_title, a.display_text
FROM case_law cl
JOIN case_article_interpretation cai ON cl.id = cai.case_id
JOIN article a ON cai.article_id = a.id
JOIN legislation l ON a.legislation_id = l.id
WHERE l.celex = '32016R0679' AND a.article_num = 5;
```

## Requirements

```bash
pip3 install lxml requests tqdm streamlit
```
