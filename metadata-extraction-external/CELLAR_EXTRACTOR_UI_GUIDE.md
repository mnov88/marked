# CELLAR Metadata Extractor - Streamlit UI Guide

## Quick Start

### Launch the UI

```bash
cd /Users/milos/Desktop/markdowned
streamlit run cellar_metadata_extractor_ui.py
```

The UI will open at: `http://localhost:8501`

## Features

### 🎛️ Control Panel
- **Start Extraction**: Begin processing documents
- **Pause**: Temporarily pause extraction
- **Resume**: Continue from where you paused
- **Stop**: Stop extraction completely

### ⚙️ Configuration (Sidebar)
- **Root Directory**: Path to organized document folders
- **Document Limit**: Max documents to process (0 = all)
- **Skip Existing Files**: Skip documents with existing JSON
- **XPath Config File**: Custom XPath configuration path

### 📊 Three Tabs

#### 1. Extraction Tab
- **Real-time progress bar**: Visual progress indicator
- **Live statistics**: Success, failed, skipped counts
- **Processing time**: Elapsed time tracking
- **Recent documents**: Last 10 processed documents with status
- **Error details**: Expandable section for failed extractions

#### 2. Statistics Tab
- **Aggregate totals**: Sum of all extracted metadata
  - Total languages
  - Total case law entries
  - Total Eurovoc concepts
  - Total articles parsed
  - Total legal relations
  - Total implementations
- **Averages**: Per-document averages
- **Performance metrics**: Processing rate and time per document

#### 3. Sample Output Tab
- **JSON structure**: Example output format
- **Field list**: Complete list of extracted fields

## Usage Examples

### Process All Documents

1. Launch UI
2. Set Root Directory: `/Users/milos/Coding/eurlex-organized`
3. Set Document Limit: `0` (all)
4. Check "Skip Existing Files"
5. Click "Start Extraction"

### Process Small Test Batch

1. Launch UI
2. Set Document Limit: `10`
3. Check "Skip Existing Files"
4. Click "Start Extraction"
5. Watch progress in real-time

### Resume Processing

If you pause or stop:
1. Configure same settings as before
2. Ensure "Skip Existing Files" is checked
3. Click "Start Extraction" again
4. It will continue from where it left off

## UI Screenshots (Mockup)

```
┌─────────────────────────────────────────────────────────────────┐
│ 📊 CELLAR Metadata Extractor                                   │
├─────────────────────────────────────────────────────────────────┤
│ Extract comprehensive metadata from CELLAR tree XML notices...  │
│                                                                  │
│ [▶️ Start] [⏸️ Pause] [▶️ Resume] [⏹️ Stop]                     │
│                                                                  │
│ Processing: REG-2016-679 (5/100)                                │
│ [████████░░░░░░░░░░░░░] 5%                                      │
│                                                                  │
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐              │
│ │ Success │ │ Failed  │ │ Skipped │ │  Time   │              │
│ │   5     │ │   0     │ │   0     │ │ 00:00:10│              │
│ └─────────┘ └─────────┘ └─────────┘ └─────────┘              │
│                                                                  │
│ 📄 Recent Documents                                             │
│ ✅ REG-2016-679 (32016R0679) - 14:23:45                        │
│ ✅ DEC-2019-236 (32019D0236) - 14:23:42                        │
│ ✅ REG-IMPL-2019-921 (32019R0921) - 14:23:39                   │
└─────────────────────────────────────────────────────────────────┘
```

## Comparison: CLI vs UI

| Feature | CLI | Streamlit UI |
|---------|-----|--------------|
| **Speed** | ⚡ Fast | 🐌 Slightly slower (UI updates) |
| **Progress** | Text only | Visual progress bar |
| **Pause/Resume** | ❌ No | ✅ Yes |
| **Statistics** | End summary | Real-time + aggregate |
| **Monitoring** | Manual | Live updates |
| **Background** | ✅ Can run in tmux | ⚠️ Browser needed |
| **Automation** | ✅ Easy to script | ⚠️ Interactive |

## When to Use Each

### Use CLI When:
- Processing large batches (1000+ docs)
- Running on remote server
- Automation/scripting needed
- Want maximum speed
- No monitoring needed

### Use Streamlit UI When:
- Need visual progress
- Want to pause/resume
- Monitoring extraction process
- Exploring smaller batches
- Prefer interactive interface
- Want live statistics

## Performance Notes

- **UI adds ~0.1-0.2s overhead** per document due to UI updates
- For 24K documents: CLI ~3.5 hours vs UI ~4-5 hours
- UI is better for batches < 1000 documents
- CLI is better for full dataset processing

## Tips

1. **Test First**: Use limit of 5-10 docs to verify configuration
2. **Skip Existing**: Always enable to avoid reprocessing
3. **Monitor Stats**: Check Statistics tab for aggregate data
4. **Check Errors**: Expand error section if any failures
5. **Browser Tab**: Keep browser tab open during processing

## Troubleshooting

### UI Won't Start
```bash
pip3 install streamlit
streamlit run cellar_metadata_extractor_ui.py
```

### Processing Stops
- Check if browser tab is closed
- Restart UI and enable "Skip Existing Files"
- Check error section for details

### Slow Performance
- Close other browser tabs
- Reduce document limit
- Use CLI for large batches

## Output

Both CLI and UI produce identical output:
- `{CELEX}_metadata.json` in each document folder
- Same JSON structure
- Same extracted fields

## Next Steps

After extracting metadata:
1. View Statistics tab for aggregate data
2. Check individual JSON files for detailed metadata
3. Use extracted data for analysis, visualization, or database import

---

**Created**: November 7, 2025  
**Status**: Ready to use  
**Features**: Progress tracking, stats dashboard, pause/resume  




