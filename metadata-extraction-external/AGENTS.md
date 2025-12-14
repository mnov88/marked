# Repository Guidelines

> **📖 Primary Documentation:** [EURLEX_METADATA_EXTRACTION_GUIDE.md](EURLEX_METADATA_EXTRACTION_GUIDE.md) - Comprehensive guide for EUR-Lex metadata extraction (legislation + case law)

## Project Structure & Module Organization
- This folder houses Python tools for CELLAR/EUR-Lex download and metadata extraction; the Swift app lives in `../markdowned/` (separate).
- Downloaders: `cellar_downloader_ui.py` (standard Streamlit), `cellar_downloader_fast.py` (10–15x faster UI), and `cellar_downloader_cli.py` (ThreadPool CLI, see `CLI_DOWNLOADER_GUIDE.md`/`CLI_QUICK_REFERENCE.md`). Case-law downloader: `case_downloader.py` (pulls case notices from CELEX lists or scanned legislation metadata).
- Extractors: `cellar_metadata_extractor.py` (primary CLI), `cellar_metadata_extractor_ui.py` (Streamlit), plus `eurlex_metadata_extractor.py` and `_enhanced.py`; XPath map in `cellar_xpath_config.json` (see `CELLAR_EXTRACTOR_README.md`). Case-law extractor: `case_metadata_extractor.py` with `case_xpath_config.json`.
- Reference docs: `QUICK_START.md` (sanity path), `FAST_VERSION_GUIDE.md` (speed knobs), `METADATA_QUICK_REFERENCE.md` (fields), filtering and performance summaries. Do not commit regenerated logs or CSVs (`eurlex_metadata*.csv`, `metadata_extraction.log`, `sample_output.json`).

## Tooling & Setup
- Python 3.x with `streamlit`, `requests`, `lxml`, and `tqdm`. Install per doc examples (`pip3 install lxml tqdm streamlit`).
- CSV inputs live alongside scripts (`eurlex_metadata_enhanced.csv`); outputs go under your chosen target root (e.g., `/Users/milos/Coding/eurlex-organized`).

## Build, Test, and Development Commands
- Fast UI downloader (preferred for bulk): `streamlit run cellar_downloader_fast.py` (speed/ETA metrics; pooling, no blanket sleep).
- Standard UI downloader (safe/small batches): `streamlit run cellar_downloader_ui.py`.
- CLI downloader for peak throughput: `python3 cellar_downloader_cli.py --csv eurlex_metadata_enhanced.csv --output <dir> [--types REG DIR --years 2021 2022 --workers 20 --limit 50]`.
- Metadata extraction CLI: `python3 cellar_metadata_extractor.py --root <eurlex_root> [--limit N --verbose --no-skip-existing]`; single folder via `--folder <path>`.
- Metadata extraction UI: `streamlit run cellar_metadata_extractor_ui.py` and set the root path.
- Case notices: `python3 case_downloader.py --from-legislation-root <metadata_root> --output <case_root> [--limit N]`; parse with `python3 case_metadata_extractor.py --root <case_root> --verbose` (legislation-aligned schema, parsed article refs).

## Coding Style & Naming Conventions
- Python, 4-space indent, snake_case for files/vars and descriptive flags (`--root`, `--limit`, `--verbose`).
- Keep modules focused (no monolithic scripts); minimize imports to what is used. Log CELEX IDs and counts instead of full payloads.

## Testing & Validation
- No automated suite; rely on quick checks from `QUICK_START.md` (GDPR sample run). Verify outputs with `jq` (CELEX, document date, primary title) and diff against `sample_output.json` when adjusting XPath or metadata fields.
- For downloader changes, dry-run with `--limit 10 --workers 3`, confirm skips/resume behavior, and note any rate-limit handling differences (see fast vs standard in `FAST_VERSION_GUIDE.md`).

## Commit & Pull Request Guidelines
- Use short, imperative commits (`Improve fast downloader retries`, `Adjust XPath for CELEX`).
- In PRs, include scope, commands used to verify (CLI/UI), any data artifacts produced (but not committed), and performance/behavior notes between fast and standard paths. Avoid adding large datasets or logs; document repro steps instead.
