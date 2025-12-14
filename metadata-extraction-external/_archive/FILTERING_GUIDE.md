# 🔍 Filtering Guide for CELLAR Tools

## New Features

Both the **CELLAR XML Downloader** and **CELLAR Metadata Extractor** now support powerful filtering by document type and year!

## Why Use Filters?

### Before (Without Filters)
- ❌ Process ALL documents at once (could be thousands)
- ❌ Can't target specific legislation types
- ❌ Can't focus on specific time periods
- ❌ Have to manually organize after downloading

### After (With Filters)
- ✅ **Targeted downloads**: Get only what you need
- ✅ **Incremental processing**: Do REGs today, DIRs tomorrow
- ✅ **Year-based batching**: Process 2020 legislation while you work
- ✅ **Resource management**: Control bandwidth and disk usage
- ✅ **Testing friendly**: Test on small subsets first

## CELLAR XML Downloader - Filtering

### Access the UI
```bash
cd /Users/milos/Desktop/markdowned
streamlit run cellar_downloader_ui.py
```

### Using Filters

#### 1. **Document Type Filter**
Located in sidebar under "🔍 Filters"

**Available types:**
- `REG` - Regulations
- `DIR` - Directives  
- `DEC` - Decisions
- `REG-IMPL` - Implementing Regulations
- `DIR-IMPL` - Implementing Directives
- `DEC-IMPL` - Implementing Decisions
- And more...

**How to use:**
1. Click the "Document Types" dropdown
2. Select one or more types (e.g., `REG`, `DIR`)
3. Leave empty to show all types

#### 2. **Year Filter**
Select specific years to download

**How to use:**
1. Click the "Years" dropdown
2. Select one or more years (e.g., `2020`, `2021`, `2022`)
3. Leave empty to show all years

#### 3. **Quick Filter Buttons**
- **📋 All Types** - Clear type filter (show all types)
- **📅 All Years** - Clear year filter (show all years)

### Filter Statistics

The sidebar shows:
- **📊 Total in CSV**: Total documents available
- **🔍 Filtered**: Documents matching your filters
- **📈 Showing**: Percentage of total

Example:
```
📊 Total in CSV: 24,078
🔍 Filtered: 1,234
📈 Showing: 5.1%
```

### Active Filter Display

The main area shows what filters are active:
```
🔍 Active Filters: Types: REG, DIR | Years: 2020, 2021
```

### Example Workflows

#### Workflow 1: Download All 2020 Regulations
1. Select **Years**: `2020`
2. Select **Types**: `REG`
3. Set **Batch Size**: `500`
4. Click **▶️ Start Download**
5. Result: Downloads only 2020 regulations

#### Workflow 2: Download Recent Directives (2022-2024)
1. Select **Years**: `2022`, `2023`, `2024`
2. Select **Types**: `DIR`, `DIR-IMPL`
3. Click **▶️ Start Download**
4. Result: Downloads only recent directives

#### Workflow 3: Progressive Download Strategy
**Day 1:** Download 2020 documents
- Filter: Years = `2020`
- Download all

**Day 2:** Download 2021 documents
- Filter: Years = `2021`
- Download all

**Day 3:** Download 2022-2024
- Filter: Years = `2022`, `2023`, `2024`
- Download all

**Benefit**: Spread bandwidth usage over multiple days!

---

## CELLAR Metadata Extractor - Filtering

### Access the UI
```bash
cd /Users/milos/Desktop/markdowned
streamlit run cellar_metadata_extractor_ui.py
```

### Using Filters

The filtering works the same way as the downloader!

#### Filter By Type and Year
1. Open the UI
2. The tool automatically scans your directory
3. Available types and years are extracted from folder names
4. Select filters in sidebar
5. Click **▶️ Start Extraction**

### Example: Extract Only GDPR-Era Regulations (2016)

1. **Select Years**: `2016`
2. **Select Types**: `REG`
3. Click **▶️ Start Extraction**
4. **Result**: Processes only 2016 regulations (including GDPR!)

### Example: Process All Directives from 2020-2023

1. **Select Types**: `DIR`, `DIR-IMPL`
2. **Select Years**: `2020`, `2021`, `2022`, `2023`
3. Set **Document Limit**: `0` (all)
4. Click **▶️ Start Extraction**

---

## Combined Workflow: Download → Extract

### Step 1: Download Specific Documents
Use **cellar_downloader_ui.py**:
1. Filter: Types = `REG`, Years = `2020`
2. Download: 500 documents
3. Wait for completion

### Step 2: Extract Metadata
Use **cellar_metadata_extractor_ui.py**:
1. Same filters: Types = `REG`, Years = `2020`
2. Extract metadata from downloaded XMLs
3. Get JSON files with comprehensive metadata

### Step 3: Repeat for Other Categories
- Tomorrow: Do `DIR` from 2020
- Next day: Do `DEC` from 2020
- Then: Move to 2021, 2022, etc.

---

## Filter Tips & Tricks

### 1. **Test Before Bulk Processing**
```
Select: Years = 2020, Types = REG
Set Batch Size: 10
Click Start
→ Test with 10 documents first!
```

### 2. **Combine Multiple Years**
```
Select Years: 2020, 2021, 2022
→ Process 3 years at once
```

### 3. **Focus on Specific Legislation**
```
Types: REG, REG-IMPL
Years: 2016
→ Get GDPR and related implementing regulations
```

### 4. **Clear Filters Quickly**
Use the quick filter buttons:
- Click **📋 All Types** to reset type filter
- Click **📅 All Years** to reset year filter

### 5. **Monitor Filter Percentage**
```
Showing: 2.5%
→ Very targeted (good for testing)

Showing: 95.0%
→ Almost everything (minor filtering)
```

---

## Filter Statistics Explained

### Downloader UI
```
📊 Total in CSV: 24,078          ← All documents in your CSV
🔍 Filtered: 1,234               ← Matching your filters
📈 Showing: 5.1%                 ← Percentage filtered
```

### Extractor UI
```
📊 Total XML files: 10           ← All downloaded XMLs found
🔍 Filtered: 3                   ← Matching your filters
📈 Showing: 30.0%                ← Percentage filtered
```

---

## Advanced Use Cases

### Use Case 1: Research on Data Protection (2016-2020)
**Goal**: Study evolution of data protection regulations

**Filters**:
- Types: `REG`, `DIR`, `DEC`
- Years: `2016`, `2017`, `2018`, `2019`, `2020`

**Workflow**:
1. Download with filters
2. Extract metadata with same filters
3. Analyze JSON files for data protection keywords

### Use Case 2: Implementing Legislation Analysis
**Goal**: Study how regulations are implemented

**Filters**:
- Types: `REG-IMPL`, `DIR-IMPL`, `DEC-IMPL`
- Years: `2020`, `2021`, `2022`

**Result**: Only implementing acts from recent years

### Use Case 3: Yearly Legislation Tracking
**Goal**: Track all legislation by year

**Strategy**:
```
Week 1: Download & extract 2020 (all types)
Week 2: Download & extract 2021 (all types)  
Week 3: Download & extract 2022 (all types)
Week 4: Download & extract 2023 (all types)
```

**Benefit**: Organized by year, easier to analyze trends

---

## Performance Tips

### 1. **Filter First, Download Later**
✅ Filter to 1,000 documents → Download in 20 minutes
❌ Download 24,000 documents → 8+ hours

### 2. **Use Batch Sizes with Filters**
```
Filter: 1,234 documents
Batch Size: 500
Result: Download 500 of the 1,234 filtered documents
```

### 3. **Process Overnight**
```
Evening: Set filters for large set
Click: Start Download/Extraction
Morning: Check results!
```

### 4. **Incremental Processing**
```
Day 1: Types = REG, Years = 2020 (300 docs)
Day 2: Types = DIR, Years = 2020 (200 docs)
Day 3: Types = DEC, Years = 2020 (150 docs)
→ More manageable chunks!
```

---

## Troubleshooting

### Filter Shows 0 Documents
**Cause**: No documents match your filter combination
**Fix**: 
- Check if year exists in your data
- Try broader filters
- Click "All Types" and "All Years" to reset

### Filter Not Updating
**Cause**: Streamlit state not refreshing
**Fix**: 
- Click a quick filter button to force refresh
- Restart the Streamlit app

### Wrong Documents Being Processed
**Cause**: Filters not applied correctly
**Fix**:
- Check the "Active Filters" display at top
- Verify sidebar shows correct filtered count
- Restart processing if needed

---

## Summary

### Key Benefits
✅ **Targeted processing** - Get exactly what you need
✅ **Time savings** - Process smaller, focused batches
✅ **Resource control** - Manage bandwidth and disk space
✅ **Testing friendly** - Test on small subsets first
✅ **Incremental approach** - Break large jobs into manageable pieces

### Remember
- Empty filters = ALL documents
- Multiple selections = OR logic (REG **OR** DIR)
- Combine type + year for powerful targeting
- Use quick filter buttons to reset
- Check filter stats before starting

---

## Quick Reference

| Action | Downloader | Extractor |
|--------|-----------|-----------|
| Open UI | `streamlit run cellar_downloader_ui.py` | `streamlit run cellar_metadata_extractor_ui.py` |
| Filter by Type | Sidebar → Document Types | Sidebar → Document Types |
| Filter by Year | Sidebar → Years | Sidebar → Years |
| Reset Filters | Click "All Types" / "All Years" | Click "All Types" / "All Years" |
| See Active Filters | Top of main area (blue box) | Top of main area (blue box) |
| Filter Stats | Sidebar (bottom) | Sidebar (bottom) |

Happy filtering! 🎉




