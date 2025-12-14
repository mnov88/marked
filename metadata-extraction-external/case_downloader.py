#!/usr/bin/env python3
"""
Case-law CELLAR downloader

Use cases:
- Pull case notices for all case references found in existing legislation metadata JSONs
- Or pull a provided list of case CELEX IDs

Outputs: downloads each notice to <output>/CASE/<CELEX>/cellar_case_notice.xml
"""

import argparse
import json
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
from threading import Lock
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from tqdm import tqdm


def create_session(timeout: int) -> requests.Session:
    """Session with pooling and retries."""
    session = requests.Session()
    retry_strategy = Retry(
        total=3,
        status_forcelist=[429, 500, 502, 503, 504],
        backoff_factor=1,
        allowed_methods=["GET"]
    )
    adapter = HTTPAdapter(max_retries=retry_strategy, pool_connections=10, pool_maxsize=10)
    session.mount("http://", adapter)
    session.mount("https://", adapter)
    session.headers.update({
        "Accept": "application/xml;notice=tree",
        "Accept-Language": "eng",
        "User-Agent": "EUR-Lex Case Downloader/1.0"
    })
    session.timeout = timeout
    return session


class DownloadStats:
    """Thread-safe counters."""
    def __init__(self) -> None:
        self.lock = Lock()
        self.success = 0
        self.failed = 0
        self.skipped = 0
        self.errors = []

    def add_success(self) -> None:
        with self.lock:
            self.success += 1

    def add_failed(self, celex: str, msg: str) -> None:
        with self.lock:
            self.failed += 1
            self.errors.append((celex, msg))

    def add_skipped(self) -> None:
        with self.lock:
            self.skipped += 1


def download_case(session: requests.Session, celex: str, output_file: Path, timeout: int) -> tuple[bool, str]:
    """Fetch a case notice by CELEX."""
    url = f"https://publications.europa.eu/resource/celex/{celex}"
    try:
        resp = session.get(url, allow_redirects=True, timeout=timeout)
        if resp.status_code == 200:
            output_file.parent.mkdir(parents=True, exist_ok=True)
            output_file.write_bytes(resp.content)
            return True, "OK"
        return False, f"HTTP {resp.status_code}"
    except requests.exceptions.Timeout:
        return False, "Timeout"
    except Exception as exc:  # pragma: no cover - defensive
        return False, str(exc)


def extract_cases_from_legislation(root: Path) -> set[str]:
    """Scan legislation metadata JSONs for case CELEX values."""
    cases: set[str] = set()
    for json_file in root.rglob("*_metadata.json"):
        try:
            data = json.loads(json_file.read_text(encoding="utf-8"))
        except Exception:
            continue
        caselaw = data.get("document", {}).get("caselaw", [])
        for entry in caselaw:
            celex = (entry or {}).get("celex") or (entry or {}).get("celexId")
            if celex:
                cases.add(celex.strip())
    return cases


def load_cases_from_file(path: Path) -> set[str]:
    """Load CELEX IDs from a text file (one per line)."""
    cases: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        celex = line.strip()
        if celex:
            cases.add(celex)
    return cases


def worker(args: tuple[str, Path, int, DownloadStats]) -> dict:
    """Thread worker to download a single case."""
    celex, output_root, timeout, stats = args
    output_file = output_root / "CASE" / celex / "cellar_case_notice.xml"
    if output_file.exists():
        stats.add_skipped()
        return {"celex": celex, "status": "skipped"}

    session = create_session(timeout)
    ok, msg = download_case(session, celex, output_file, timeout)
    if ok:
        stats.add_success()
    else:
        stats.add_failed(celex, msg)
    return {"celex": celex, "status": "ok" if ok else "failed", "message": msg}


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Download CELLAR notices for case-law CELEX IDs."
    )
    parser.add_argument("--output", required=True, help="Output root directory for case notices.")
    parser.add_argument("--cases-file", help="Text file with one case CELEX per line.")
    parser.add_argument("--from-legislation-root", help="Folder containing *_metadata.json files to scan for case references.")
    parser.add_argument("--limit", type=int, help="Optional limit of cases to fetch.")
    parser.add_argument("--workers", type=int, default=10, help="Concurrent workers (default: 10).")
    parser.add_argument("--timeout", type=int, default=30, help="Request timeout in seconds.")
    args = parser.parse_args()

    if not args.cases_file and not args.from_legislation_root:
        parser.error("Provide --cases-file and/or --from-legislation-root.")

    cases: set[str] = set()
    if args.cases_file:
        cases |= load_cases_from_file(Path(args.cases_file))
    if args.from_legislation_root:
        cases |= extract_cases_from_legislation(Path(args.from_legislation_root))

    if not cases:
        raise SystemExit("No case CELEX IDs found.")

    celex_list = sorted(cases)
    if args.limit:
        celex_list = celex_list[: args.limit]

    output_root = Path(args.output)
    stats = DownloadStats()
    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        futures = [
            executor.submit(worker, (celex, output_root, args.timeout, stats))
            for celex in celex_list
        ]
        for _ in tqdm(as_completed(futures), total=len(futures), desc="Downloading cases"):
            pass

    print(f"Done. OK: {stats.success}, Skipped: {stats.skipped}, Failed: {stats.failed}")
    if stats.errors:
        print("Failures:")
        for celex, msg in stats.errors:
            print(f"  {celex}: {msg}")


if __name__ == "__main__":
    main()
