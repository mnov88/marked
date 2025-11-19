# Metadata Quick Reference - What's Available 📋

## Quick Access Guide

### 🔍 Finding Documents

| What You Want | Use This Field | Example |
|---------------|----------------|---------|
| Unique ID | `document.identifiers.celex` | `"32021R0479"` |
| Permanent URI | `document.identifiers.eli` | `"http://data.europa.eu/eli/reg/2021/479/oj"` |
| Official Journal ref | `document.identifiers.ojReference` | `"JOL_2021_099_I_0002"` |

### 📅 Temporal Information

| What You Want | Use This Field | Format |
|---------------|----------------|--------|
| Document date | `document.dates.document` | `"2021-03-22"` |
| Publication date | `document.dates.publication` | `"2021-03-22"` |
| Effective date | `document.dates.entryIntoForce` | `"2021-03-22"` |
| Still valid? | `document.dates.endOfValidity` | `"9999-12-31"` = yes |
| Is in force? | `document.metadata.inForce` | `"true"` / `"false"` |

### 🌍 Multilingual Titles

| Language | Code | Access |
|----------|------|--------|
| English | `eng` | `document.title.multilingual.eng[0]` |
| French | `fra` | `document.title.multilingual.fra[0]` |
| German | `deu` | `document.title.multilingual.deu[0]` |
| Spanish | `spa` | `document.title.multilingual.spa[0]` |
| Italian | `ita` | `document.title.multilingual.ita[0]` |

**All 24 EU languages available:** bul, ces, dan, deu, ell, eng, est, fin, fra, gle, hrv, hun, ita, lav, lit, mlt, nld, pol, por, ron, slk, slv, spa, swe

### 🏷️ Classification & Topics

| What You Want | Use This Field | Structure |
|---------------|----------------|-----------|
| Subject keywords | `document.eurovoc.concepts` | `[{"id": "3870", "label": "economic sanctions"}]` |
| High-level topic | `document.metadata.subjectMatter` | `"Common foreign and security policy"` |
| Created by | `document.metadata.createdBy` | `"Council of the European Union"` |

### 🔗 Legal Relationships

| Relationship Type | Field | Description |
|------------------|-------|-------------|
| **Based on** | `document.legalRelations.basedOn` | Legal basis (treaties, decisions) |
| **Amends** | `document.legalRelations.amends` | Which acts this modifies |
| **Cites** | `document.legalRelations.cites` | Referenced documents |
| **Repeals** | `document.legalRelations.repeals` | Acts this replaces |
| **Consolidated by** | `document.legalRelations.consolidatedBy` | Consolidated versions |
| **Corrected by** | `document.legalRelations.correctedBy` | Corrigenda |

## Common Use Cases

### 1. Get Document Title in Specific Language

```python
import json

with open('32021R0479_metadata.json') as f:
    data = json.load(f)

# English title
title_en = data['document']['title']['multilingual']['eng'][0]

# French title
title_fr = data['document']['title']['multilingual']['fra'][0]

# Primary title (in selected language)
title = data['document']['title']['primary']
```

### 2. Check if Document is Still Valid

```python
# Method 1: Check end of validity date
end_date = data['document']['dates']['endOfValidity']
is_valid = end_date == '9999-12-31'

# Method 2: Check inForce flag
in_force = data['document']['metadata']['inForce'] == 'true'

print(f"Document valid: {is_valid and in_force}")
```

### 3. Find All Documents on a Topic

```python
from pathlib import Path
import json

topic = "economic sanctions"
results = []

for json_file in Path('/path/to/metadata').glob('*.json'):
    with open(json_file) as f:
        data = json.load(f)
    
    # Check Eurovoc concepts
    concepts = [c['label'] for c in data['document']['eurovoc']['concepts']]
    if topic in concepts:
        results.append({
            'celex': data['document']['identifiers']['celex'],
            'title': data['document']['title']['primary'],
            'date': data['document']['dates']['document']
        })
```

### 4. Build Legal Relationship Network

```python
# Find all documents that amend a specific regulation
target_celex = "32013R0401"

for json_file in json_files:
    with open(json_file) as f:
        data = json.load(f)
    
    amends = data['document']['legalRelations']['amends']
    if any(target_celex in ref for ref in amends):
        print(f"{data['document']['identifiers']['celex']} amends {target_celex}")
```

### 5. Extract Temporal Trends

```python
import pandas as pd
from collections import Counter

# Count documents by year
years = []
subjects = []

for json_file in json_files:
    with open(json_file) as f:
        data = json.load(f)
    
    year = data['document']['dates']['document'][:4]
    subject = data['document']['metadata']['subjectMatter']
    
    years.append(year)
    subjects.append(subject)

# Create DataFrame
df = pd.DataFrame({'year': years, 'subject': subjects})
yearly_counts = df.groupby('year').size()
```

### 6. Multilingual Analysis

```python
# Compare terminology across languages
def get_all_titles(data):
    multilingual = data['document']['title']['multilingual']
    return {
        lang: titles[0] if titles else None 
        for lang, titles in multilingual.items()
    }

titles = get_all_titles(data)
print(f"English: {titles['eng']}")
print(f"French: {titles['fra']}")
print(f"German: {titles['deu']}")
```

## Statistics Summary (`stats` object)

| Field | Description |
|-------|-------------|
| `stats.languages` | Number of language versions (typically 24) |
| `stats.eurovoc` | Number of Eurovoc concepts tagged |
| `stats.relations` | Total number of legal relationships |
| `stats.cases` | Number of case law references (for judgments) |
| `stats.implementations` | Number of national implementations (for directives) |
| `stats.articles` | Number of articles referenced (for case law) |

## Field Value Conventions

### Dates
- Format: `YYYY-MM-DD` (ISO 8601)
- Not found: `"Not found"`
- Still valid: `"9999-12-31"`

### Boolean Values
- In force: `"true"` or `"false"` (strings, not booleans)

### Arrays
- Empty arrays: `[]`
- May contain multiple values

### Reference Formats
Multiple formats may appear for the same document:
- CELEX: `32013R0401`
- ELI: `reg:2013:401:oj`
- OJ: `JOL_2013_121_R_0001_01`
- Consolidated: `02013R0401-20220423`

## Case Law & Article Interpretation 📚

### Case Law References

**Available in:** Regulations that reference case law (Court of Justice judgments)

**Field:** `document.caselaw[]`

**Structure:**
```python
{
  "celex": "62016CJ0673",          # Case identifier
  "ecli": "ECLI:EU:C:2018:385",   # European Case Law Identifier
  "articles": ["A58P5"],           # Raw article references
  "parsedArticles": [              # Interpreted article references
    {
      "raw": "A58P5",
      "parsed": "Article 58, Paragraph 5",
      "type": "simple",
      "components": {
        "article": 58,
        "paragraph": 5
      }
    }
  ],
  "type": "interpreted"
}
```

### Article Reference Parsing

The extractor automatically parses article references into structured format:

**Supported Formats:**

1. **Simple format:** `A58P5`
   - A = Article
   - 58 = Article number
   - P = Paragraph
   - 5 = Paragraph number
   - Result: `"Article 58, Paragraph 5"`

2. **URI-structured format:** `{AR|...}58{PA|...}5{PTA|...}(a)`
   - Complex CELLAR internal format
   - Extracts article, paragraph, point
   - Result: `"Article 58, Paragraph 5, Point (a)"`

3. **Inferred format:** Any number found
   - Extracts first number as article
   - Result: `"Article 58 (inferred)"`

### Example: Extract Case Law References

```python
# Get all case law references
cases = data['document']['caselaw']

for case in cases:
    celex = case['celex']
    articles = case['parsedArticles']
    
    print(f"Case: {celex}")
    for art in articles:
        if art['type'] != 'none':
            print(f"  - {art['parsed']}")
            print(f"    Article: {art['components'].get('article')}")
            if 'paragraph' in art['components']:
                print(f"    Paragraph: {art['components']['paragraph']}")
```

### Article Reference Types

| Type | Description | Example |
|------|-------------|---------|
| `simple` | Standard format (A58P5) | Article 58, Paragraph 5 |
| `uri_structured` | Complex CELLAR format | Article 58, Paragraph 5, Point (a) |
| `inferred` | Number extracted | Article 58 (inferred) |
| `original` | Could not parse | Returned as-is |
| `none` | Not specified | No article reference |

### Access Article Components

```python
# Extract structured article information
for case in data['document']['caselaw']:
    for art in case['parsedArticles']:
        if art['type'] in ['simple', 'uri_structured']:
            article_num = art['components']['article']
            paragraph_num = art['components'].get('paragraph')
            point = art['components'].get('point')
            
            # Use structured data for analysis
            print(f"Article {article_num}")
            if paragraph_num:
                print(f"  Paragraph {paragraph_num}")
            if point:
                print(f"  Point {point}")
```

### Statistics

Use `stats.cases` to see how many case law references are in a document:

```python
num_cases = data['stats']['cases']
num_articles = data['stats']['articles']

print(f"Document cites {num_cases} cases")
print(f"References {num_articles} articles")
```

---

## CELEX Number Format

Format: `SYYYRTNNNN`

- **S** = Sector (0-9)
  - 0 = Secondary legislation (most regulations)
  - 1 = Treaties
  - 2 = International agreements
  - 3 = General acts (budgets, etc.)
  - 6 = Case law
  
- **YYYY** = Year (4 digits)

- **R** = Resource type
  - R = Regulation
  - L = Directive
  - D = Decision
  - C = Communication
  - etc.

- **T** = Type indicator (0-9, A-Z)

- **NNNN** = Sequential number

Example: `32021R0479`
- 3 = General acts sector
- 2021 = Year
- R = Regulation
- 0479 = Number 479

---

**For complete structure details, see:** `EXTRACTION_SUMMARY.md`
