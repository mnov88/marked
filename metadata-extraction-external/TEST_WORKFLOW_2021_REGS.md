# 🧪 Test Workflow: 2021 REGs

Complete test of the full pipeline: Download → Extract → Verify

## Step 1: Download 2021 REGs ⚡

### Launch Fast Downloader

```bash
cd /Users/milos/Desktop/markdowned
streamlit run cellar_downloader_fast.py
```

### Configure Filters

In the Streamlit UI sidebar:

1. **🔍 Filters Section:**
   - **Document Types:** Select `REG` only
   - **Years:** Select `2021` only

2. **⚙️ Configuration:**
   - **CSV Path:** `/Users/milos/Desktop/markdowned/eurlex_metadata_enhanced.csv`
   - **Output Root:** `/Users/milos/Coding/eurlex-organized`
   - **Batch Size:** Leave as default (will download all filtered docs)

3. **Advanced Settings** (optional):
   - **UI Update Interval:** 10 (good balance)
   - **Max Retries:** 3
   - **Timeout:** 30s

### Expected Stats

After filtering:
- **📊 Total in CSV:** ~24,078
- **🔍 Filtered:** ~XXX (we'll see the exact number)
- **📈 Showing:** ~X.X%

### Start Download

Click **"▶️ Start Download"**

**Expected Performance:**
- If ~500 REGs from 2021
- Fast version: **~45 seconds - 1 minute**
- Standard version would take: **~8-10 minutes**

### Monitor Progress

Watch for:
- ✅ Success count
- ⚡ Speed (docs/sec)
- ⏱️ ETA
- 💾 Downloaded (MB)

---

## Step 2: Extract Metadata from Downloaded REGs 📊

### Option A: Streamlit UI (Recommended for Testing)

```bash
cd /Users/milos/Desktop/markdowned
streamlit run cellar_metadata_extractor_ui.py
```

**In the UI:**

1. **Configuration:**
   - **Root Directory:** `/Users/milos/Coding/eurlex-organized`
   - **Document Limit:** 0 (process all)
   - **Skip Existing Files:** ✅ Checked

2. **Filters:**
   - **Document Types:** Select `REG` only
   - **Years:** Select `2021` only

3. Click **"▶️ Start Extraction"**

### Option B: CLI (Faster for Batch)

```bash
cd /Users/milos/Desktop/markdowned

# Extract all 2021 REGs
python3 cellar_metadata_extractor.py \
  --root "/Users/milos/Coding/eurlex-organized" \
  --verbose
```

**Note:** CLI doesn't have filters, so it will process all docs. If you only want 2021 REGs, use the Streamlit UI or process the specific folder manually.

---

## Step 3: Verify Results ✅

### Quick Check: Count Files

```bash
# Count downloaded XMLs
find /Users/milos/Coding/eurlex-organized/REG -name "cellar_tree_notice.xml" | \
  grep "2021" | wc -l

# Count extracted JSONs
find /Users/milos/Coding/eurlex-organized/REG -name "*_metadata.json" | \
  grep "2021" | wc -l
```

**Expected:** Same number of XML and JSON files

### Verify Random Sample

Pick a random 2021 REG and check it:

```bash
# Find a 2021 REG
find /Users/milos/Coding/eurlex-organized/REG -name "*2021*" -type d | head -1

# Example: REG-2021-1234
cd /Users/milos/Coding/eurlex-organized/REG/REG-2021-XXXX

# Check files exist
ls -lh
# Should see:
#   cellar_tree_notice.xml
#   3XXXXRXXXX_metadata.json

# Verify JSON content
cat *_metadata.json | jq '{
  celex: .document.identifiers.celex,
  date: .document.dates.document,
  title: .document.title.primary,
  eurovoc_count: .document.eurovoc.concepts | length,
  caselaw_count: .document.caselaw | length
}'
```

### Comprehensive Statistics

```bash
# Get stats on all 2021 REGs
python3 << 'EOF'
import json
from pathlib import Path

reg_dir = Path("/Users/milos/Coding/eurlex-organized/REG")
json_files = list(reg_dir.rglob("*_metadata.json"))

# Filter for 2021
regs_2021 = [f for f in json_files if "2021" in f.parent.name]

print(f"📊 2021 REGs Processed: {len(regs_2021)}")

if regs_2021:
    # Sample first one
    sample = json.loads(regs_2021[0].read_text())
    print(f"\n📄 Sample Document:")
    print(f"  CELEX: {sample['document']['identifiers']['celex']}")
    print(f"  Date: {sample['document']['dates']['document']}")
    print(f"  Title: {sample['document']['title']['primary'][:80]}...")
    print(f"  Eurovoc concepts: {len(sample['document']['eurovoc']['concepts'])}")
    print(f"  Case law refs: {len(sample['document']['caselaw'])}")

    # Aggregate stats
    total_eurovoc = sum(
        len(json.loads(f.read_text())['document']['eurovoc']['concepts'])
        for f in regs_2021[:10]  # Sample first 10
    )
    print(f"\n📈 Stats (first 10 docs):")
    print(f"  Avg Eurovoc concepts: {total_eurovoc / min(10, len(regs_2021)):.1f}")

EOF
```

---

## Step 4: Spot Check Specific Documents 🔍

### Check CELEX Format

All 2021 REGs should have CELEX starting with `32021R`:

```bash
cd /Users/milos/Coding/eurlex-organized/REG

# Extract all CELEX IDs from 2021 REGs
find . -path "*/REG-2021-*/*_metadata.json" -exec jq -r '.document.identifiers.celex' {} \; | sort | head -20
```

**Expected pattern:** `32021R0001`, `32021R0002`, etc.

### Check Dates

All dates should be in 2021:

```bash
# Extract dates from 2021 REGs
find . -path "*/REG-2021-*/*_metadata.json" -exec jq -r '.document.dates.document' {} \; | sort | head -20
```

**Expected:** All dates start with `2021-`

### Check Titles

Verify titles make sense:

```bash
# Sample titles
find . -path "*/REG-2021-*/*_metadata.json" -exec jq -r '.document.title.primary' {} \; | head -5
```

**Expected:** Proper regulation titles, not references to consolidated versions

---

## Expected Results Summary

### Download Phase (Fast Version ⚡)

**Estimated 2021 REGs:** ~400-600 documents

**Time:**
- Fast version: **~1-2 minutes**
- Standard version: **~10-15 minutes**

**Success Rate:** ~98-99%
- Most should succeed
- Some 404s are normal (withdrawn/not published)

### Extraction Phase

**Time:**
- ~400-600 docs: **~2-3 minutes**

**Success Rate:** ~100%
- All valid XMLs should extract successfully

### Output

Each 2021 REG folder should contain:
```
REG-2021-XXXX/
├── cellar_tree_notice.xml      (100-500 KB)
└── 32021RXXXX_metadata.json    (5-50 KB)
```

---

## Validation Checklist

After running both steps, verify:

- [ ] All filtered 2021 REGs downloaded
- [ ] XML files present in each folder
- [ ] JSON metadata files created
- [ ] CELEX IDs match pattern `32021R*`
- [ ] Dates are in 2021
- [ ] Titles look correct (not consolidated versions)
- [ ] Eurovoc concepts extracted
- [ ] No extraction errors

---

## Quick Test Commands

### One-Liner: Count Everything

```bash
echo "XMLs: $(find /Users/milos/Coding/eurlex-organized/REG -path "*/REG-2021-*/cellar_tree_notice.xml" | wc -l)"
echo "JSONs: $(find /Users/milos/Coding/eurlex-organized/REG -path "*/REG-2021-*/*_metadata.json" | wc -l)"
```

### One-Liner: Verify Sample

```bash
# Pick random 2021 REG and show key fields
find /Users/milos/Coding/eurlex-organized/REG -path "*/REG-2021-*/*_metadata.json" -print -quit | \
  xargs cat | jq '{celex, date: .document.dates.document, title: .document.title.primary | .[0:100]}'
```

---

## Troubleshooting

### No 2021 REGs Found in CSV

**Check CSV:**
```bash
grep "2021" /Users/milos/Desktop/markdowned/eurlex_metadata_enhanced.csv | grep "REG" | head -5
```

If none found, the CSV might need updating.

### Download Errors

**Common issues:**
- **404:** Document not published yet or withdrawn (normal)
- **429:** Rate limited (fast version retries automatically)
- **Timeout:** Network issues (fast version retries automatically)

### Extraction Errors

**Common issues:**
- **XML parse error:** Corrupted download (re-download)
- **Missing main work:** Check if XML is valid
- **Wrong CELEX:** Check folder name vs actual CELEX

---

## Performance Metrics

### Expected Download Performance (Fast Version ⚡)

**500 documents:**
- **Time:** ~1-2 minutes
- **Speed:** ~5-8 docs/sec
- **Size:** ~100-200 MB
- **Success rate:** ~98%

### Expected Extraction Performance

**500 documents:**
- **Time:** ~2-3 minutes
- **Speed:** ~3-4 docs/sec
- **Success rate:** ~100%

---

## Next Steps

Once 2021 REGs are tested:

1. **Scale Up:** Try a full year (e.g., 2020, 2019)
2. **Different Types:** Test DIRs, DECs from 2021
3. **Bulk Download:** Download all 24K docs overnight
4. **Full Extraction:** Extract all downloaded XMLs

---

## Summary

This test workflow validates:
- ✅ Fast downloader works correctly
- ✅ Filtering by type and year works
- ✅ Metadata extraction produces correct output
- ✅ CELEX, dates, titles are accurate
- ✅ End-to-end pipeline is functional

**Total Time:** ~5 minutes for complete workflow! ⚡

Ready to scale to full dataset! 🚀



