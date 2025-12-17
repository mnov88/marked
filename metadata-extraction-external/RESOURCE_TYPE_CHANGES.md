# Resource Type Extraction - Quick Visual Guide

## What Was Added

### New Fields in JSON Output

```diff
  "document": {
    "identifiers": {
      "celex": "32016R0679",
      "eli": "http://data.europa.eu/eli/reg/2016/679/oj",
      "naturalNumber": "0679",
      "type": "R",
      "year": "2016",
-     "sector": "3"
+     "sector": "3",
+     "resourceType": "REG",
+     "resourceTypeLabel": "Regulation"
    }
  }
```

## Before vs After

### Before
```json
{
  "identifiers": {
    "type": "R"  // Single letter code only
  }
}
```

### After
```json
{
  "identifiers": {
    "type": "R",                      // Original field preserved
    "resourceType": "REG",            // Full code (NEW)
    "resourceTypeLabel": "Regulation" // Human-readable (NEW)
  }
}
```

## XML Structure Being Extracted

```xml
<NOTICE>
  <WORK>
    <WORK_HAS_RESOURCE-TYPE type="concept">
      <URI>
        <VALUE>http://publications.europa.eu/resource/authority/resource-type/DIR</VALUE>
        <IDENTIFIER>DIR</IDENTIFIER>  ← Extracted to resourceType
        <TYPE>resource-type</TYPE>
      </URI>
      <OP-CODE>DIR</OP-CODE>
      <IDENTIFIER>DIR</IDENTIFIER>
      <PREFLABEL>Directive</PREFLABEL>  ← Extracted to resourceTypeLabel
      <ALTLABEL>Directives</ALTLABEL>
    </WORK_HAS_RESOURCE-TYPE>
  </WORK>
</NOTICE>
```

## XPath Mappings

| Field | XPath | Example Value |
|-------|-------|---------------|
| `resourceType` | `//WORK_HAS_RESOURCE-TYPE/IDENTIFIER` | `"DIR"`, `"REG"`, `"DEC"` |
| `resourceTypeLabel` | `//WORK_HAS_RESOURCE-TYPE/PREFLABEL` | `"Directive"`, `"Regulation"`, `"Decision"` |

## Common Values

| Type Code | Type Label | Old "type" Field | Description |
|-----------|------------|------------------|-------------|
| `REG` | Regulation | `R` | EU Regulation |
| `DIR` | Directive | `L` | EU Directive |
| `DEC` | Decision | `D` | EU Decision |
| `REG_IMPL` | Implementing Regulation | `R` | Implementing act |
| `REG_DELEG` | Delegated Regulation | `R` | Delegated act |
| `DEC_IMPL` | Implementing Decision | `D` | Implementing decision |

## Benefits

✅ **More Descriptive**: "Regulation" vs "R"  
✅ **Full Context**: Distinguishes REG, REG_IMPL, REG_DELEG  
✅ **User-Friendly**: Human-readable labels  
✅ **Standards-Compliant**: Uses EU Publications Office authority codes  
✅ **Backward Compatible**: Original "type" field preserved  

## Code Changes Summary

### 1. Configuration (`cellar_xpath_config.json`)
```json
"identifiers": {
  // ... existing fields ...
  "resource_type": "//WORK_HAS_RESOURCE-TYPE/IDENTIFIER",
  "resource_type_label": "//WORK_HAS_RESOURCE-TYPE/PREFLABEL"
}
```

### 2. Extractor (`cellar_metadata_extractor.py`)
```python
def extract_identifiers(self, tree, main_work):
    # ... existing extraction ...
    return {
        # ... existing fields ...
        'resourceType': self.extract_text_from_element(main_work, 
            './/WORK_HAS_RESOURCE-TYPE/IDENTIFIER') or 'Not found',
        'resourceTypeLabel': self.extract_text_from_element(main_work, 
            './/WORK_HAS_RESOURCE-TYPE/PREFLABEL') or 'Not found'
    }
```

## How to Use

### CLI Extraction
```bash
# Extract with new fields
python3 cellar_metadata_extractor.py \
  --root /path/to/eurlex-organized \
  --verbose
```

### Streamlit UI
```bash
# UI automatically uses updated parser
streamlit run cellar_metadata_extractor_ui.py
```

### Python Code
```python
import json

with open('32016R0679_metadata.json') as f:
    data = json.load(f)

# Access new fields
resource_type = data['document']['identifiers']['resourceType']
type_label = data['document']['identifiers']['resourceTypeLabel']

print(f"{type_label} ({resource_type})")
# Output: Regulation (REG)
```

## Files Changed

| File | Type | Changes |
|------|------|---------|
| `cellar_xpath_config.json` | Config | Added 2 XPath mappings |
| `cellar_metadata_extractor.py` | Code | Added 2 fields to extraction |
| `METADATA_QUICK_REFERENCE.md` | Docs | Added field reference |
| `EURLEX_METADATA_EXTRACTION_GUIDE.md` | Docs | Updated examples |
| `cellar_metadata_extractor_ui.py` | UI | ✅ No changes needed (uses main parser) |

---

**Status**: ✅ Implementation Complete  
**Testing**: ✅ Python syntax validated, JSON config validated  
**Documentation**: ✅ All docs updated  
**Compatibility**: ✅ Backward compatible, no breaking changes

