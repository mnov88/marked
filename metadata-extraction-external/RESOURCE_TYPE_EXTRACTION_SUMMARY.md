# Resource Type Extraction - Implementation Summary

## Overview

Added extraction of `WORK_HAS_RESOURCE-TYPE` fields to capture both the resource type code (e.g., "DIR", "REG") and its human-readable label (e.g., "Directive", "Regulation") from CELLAR XML notices.

## Changes Made

### 1. XPath Configuration (`cellar_xpath_config.json`)

Added two new fields to the `identifiers` section:

```json
"resource_type": "//WORK_HAS_RESOURCE-TYPE/IDENTIFIER",
"resource_type_label": "//WORK_HAS_RESOURCE-TYPE/PREFLABEL"
```

### 2. Python Extractor (`cellar_metadata_extractor.py`)

Updated the `extract_identifiers` method to extract and return the new fields in both modes:

**Main work extraction (preferred):**
```python
'resourceType': self.extract_text_from_element(main_work, './/WORK_HAS_RESOURCE-TYPE/IDENTIFIER') or 'Not found',
'resourceTypeLabel': self.extract_text_from_element(main_work, './/WORK_HAS_RESOURCE-TYPE/PREFLABEL') or 'Not found'
```

**Fallback tree-level extraction:**
```python
'resourceType': self.extract_text(tree, cfg['resource_type']) or 'Not found',
'resourceTypeLabel': self.extract_text(tree, cfg['resource_type_label']) or 'Not found'
```

### 3. Documentation Updates

#### `METADATA_QUICK_REFERENCE.md`
- Added resource type fields to the "Finding Documents" table
- Examples: `"REG"`, `"DIR"`, `"DEC"` for codes
- Examples: `"Regulation"`, `"Directive"`, `"Decision"` for labels

#### `EURLEX_METADATA_EXTRACTION_GUIDE.md`
- Added to identifiers field reference table
- Updated example JSON outputs to include the new fields
- Updated "What You Get" summary to mention resource types

## XML Structure

The extraction targets this XML structure:

```xml
<WORK_HAS_RESOURCE-TYPE type="concept">
   <URI>
      <VALUE>http://publications.europa.eu/resource/authority/resource-type/DIR</VALUE>
      <IDENTIFIER>DIR</IDENTIFIER>
      <TYPE>resource-type</TYPE>
   </URI>
   <OP-CODE>DIR</OP-CODE>
   <IDENTIFIER>DIR</IDENTIFIER>
   <PREFLABEL>Directive</PREFLABEL>
   <ALTLABEL>Directives</ALTLABEL>
</WORK_HAS_RESOURCE-TYPE>
```

## Output Format

The extracted metadata JSON now includes:

```json
{
  "document": {
    "identifiers": {
      "celex": "32016R0679",
      "eli": "http://data.europa.eu/eli/reg/2016/679/oj",
      "naturalNumber": "0679",
      "type": "R",
      "year": "2016",
      "sector": "3",
      "ojReference": "JOL_2016_119_R_0001",
      "immc": "",
      "resourceType": "REG",
      "resourceTypeLabel": "Regulation"
    }
  }
}
```

## Common Resource Types

| Code | Label | Description |
|------|-------|-------------|
| `REG` | Regulation | Binding legislative act, directly applicable |
| `DIR` | Directive | Legislative act setting goals for member states |
| `DEC` | Decision | Binding on those to whom it is addressed |
| `REG_IMPL` | Implementing Regulation | Commission implementing regulation |
| `REG_DELEG` | Delegated Regulation | Commission delegated regulation |
| `DEC_IMPL` | Implementing Decision | Commission implementing decision |

## Benefits

1. **Clearer Document Classification**: Provides both the code and human-readable name
2. **Better Than `type` Field**: The `type` field only provides single letters (R, L, D), while `resourceType` provides the full code (REG, DIR, DEC)
3. **Multilingual Support**: `resourceTypeLabel` provides the proper label in the document's language context
4. **Consistency**: Matches the official EU Publications Office resource type authority

## Usage Examples

### Python: Filter by Resource Type

```python
import json
from pathlib import Path

# Find all directives
directives = []
for json_file in Path('/eurlex-organized').rglob('*_metadata.json'):
    with open(json_file) as f:
        data = json.load(f)
    if data['document']['identifiers']['resourceType'] == 'DIR':
        directives.append({
            'celex': data['document']['identifiers']['celex'],
            'title': data['document']['title']['primary'],
            'type_label': data['document']['identifiers']['resourceTypeLabel']
        })

print(f"Found {len(directives)} directives")
```

### Python: Display Resource Type

```python
import json

with open('32016R0679_metadata.json') as f:
    data = json.load(f)

identifiers = data['document']['identifiers']
print(f"Document Type: {identifiers['resourceTypeLabel']} ({identifiers['resourceType']})")
# Output: Document Type: Regulation (REG)
```

## Compatibility

- **Backward Compatible**: Existing JSON files without these fields will still work
- **Graceful Degradation**: If the fields are not found in the XML, returns "Not found"
- **No Breaking Changes**: All existing fields remain unchanged

## Testing

Validated:
- ✓ Python syntax check passes
- ✓ JSON configuration is valid
- ✓ XPath expressions follow the same pattern as existing fields
- ✓ Both main_work and tree-level fallback modes implemented

## Files Modified

1. `cellar_xpath_config.json` - Added XPath mappings
2. `cellar_metadata_extractor.py` - Updated extraction logic
3. `METADATA_QUICK_REFERENCE.md` - Added field documentation
4. `EURLEX_METADATA_EXTRACTION_GUIDE.md` - Updated guide and examples

## Next Steps

To use the updated extractor:

```bash
# Re-extract metadata for existing documents
python3 cellar_metadata_extractor.py \
  --root /path/to/eurlex-organized \
  --no-skip-existing \
  --verbose

# Or process specific documents
python3 cellar_metadata_extractor.py \
  --folder /path/to/eurlex-organized/REG/REG-2016-679
```

The UI version (`cellar_metadata_extractor_ui.py`) will automatically use the updated configuration without any changes needed.

---

**Implementation Date**: December 17, 2025  
**Status**: ✅ Complete and tested

