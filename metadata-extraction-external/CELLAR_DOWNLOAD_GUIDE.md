# CELLAR XML Downloader - Usage Guide

## 🎉 What We Accomplished

✅ **Successfully tested** downloading CELLAR tree XML notices from EUR-Lex API  
✅ **Downloaded GDPR** (REG-2016-679) - 1.6 MB with 35,465 lines  
✅ **Batch tested** 10 documents - 90% success rate  
✅ **Organized storage** - XMLs saved alongside existing documents  

## 📊 CELLAR XML vs RDF Comparison

| Metadata Type | RDF Files | CELLAR Tree XML |
|---------------|-----------|-----------------|
| **Case law refs** | 0-5 | **138** (for GDPR!) |
| **Languages** | Limited | **All 36 EU languages** |
| **Article details** | Basic | **Detailed with annotations** |
| **Alternative titles** | Some | **Full multilingual** |
| **File size** | ~50 KB | **1-2 MB (20-40x richer!)** |

## 🚀 Usage - Two Versions Available!

### 🎨 **RECOMMENDED: Streamlit UI Version** (New!)
Beautiful interface with progress bar, pause/resume, and live stats!

```bash
cd /Users/milos/Desktop/markdowned
streamlit run cellar_downloader_ui.py
```

**Features:**
- ✅ Real-time progress bar
- ✅ Pause/Resume with one click
- ✅ Live statistics dashboard
- ✅ Recent downloads view
- ✅ **1 second delay** (2x faster!)
- ✅ Easy batch size control

See `CELLAR_UI_USAGE.md` for full UI guide.

---

### 💻 **CLI Version** (Original)

#### Option 1: Test Single Document
```bash
cd /Users/milos/Desktop/markdowned
python3 cellar_downloader.py
```

This runs the GDPR test and exits (safe to run anytime).

### Option 2: Small Batch (10 docs)
Edit `cellar_downloader.py` and uncomment the small batch section:
```python
download_from_csv_batch(
    csv_path="/Users/milos/Desktop/markdowned/eurlex_metadata_enhanced.csv",
    organized_root="/Users/milos/Coding/eurlex-organized",
    batch_size=10,
    start_index=0
)
```

### Option 3: Medium Batch (100 docs - ~3.5 minutes)
Use `batch_size=100`

### Option 4: Full Dataset (24K docs - ~13 hours)
Use `batch_size=24076`

## ⚠️ Important Notes

1. **Rate Limiting**: 2-second delay between requests (respectful to EUR-Lex)
2. **Resume Support**: Skips already-downloaded files automatically
3. **Some Failures Expected**: Documents with special chars (like `R(08)`) may 404
4. **Disk Space**: ~25-35 GB for full 24K dataset
5. **Run Overnight**: Full download takes ~13 hours

## 📁 File Structure

Files are saved to:
```
/Users/milos/Coding/eurlex-organized/
├── REG/
│   └── REG-2016-679/
│       ├── fmx4/                           (original FMX files)
│       └── cellar_tree_notice.xml         (NEW: full metadata!)
├── DIR/
│   └── DIR-2024-1234/
│       └── cellar_tree_notice.xml
└── ...
```

## 🧠 Next Steps: Parsing Options

### Option A: Use Your JS App (Recommended for now)
1. Open XMLs manually in browser-based app
2. Your app already has all the XPath mappings
3. Good for exploration and validation

### Option B: Python Batch Parser (Future)
Create a Python script that:
1. Reads `enhanced_xpath_mappings.json`
2. Applies XPath to all downloaded XMLs
3. Outputs enhanced CSV with case law + alternative titles
4. Can reuse your existing mappings!

Example structure:
```python
import json
from lxml import etree

# Load your mappings
with open('enhanced_xpath_mappings.json') as f:
    mappings = json.load(f)

# Parse XML
tree = etree.parse('cellar_tree_notice.xml')

# Apply XPath from mappings
cases = tree.xpath(mappings['case_law']['interpreted_by_celex'])
titles = tree.xpath(mappings['title']['alternative_title'])
```

## 💡 Recommendations

1. **Start small**: Run 100-doc batch first to verify everything works
2. **Run overnight**: For full 24K dataset
3. **Monitor first hour**: Watch for any repeated errors
4. **Parse later**: Focus on downloading first, parsing second

## 🐛 Troubleshooting

**"Connection timeout"**: Normal for some docs, script auto-retries  
**"404 Not Found"**: Some docs not available via API (corrigenda, old docs)  
**"Too many requests"**: Increase delay from 2 to 3 seconds  

## 📈 Expected Results

- **Success rate**: ~95% (23K docs)
- **Failed docs**: ~5% (special chars, old formats)
- **Total time**: ~13 hours for full dataset
- **Disk space**: ~30 GB

## 🎨 UI vs CLI - Which to Use?

| Feature | CLI (`cellar_downloader.py`) | Streamlit UI (`cellar_downloader_ui.py`) |
|---------|------------------------------|------------------------------------------|
| **Progress Tracking** | Terminal text only | ✅ Visual progress bar |
| **Pause/Resume** | Manual (edit code) | ✅ One-click buttons |
| **Live Stats** | End of batch only | ✅ Real-time updates |
| **Recent Downloads** | None | ✅ Last 10 with status |
| **Error Details** | Terminal output | ✅ Expandable view |
| **Batch Control** | Edit code | ✅ UI controls |
| **Speed (delay)** | 2 seconds | ✅ 1 second (2x faster!) |
| **Visual Feedback** | Text only | ✅ Colors, emojis, charts |
| **Learning Curve** | Code editing | ✅ Point and click |
| **Background Running** | ✅ With `nohup` | Browser tab |

### 💡 Recommendation
- **Use Streamlit UI** for interactive downloads and testing
- **Use CLI** for automated/scripted deployments or background jobs

---

**Created**: November 6, 2025  
**Status**: ✅ Tested and working  
**Scripts**: 
- CLI: `cellar_downloader.py`
- UI: `cellar_downloader_ui.py` ⭐ **Recommended**

