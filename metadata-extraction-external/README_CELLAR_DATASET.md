# EU Regulations Dataset - Documentation Index 📚

## Quick Start

**Want to use the metadata?** Start here:
👉 **[METADATA_QUICK_REFERENCE.md](METADATA_QUICK_REFERENCE.md)** - Quick lookup tables & Python examples

**Want the full picture?** Read this:
👉 **[EXTRACTION_SUMMARY.md](EXTRACTION_SUMMARY.md)** - Complete project overview & detailed JSON structure

**Want to download more data?** See:
👉 **[CLI_DOWNLOADER_GUIDE.md](CLI_DOWNLOADER_GUIDE.md)** - Complete CLI downloader guide

---

## 📊 What's in This Dataset?

- **2,576 EU Regulations** (2010-2024)
- **Full metadata** in structured JSON format
- **24 EU languages** for each document
- **Legal relationships** (amendments, citations, consolidations)
- **Eurovoc subject classifications**
- **Original CELLAR XML** files

## 📂 Documentation Structure

### For End Users (Data Analysis)

1. **[METADATA_QUICK_REFERENCE.md](METADATA_QUICK_REFERENCE.md)** ⭐ START HERE
   - Quick lookup tables
   - Common field paths
   - Python code examples
   - Use cases (finding documents, multilingual access, etc.)

2. **[EXTRACTION_SUMMARY.md](EXTRACTION_SUMMARY.md)**
   - Complete JSON structure with all fields
   - Detailed field descriptions
   - Performance stats
   - Dataset overview

### For Developers (Tools & Downloading)

3. **[CLI_DOWNLOADER_GUIDE.md](CLI_DOWNLOADER_GUIDE.md)**
   - How to download more documents
   - CLI tool usage
   - Filtering by type/year
   - Performance tips

4. **[CLI_QUICK_REFERENCE.md](CLI_QUICK_REFERENCE.md)**
   - Quick CLI commands
   - Common download scenarios
   - Troubleshooting

5. **[PERFORMANCE_COMPARISON.md](PERFORMANCE_COMPARISON.md)**
   - Speed analysis (CLI vs Streamlit)
   - Technical bottleneck explanation
   - Optimization details

## 🚀 Common Tasks

### I want to...

**...find all regulations about a specific topic**
→ See: [METADATA_QUICK_REFERENCE.md - Use Case 3](METADATA_QUICK_REFERENCE.md#3-find-all-documents-on-a-topic)

**...get document titles in different languages**
→ See: [METADATA_QUICK_REFERENCE.md - Use Case 1](METADATA_QUICK_REFERENCE.md#1-get-document-title-in-specific-language)

**...check if a regulation is still valid**
→ See: [METADATA_QUICK_REFERENCE.md - Use Case 2](METADATA_QUICK_REFERENCE.md#2-check-if-document-is-still-valid)

**...build a network of legal relationships**
→ See: [METADATA_QUICK_REFERENCE.md - Use Case 4](METADATA_QUICK_REFERENCE.md#4-build-legal-relationship-network)

**...download more documents**
→ See: [CLI_DOWNLOADER_GUIDE.md - Quick Start](CLI_DOWNLOADER_GUIDE.md#quick-start)

**...understand the complete JSON structure**
→ See: [EXTRACTION_SUMMARY.md - Complete Metadata Structure](EXTRACTION_SUMMARY.md#complete-metadata-structure)

**...extract case law references and article numbers**
→ See: [METADATA_QUICK_REFERENCE.md - Case Law & Article Interpretation](METADATA_QUICK_REFERENCE.md#case-law--article-interpretation-)

## 📁 File Locations

```
/Users/milos/Coding/eurlex-organized/
└── REG/
    ├── REG-2021-479/
    │   ├── cellar_tree_notice.xml      # Original CELLAR XML
    │   └── 32021R0479_metadata.json    # Extracted metadata (USE THIS)
    ├── REG-2021-821/
    │   ├── cellar_tree_notice.xml
    │   └── 32021R0821_metadata.json
    └── ... (2,576 total folders)
```

**Use the JSON files** - they contain all the structured metadata in an easy-to-use format!

## 🔑 Key Metadata Fields

| What You Need | Field Path |
|---------------|------------|
| Unique ID | `document.identifiers.celex` |
| Title (English) | `document.title.multilingual.eng[0]` |
| Document date | `document.dates.document` |
| Still valid? | `document.dates.endOfValidity == "9999-12-31"` |
| Subject topics | `document.eurovoc.concepts` |
| Amends which acts | `document.legalRelations.amends` |

👉 **Full field reference:** [METADATA_QUICK_REFERENCE.md](METADATA_QUICK_REFERENCE.md)

## 💡 Example: Load and Analyze

```python
import json
from pathlib import Path

# Load a single metadata file
with open('32021R0479_metadata.json') as f:
    data = json.load(f)

# Get key information
celex = data['document']['identifiers']['celex']
title = data['document']['title']['primary']
date = data['document']['dates']['document']
topics = [c['label'] for c in data['document']['eurovoc']['concepts']]

print(f"CELEX: {celex}")
print(f"Title: {title}")
print(f"Date: {date}")
print(f"Topics: {', '.join(topics)}")
```

**Output:**
```
CELEX: 32021R0479
Title: Council Regulation (EU) 2021/479 of 22 March 2021...
Date: 2021-03-22
Topics: economic sanctions, legal person, Myanmar/Burma, EU restrictive measure...
```

## 📚 Additional Resources

- **CELLAR Manual:** `cellarmanual.md` (EUR-Lex technical documentation)
- **Tools Source Code:** 
  - `cellar_downloader_cli.py` - Fast concurrent downloader
  - `cellar_metadata_extractor.py` - XML to JSON extractor

## 🎯 Quick Links by User Type

### Legal Researcher
- Start: [METADATA_QUICK_REFERENCE.md](METADATA_QUICK_REFERENCE.md)
- Focus: Legal relations, Eurovoc concepts, dates

### Data Scientist
- Start: [EXTRACTION_SUMMARY.md](EXTRACTION_SUMMARY.md)
- Focus: Complete JSON structure, stats object, batch processing

### Linguist
- Start: [METADATA_QUICK_REFERENCE.md - Multilingual Section](METADATA_QUICK_REFERENCE.md#-multilingual-titles)
- Focus: Title translations, language codes, multilingual analysis

### Software Developer
- Start: [CLI_DOWNLOADER_GUIDE.md](CLI_DOWNLOADER_GUIDE.md)
- Focus: Downloading more data, filtering, automation

## ✅ Dataset Quality

- **Success Rate:** 100% (2,576/2,576 successful extractions)
- **Data Completeness:** All mandatory CELLAR fields extracted
- **Time Period:** 2010-2024 (15 years)
- **Languages:** All 24 official EU languages
- **Size:** 2.84 GB (XML + JSON)

## 📞 Support

Questions about:
- **Metadata fields?** → Check [METADATA_QUICK_REFERENCE.md](METADATA_QUICK_REFERENCE.md)
- **Downloading more?** → Check [CLI_DOWNLOADER_GUIDE.md](CLI_DOWNLOADER_GUIDE.md)
- **JSON structure?** → Check [EXTRACTION_SUMMARY.md](EXTRACTION_SUMMARY.md)

---

**Last Updated:** November 8, 2025  
**Dataset Version:** 1.0  
**Total Documents:** 2,576 regulations
