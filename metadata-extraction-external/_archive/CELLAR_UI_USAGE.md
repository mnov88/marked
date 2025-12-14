# CELLAR Downloader UI - Quick Start Guide

## 🚀 Launch the UI

```bash
cd /Users/milos/Desktop/markdowned
streamlit run cellar_downloader_ui.py
```

The app will open automatically at: **http://localhost:8501**

## ✨ Features

### 📊 Live Dashboard
- **Real-time progress bar** - See exactly how far along you are
- **Live stats** - Success, failed, skipped counts update as you go
- **Recent downloads** - Last 10 downloads with status indicators

### ⏯️ Full Control
- **▶️ Start** - Begin downloading from specified index
- **⏸️ Pause** - Pause anytime, resume later
- **▶️ Resume** - Pick up exactly where you left off
- **🔄 Reset** - Clear stats and start fresh

### ⚙️ Configurable Settings (Sidebar)
- **CSV Path** - Path to your metadata CSV
- **Output Root** - Where to save XMLs
- **Delay** - Rate limiting (default: 1 second, faster than CLI!)
- **Batch Size** - How many docs to download (default: 100)
- **Start Index** - Resume from specific document

## 🎯 Typical Workflow

### 1. Test Run (10 docs)
1. Launch the UI
2. Set **Batch Size** to `10`
3. Set **Start Index** to `0`
4. Click **▶️ Start Download**
5. Watch the progress!

### 2. Medium Run (100 docs)
1. Set **Batch Size** to `100`
2. Click **▶️ Start Download**
3. Leave it running (takes ~2 minutes)

### 3. Full Run (24K docs)
1. Set **Batch Size** to `24000`
2. Click **▶️ Start Download**
3. If you need to stop:
   - Click **⏸️ Pause**
   - Note the current index
   - Resume later with **▶️ Resume**

## 💡 Pro Tips

### Pause & Resume
- Pausing saves your progress automatically
- Resume continues from the exact document
- Perfect for overnight downloads with breaks

### Error Handling
- Errors show in expandable section at bottom
- Failed downloads don't stop the batch
- 404 errors are normal (some docs unavailable)

### Speed
- **1 second delay** (vs 2 seconds in CLI)
- Downloads ~3,600 docs/hour
- Full 24K dataset: ~6.5 hours

### Monitor Progress
- Progress bar shows % complete
- "Remaining" metric counts down
- Recent downloads scroll automatically

## 🐛 Troubleshooting

**"Connection timeout"**
- Normal for some docs
- Download continues automatically

**"UI becomes unresponsive"**
- Streamlit reruns on each download
- Slight delay is normal
- Progress is saved, safe to refresh

**"Want to change batch mid-run"**
- Pause first
- Change batch size
- Resume (continues with new settings)

## 📊 Stats Explained

- **✅ Success** - Downloaded successfully
- **❌ Failed** - HTTP errors, timeouts (expanded view shows details)
- **⏭️ Skipped** - File already exists
- **📊 Remaining** - Documents left in current batch

## 🎨 UI vs CLI Comparison

| Feature | CLI | Streamlit UI |
|---------|-----|--------------|
| Progress bar | ❌ | ✅ Real-time |
| Pause/Resume | ❌ | ✅ One-click |
| Live stats | ❌ | ✅ Auto-update |
| Recent downloads | ❌ | ✅ Last 10 |
| Batch control | Code edit | ✅ UI slider |
| Error view | Terminal | ✅ Expandable |
| Speed | 2s delay | ✅ 1s delay |

## 🚦 Status Indicators

- 🟢 **Green** - Success
- 🔴 **Red** - Error (see details in expandable)
- 🔵 **Blue** - Skipped (already downloaded)
- 🟡 **Yellow** - Currently downloading

---

**Created**: November 6, 2025  
**UI Version**: v1.0 with pause/resume  
**Recommended**: Use UI for all downloads! 🎉




