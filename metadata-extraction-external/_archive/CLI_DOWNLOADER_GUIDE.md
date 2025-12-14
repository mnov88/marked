# CELLAR XML Downloader - CLI Guide 🚀

## Why This Version is ACTUALLY Fast

The CLI version is **10-20x faster** than the Streamlit version because:

### 🐌 Streamlit Version Problems:
- **Full script rerun** every 10 documents (1-3 seconds overhead)
- **CSV reloaded** from disk on every rerun
- **Filter re-extraction** on every rerun
- **UI reconstruction** overhead
- **Sequential processing** (one document at a time)
- **Actual throughput: ~1-2 docs/sec**

### ⚡ CLI Version Advantages:
- **True concurrency** with ThreadPoolExecutor
- **10-50 parallel workers** downloading simultaneously
- **No UI overhead** (just a progress bar)
- **Connection pooling** per thread
- **CSV loaded once** at startup
- **Expected throughput: 50-100+ docs/sec**

## Installation

The script only requires `tqdm` for progress bars:

```bash
pip3 install tqdm
```

## Quick Start

### 1. List Available Filters

First, see what document types and years are available:

```bash
./cellar_downloader_cli.py --csv eurlex_metadata_enhanced.csv --list-filters
```

This will show:
- All available document types (REG, DIR, DEC, etc.)
- All available years with ranges

### 2. Download All Documents

Download everything with 10 concurrent workers (default):

```bash
./cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /Users/milos/Coding/eurlex-organized
```

### 3. Download Specific Types

Download only regulations:

```bash
./cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /Users/milos/Coding/eurlex-organized \
  --types REG
```

Download regulations and directives:

```bash
./cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /Users/milos/Coding/eurlex-organized \
  --types REG DIR
```

### 4. Download Specific Years

Download all documents from 2021:

```bash
./cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /Users/milos/Coding/eurlex-organized \
  --years 2021
```

Download from 2020-2022:

```bash
./cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /Users/milos/Coding/eurlex-organized \
  --years 2020 2021 2022
```

### 5. Combine Filters

Download only 2021 regulations:

```bash
./cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /Users/milos/Coding/eurlex-organized \
  --types REG \
  --years 2021
```

## Advanced Usage

### Increase Concurrency (FASTER!)

Use 30 concurrent workers for maximum speed:

```bash
./cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /Users/milos/Coding/eurlex-organized \
  --workers 30
```

**Note:** More workers = faster, but may hit rate limits or network bottlenecks. Start with 10-20 and increase if stable.

### Limit Number of Documents

Download only the first 100 documents:

```bash
./cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /Users/milos/Coding/eurlex-organized \
  --limit 100
```

### Resume from Specific Index

If download was interrupted, resume from document 500:

```bash
./cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /Users/milos/Coding/eurlex-organized \
  --start 500
```

### Increase Timeout

For slow networks, increase timeout to 60 seconds:

```bash
./cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /Users/milos/Coding/eurlex-organized \
  --timeout 60
```

## Complete Example: 2021 Regulations

Download all 2021 regulations with 20 workers:

```bash
./cellar_downloader_cli.py \
  --csv eurlex_metadata_enhanced.csv \
  --output /Users/milos/Coding/eurlex-organized \
  --types REG \
  --years 2021 \
  --workers 20
```

Expected output:
```
📂 Loading CSV: eurlex_metadata_enhanced.csv
✅ Loaded 7,822 documents

🔍 Active Filters:
  📋 Types: REG
  📅 Years: 2021

📊 Will process 1,234 documents
⚙️  Using 20 concurrent workers
📁 Output: /Users/milos/Coding/eurlex-organized
⏱️  Timeout: 30s per request

⚡ Downloading: 100%|████████████| 1234/1234 [00:15<00:00, 82.3doc/s] OK:1180 SKIP:45 ERR:9

============================================================
📊 DOWNLOAD COMPLETE
============================================================
⏱️  Time elapsed: 15.0s (0.2 min)
⚡ Average speed: 82.3 docs/sec
✅ Success: 1,180
⏭️  Skipped: 45 (already existed)
❌ Failed: 9
💾 Downloaded: 45.2 MB
============================================================
```

## All Command-Line Options

```bash
./cellar_downloader_cli.py --help
```

| Option | Description | Default |
|--------|-------------|---------|
| `--csv PATH` | Path to CSV file | **Required** |
| `--output PATH` | Output directory | **Required** |
| `--types TYPE [TYPE ...]` | Document types (REG, DIR, etc.) | All types |
| `--years YEAR [YEAR ...]` | Years to download | All years |
| `--start INDEX` | Start index (for resuming) | 0 |
| `--limit N` | Max documents to download | All |
| `--workers N` | Concurrent workers | 10 |
| `--timeout N` | Request timeout (seconds) | 30 |
| `--list-filters` | List available filters and exit | - |

## Performance Tips

### 1. **Optimal Worker Count**

Start with 10-20 workers. If you see high success rates and low timeouts, increase:

- **10 workers**: Safe, ~50-80 docs/sec
- **20 workers**: Fast, ~80-120 docs/sec
- **30+ workers**: Very fast, may hit rate limits

### 2. **Network Considerations**

- **Fast network + fast CPU**: Use 30+ workers
- **Slow network**: Use 10-15 workers, increase timeout
- **Unstable network**: Use 5-10 workers, timeout 60s

### 3. **Resume Failed Downloads**

If some downloads failed, run again with same filters. The script automatically skips existing files.

### 4. **Monitor Progress**

The progress bar shows real-time stats:
- **OK**: Successfully downloaded
- **SKIP**: Already existed (skipped)
- **ERR**: Failed (will show details at end)

## Troubleshooting

### "Too many open files" error

Reduce workers:
```bash
--workers 5
```

Or increase system limit:
```bash
ulimit -n 4096
```

### Timeouts

Increase timeout:
```bash
--timeout 60
```

### Rate Limiting

If you see many 429 errors, reduce workers:
```bash
--workers 5
```

### Wrong filters

Check available filters first:
```bash
./cellar_downloader_cli.py --csv eurlex_metadata_enhanced.csv --list-filters
```

## Comparison: CLI vs Streamlit

| Feature | Streamlit "Fast" | CLI (This) |
|---------|------------------|------------|
| Concurrency | Sequential | 10-50 parallel |
| Throughput | ~1-2 docs/sec | 50-100+ docs/sec |
| UI | Web interface | Terminal progress bar |
| Overhead | High (reruns) | Minimal |
| Filtering | Interactive | Command-line args |
| Resume | Manual | Automatic via `--start` |
| Scripting | No | Yes |

## Batch Processing Multiple Filters

You can create shell scripts for batch processing:

```bash
#!/bin/bash
# Download all regulations by year

for year in 2019 2020 2021 2022 2023; do
  echo "Downloading $year regulations..."
  ./cellar_downloader_cli.py \
    --csv eurlex_metadata_enhanced.csv \
    --output /Users/milos/Coding/eurlex-organized \
    --types REG \
    --years $year \
    --workers 20
done
```

## Summary

The CLI version is **dramatically faster** because:
1. ✅ True concurrent downloads (10-50 workers)
2. ✅ No Streamlit overhead (no reruns)
3. ✅ CSV loaded once
4. ✅ Connection pooling per thread
5. ✅ Minimal progress bar overhead

Expected real-world performance: **50-100+ docs/sec** vs Streamlit's ~1-2 docs/sec.

---

**Pro Tip**: Start with `--limit 10 --workers 5` to test, then scale up! 🚀



