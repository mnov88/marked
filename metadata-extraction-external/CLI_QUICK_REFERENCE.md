# CELLAR CLI - Quick Reference Card 🚀

## Essential Commands

### 1️⃣ See What's Available
```bash
./cellar_downloader_cli.py --csv eurlex_metadata_enhanced.csv --list-filters
```

### 2️⃣ Download Everything (Default 10 Workers)
```bash
./cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /Users/milos/Coding/eurlex-organized
```

### 3️⃣ Download 2021 Regulations (Fast)
```bash
./cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /Users/milos/Coding/eurlex-organized \
  --types REG \
  --years 2021 \
  --workers 20
```

### 4️⃣ Download Multiple Types and Years
```bash
./cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /Users/milos/Coding/eurlex-organized \
  --types REG DIR DEC \
  --years 2020 2021 2022 \
  --workers 20
```

### 5️⃣ Test Small Batch First
```bash
./cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /Users/milos/Coding/eurlex-organized \
  --limit 10 \
  --workers 3
```

### 6️⃣ Resume from Index
```bash
./cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /Users/milos/Coding/eurlex-organized \
  --start 500
```

### 7️⃣ Maximum Speed (30 Workers)
```bash
./cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /Users/milos/Coding/eurlex-organized \
  --workers 30
```

## Common Document Types

| Code | Description |
|------|-------------|
| REG | Regulations |
| DIR | Directives |
| DEC | Decisions |
| REC | Recommendations |
| DECIMP | Implementing Decisions |
| DECDEL | Delegated Decisions |
| DIRIMP | Implementing Directives |
| DIRDEL | Delegated Directives |

## Quick Options

| Flag | What It Does | Example |
|------|--------------|---------|
| `--types` | Filter by document type | `--types REG DIR` |
| `--years` | Filter by year | `--years 2020 2021` |
| `--workers` | Concurrent threads | `--workers 20` |
| `--limit` | Max documents | `--limit 100` |
| `--start` | Resume from index | `--start 500` |
| `--timeout` | Request timeout | `--timeout 60` |

## Speed Guide

| Workers | Speed | Use Case |
|---------|-------|----------|
| 5 | ~25 docs/sec | Slow/unstable network |
| 10 | ~50 docs/sec | Default (safe) |
| 20 | ~100 docs/sec | Fast network |
| 30+ | ~150+ docs/sec | Maximum speed |

## Expected Performance

```
1,000 documents with 20 workers:
- Time: ~25 seconds
- Speed: ~40 docs/sec
- 40x faster than Streamlit version
```

## Troubleshooting

**Too many errors?**
```bash
--workers 5 --timeout 60
```

**Too many open files?**
```bash
ulimit -n 4096
./cellar_downloader_cli.py ...
```

**Not sure which year/type?**
```bash
./cellar_downloader_cli.py --csv eurlex_metadata_enhanced.csv --list-filters
```

## Progress Bar

While running, you'll see:
```
⚡ Downloading: 45%|████▌     | 450/1000 [00:12<00:15, 37.5doc/s] OK:420 SKIP:25 ERR:5
```

- **OK**: Successfully downloaded
- **SKIP**: Already exists
- **ERR**: Failed (details at end)

## Pro Tips

✅ **Test first**: Use `--limit 10 --workers 3` to verify setup  
✅ **Resume safe**: Script skips existing files automatically  
✅ **Scale up**: Start with 10 workers, increase if stable  
✅ **Batch by year**: Process one year at a time for organization  
✅ **Check errors**: Review error list at end, re-run if needed  

---

**Need more details?** See `CLI_DOWNLOADER_GUIDE.md` 📖



