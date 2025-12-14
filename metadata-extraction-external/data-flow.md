# Data Flow Overview

> **For comprehensive documentation, see: [EURLEX_METADATA_EXTRACTION_GUIDE.md](EURLEX_METADATA_EXTRACTION_GUIDE.md)**

This document provides a quick reference for the data flow. The comprehensive guide contains complete schemas, all available fields, and detailed examples.

---

## 1) Seed List Creation (Enhanced CSV)
- Script: `eurlex_metadata_extractor_enhanced.py`.
- Inputs: FMX doc XML tree (`.../LEG_EN_FMX_*/<uuid>/fmx4/*.doc.xml`) and RDF metadata (`.../LEG_MTD_*/<uuid>/tree_non_inferred.rdf`).
- Action: parses FMX for type/number/year/title/date/ELI and RDF for CELEX, ELI URI, in-force flags, Eurovoc, relations, languages, creator; normalizes legal types and proposes filenames.
- Output: `eurlex_metadata_enhanced.csv` written to repo root; includes status/flag reason when filename inference fails. Run via:
```bash
python eurlex_metadata_extractor_enhanced.py /path/to/LEG_EN_FMX... /path/to/LEG_MTD...
```

## 2) Download CELLAR XML Notices
- Preferred tool: `cellar_downloader_cli.py` (ThreadPool, no UI reruns; see `CLI_DOWNLOADER_GUIDE.md`).
- Alternatives: `cellar_downloader_fast.py` (Streamlit, pooled HTTP) or `cellar_downloader_ui.py` (safer, slower).
- Inputs: `eurlex_metadata_enhanced.csv` plus filters (`--types`, `--years`, `--limit`, `--start`).
- Action: fetches CELLAR tree notices using CELEX/UUID from CSV; saves under target root with preserved type/year folders.
- Output: folder tree like `/.../REG/REG-2016-679/cellar_tree_notice.xml` plus original files; existing downloads are skipped automatically. Example (CLI):
```bash
python3 cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /Users/milos/Coding/eurlex-organized \
  --types REG --years 2021 --workers 20 --limit 50
```

## 3) Extract Metadata to JSON
- Script: `cellar_metadata_extractor.py` (CLI) or `cellar_metadata_extractor_ui.py` (Streamlit UI wrapper).
- Inputs: downloaded folder tree containing `cellar_tree_notice.xml`; XPath map in `cellar_xpath_config.json` controls fields.
- Action: walks `--root` (or a single `--folder`), applies XPath to each XML, computes stats, skips existing JSON unless `--no-skip-existing`.
- Output: `{CELEX}_metadata.json` beside each XML (e.g., `/.../REG-2016-679/32016R0679_metadata.json`). Example:
```bash
python3 cellar_metadata_extractor.py \
  --root /Users/milos/Coding/eurlex-organized \
  --limit 10 --verbose
```

## 3b) Case-Law Enrichment (optional)
- Collect case CELEX IDs from existing legislation metadata or a text list.
- Download notices: `python3 case_downloader.py --from-legislation-root /path/to/eurlex-organized --output /path/to/case-cache --workers 10 --limit 20` (or `--cases-file cases.txt`).
- Extract case metadata: `python3 case_metadata_extractor.py --root /path/to/case-cache --verbose` using `case_xpath_config.json`; outputs `{CELEX}_case_metadata.json` under the same tree with legislation-aligned schema (top-level `case`, `stats`, `available_languages` and `interpretedLegislation` entries with `articles`/`parsedArticles`).
- Join logic (if needed) can be generated separately to map case CELEX/ECLI back to interpreted legislation/articles.

## 4) Validation & Tips
- Quick smoke: run the GDPR sample in `QUICK_START.md`, then verify CELEX/date/title via `jq`.
- When editing XPath config or downloader behavior, test with `--limit 10 --workers 3` before large batches and avoid committing regenerated CSV/log files.

## JSON Shape Examples (mocked)

### Legislation (`*_metadata.json`)
```json
{
  "extraction_timestamp": "2024-07-01T12:00:00Z",
  "selected_language": "eng",
  "available_languages": ["bg","cs","de","en","es","fr","it"],
  "document": {
    "languages": ["bg","cs","de","en","es","fr","it"],
    "title": {
      "primary": "Regulation (EU) 2016/679 of the European Parliament and of the Council",
      "work": "Regulation on data protection",
      "alternative": ["GDPR"],
      "subtitle": [],
      "short": "GDPR",
      "multilingual": {"en": ["Regulation (EU) 2016/679..."], "fr": ["Règlement (UE) 2016/679..."]}
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
      "natural_number": "2016R0679",
      "type": "REG",
      "year": "2016",
      "sector": "3",
      "eli": "http://data.europa.eu/eli/reg/2016/679/oj",
      "ojReference": "JOL_2016_119_R_0001",
      "immc": ""
    },
    "eurovoc": {"concepts": [{"id":"5595","label":"personal data"}], "domains": [], "microthesaurus": [], "terms": []},
    "caselaw": [{
      "celex": "62017CJ0673",
      "ecli": "ECLI:EU:C:2019:801",
      "articles": ["A04PT11","A06P1LA"],
      "parsedArticles": [
        {"raw":"A04PT11","parsed":"Article 4, Point 11","type":"simple","components":{"article":4,"point":11}},
        {"raw":"A06P1LA","parsed":"Article 6, Paragraph 1","type":"simple","components":{"article":6,"paragraph":1}}
      ],
      "type": "Interpreted by"
    }],
    "legalRelations": {"basedOn": ["12012M/TXT"], "cites": ["32002L0058"], "amends": [], "repeals": ["31995L0046"], "consolidatedBy": [], "correctedBy": [], "treatyBasis": []},
    "metadata": {"createdBy":"European Parliament and Council","responsibleAgent":"DG JUST","inForce":"true","subjectMatter":"Data protection","dossierReference":"2012/0114(COD)","version":"1.0","lastModified":"2024-06-01","directory_code":"13.10.10.00"}
  },
  "stats": {"languages":7,"cases":1,"eurovoc":1,"articles":2,"relations":3,"implementations":0}
}
```

### Case-law (`*_case_metadata.json`)
```json
{
  "extraction_timestamp": "2024-07-01T12:05:00Z",
  "selected_language": "en",
  "available_languages": ["bg","cs","da","de","el","en","es","et","fr"],
  "case": {
    "identifiers": {
      "celex": "62017CJ0673",
      "ecli": ["ECLI:EU:C:2019:801","ECLI:EU:C:2019:26"],
      "caseNumber": "C-673/17",
      "cellarUri": "http://publications.europa.eu/resource/cellar/62017CJ0673",
      "nationalEcli": []
    },
    "title": {
      "multilingual": {"en": ["Judgment of the Court (Grand Chamber) of 1 October 2019 ..."], "fr": ["Arrêt de la Cour (grande chambre) du 1 octobre 2019 ..."]},
      "short": ["Planet49"]
    },
    "parties": {"en": ["Bundesverband ... v Planet49 GmbH"], "de": ["Bundesverband ... gegen Planet49 GmbH"]},
    "dates": {"judgment":"2019-10-01","request":"2017-12-21","creation":"2019-10-01","lastModified":"2024-06-01","publication":"2019-10-15"},
    "court": {"name":"Court of Justice","code":"CJEU","procedureType":"Reference for a preliminary ruling","procedureLanguage":"de","originCountry":"Germany","documentType":"Judgment"},
    "participants": {"judges":["K. Lenaerts"], "advocatesGeneral":["M. Szpunar"]},
    "interpretedLegislation": [
      {
        "celex": "32016R0679",
        "articles": ["A04PT11","A06P1LA"],
        "parsedArticles": [
          {"raw":"A04PT11","parsed":"Article 4, Point 11","type":"simple","components":{"article":4,"point":"11"}},
          {"raw":"A06P1LA","parsed":"Article 6, Paragraph 1","type":"simple","components":{"article":6,"paragraph":1}}
        ],
        "type": "interprets"
      }
    ],
    "citations": {"celex":["32002L0058","32016R0679"], "ecli":["ECLI:EU:C:2017:994"], "works":["http://publications.europa.eu/resource/celex/32002L0058"], "nationalJudgment":[]},
    "subjectMatter": {"primary":["Data protection"], "codes":["13.10.10.00"], "eurovoc":["personal data"]},
    "academicSources": ["Opinion of AG Szpunar"],
    "metadata": {"sector":"6","year":"2019","version":"1.0","publishedInErecueil":"false","languages":["en","de","fr"],"buildInfo":[]}
  },
  "stats": {"languages":9,"interpretedActs":1,"citations":3,"judges":1,"advocatesGeneral":1},
  "source_xml": "/path/to/case-cache/CASE/62017CJ0673/cellar_case_notice.xml"
}
```
