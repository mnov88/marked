#!/usr/bin/env python3
"""
Convert allcases.csv to eurlex.db SQLite database with FTS5 full-text search.

This creates a compact database optimized for case law search in the iOS app.
"""

import csv
import sqlite3
import uuid
import re
from pathlib import Path
from datetime import datetime

# Paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent
CSV_PATH = PROJECT_DIR / "markdowned" / "allcases.csv"
DB_PATH = PROJECT_DIR / "markdowned" / "eurlex.db"

def extract_year_from_celex(celex: str) -> int:
    """Extract year from CELEX number (e.g., 62008CJ0250 -> 2008)"""
    match = re.search(r'6(\d{4})', celex)
    if match:
        return int(match.group(1))
    return 0

def extract_case_number_for_sort(case_number: str) -> tuple:
    """Extract sortable components from case number for ranking."""
    # Extract the main case number for sorting (e.g., C-250/08 -> (250, 8))
    match = re.search(r'C-(\d+)/(\d+)', case_number)
    if match:
        return (int(match.group(2)), int(match.group(1)))  # (year, number)
    return (0, 0)

def parse_csv_line(line: str) -> list:
    """Parse CSV line handling quoted fields."""
    fields = []
    current = ""
    in_quotes = False

    for char in line:
        if char == '"':
            in_quotes = not in_quotes
        elif char == ',' and not in_quotes:
            fields.append(current.strip())
            current = ""
        else:
            current += char

    fields.append(current.strip())
    return fields

def create_database():
    """Create SQLite database with FTS5 from CSV."""

    # Remove existing database
    if DB_PATH.exists():
        DB_PATH.unlink()
        print(f"Removed existing database: {DB_PATH}")

    conn = sqlite3.connect(str(DB_PATH))
    cursor = conn.cursor()

    # Create case_law table matching the schema
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS case_law (
            id TEXT PRIMARY KEY,
            celex TEXT NOT NULL UNIQUE,
            ecli TEXT,
            case_number TEXT,
            title TEXT,
            short_title TEXT,
            parties TEXT,
            court TEXT,
            procedure_type TEXT,
            origin_country TEXT,
            date_judgment TEXT,
            date_request TEXT,
            doc_year INTEGER,
            has_ag_opinion INTEGER DEFAULT 0,
            ag_opinion_title TEXT,
            ag_opinion_ecli TEXT,
            has_summary INTEGER DEFAULT 0,
            summary_celex TEXT,
            requesting_court TEXT,
            topics TEXT,
            imported_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )
    """)

    # Create indexes for efficient querying
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_case_law_celex ON case_law(celex)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_case_law_ecli ON case_law(ecli)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_case_law_year ON case_law(doc_year)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_case_law_case_number ON case_law(case_number)")

    # Create FTS5 virtual table for full-text search
    cursor.execute("""
        CREATE VIRTUAL TABLE IF NOT EXISTS case_law_fts USING fts5(
            case_number,
            title,
            parties,
            topics,
            requesting_court,
            celex,
            content='case_law',
            content_rowid='rowid',
            tokenize='unicode61 remove_diacritics 2'
        )
    """)

    # Create triggers to keep FTS in sync
    cursor.execute("""
        CREATE TRIGGER case_law_ai AFTER INSERT ON case_law BEGIN
            INSERT INTO case_law_fts(rowid, case_number, title, parties, topics, requesting_court, celex)
            VALUES (NEW.rowid, NEW.case_number, NEW.title, NEW.parties, NEW.topics, NEW.requesting_court, NEW.celex);
        END
    """)

    cursor.execute("""
        CREATE TRIGGER case_law_ad AFTER DELETE ON case_law BEGIN
            INSERT INTO case_law_fts(case_law_fts, rowid, case_number, title, parties, topics, requesting_court, celex)
            VALUES ('delete', OLD.rowid, OLD.case_number, OLD.title, OLD.parties, OLD.topics, OLD.requesting_court, OLD.celex);
        END
    """)

    cursor.execute("""
        CREATE TRIGGER case_law_au AFTER UPDATE ON case_law BEGIN
            INSERT INTO case_law_fts(case_law_fts, rowid, case_number, title, parties, topics, requesting_court, celex)
            VALUES ('delete', OLD.rowid, OLD.case_number, OLD.title, OLD.parties, OLD.topics, OLD.requesting_court, OLD.celex);
            INSERT INTO case_law_fts(rowid, case_number, title, parties, topics, requesting_court, celex)
            VALUES (NEW.rowid, NEW.case_number, NEW.title, NEW.parties, NEW.topics, NEW.requesting_court, NEW.celex);
        END
    """)

    conn.commit()

    # Parse and insert data from CSV
    now = datetime.now().isoformat()
    inserted = 0
    skipped = 0

    with open(CSV_PATH, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)  # Skip header
        print(f"CSV Header: {header}")

        for row in reader:
            if len(row) < 11:
                skipped += 1
                continue

            case_number = row[0].strip()
            case_title = row[1].strip()
            requesting_court = row[2].strip()
            topics = row[3].strip()
            judgment_ecli = row[4].strip()
            judgment_celex = row[5].strip()
            has_ag_opinion = row[6].strip().lower() == 'yes'
            ag_opinion_title = row[7].strip()
            ag_opinion_ecli = row[8].strip()
            has_summary = row[9].strip().lower() == 'yes'
            summary_celex = row[10].strip() if len(row) > 10 else ""

            # Skip if no CELEX (required field)
            if not judgment_celex:
                skipped += 1
                continue

            # Extract year from CELEX
            doc_year = extract_year_from_celex(judgment_celex)

            # Extract parties from title (format: "Case C-xxx/xx. PartyA v PartyB")
            parties = ""
            if ". " in case_title:
                parties = case_title.split(". ", 1)[1] if ". " in case_title else ""

            case_id = str(uuid.uuid4())

            try:
                cursor.execute("""
                    INSERT INTO case_law (
                        id, celex, ecli, case_number, title, short_title,
                        parties, court, procedure_type, origin_country,
                        date_judgment, date_request, doc_year,
                        has_ag_opinion, ag_opinion_title, ag_opinion_ecli,
                        has_summary, summary_celex, requesting_court, topics,
                        imported_at, updated_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    case_id,
                    judgment_celex,
                    judgment_ecli,
                    case_number,
                    case_title,
                    case_number,  # short_title = case_number
                    parties,
                    "CJEU",  # Default court
                    None,  # procedure_type
                    None,  # origin_country
                    None,  # date_judgment
                    None,  # date_request
                    doc_year,
                    1 if has_ag_opinion else 0,
                    ag_opinion_title,
                    ag_opinion_ecli,
                    1 if has_summary else 0,
                    summary_celex,
                    requesting_court,
                    topics,
                    now,
                    now
                ))
                inserted += 1
            except sqlite3.IntegrityError as e:
                # Duplicate CELEX - skip
                skipped += 1
                continue

    conn.commit()

    # Rebuild FTS index
    cursor.execute("INSERT INTO case_law_fts(case_law_fts) VALUES('rebuild')")
    conn.commit()

    # Print statistics
    cursor.execute("SELECT COUNT(*) FROM case_law")
    total = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM case_law_fts")
    fts_count = cursor.fetchone()[0]

    print(f"\nDatabase created: {DB_PATH}")
    print(f"  - Inserted: {inserted} cases")
    print(f"  - Skipped: {skipped} rows")
    print(f"  - Total in case_law: {total}")
    print(f"  - Total in FTS index: {fts_count}")

    # Test FTS search
    print("\nTesting FTS search for 'Commission'...")
    cursor.execute("""
        SELECT case_number, title, bm25(case_law_fts) as rank
        FROM case_law_fts
        WHERE case_law_fts MATCH 'Commission'
        ORDER BY rank
        LIMIT 5
    """)
    for row in cursor.fetchall():
        print(f"  {row[0]}: {row[1][:60]}... (rank: {row[2]:.4f})")

    # Get file size
    conn.close()
    size_mb = DB_PATH.stat().st_size / (1024 * 1024)
    print(f"\nDatabase size: {size_mb:.2f} MB")

    return DB_PATH

if __name__ == "__main__":
    create_database()
