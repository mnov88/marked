#!/usr/bin/env python3
"""
Add FTS5 full-text search tables to an existing eurlex.db

This script adds case_law_fts and legislation_fts virtual tables to enable
fast full-text search in the iOS app. Run this on your local eurlex.db before
copying to the app bundle.

Usage:
    python3 add_fts_to_eurlex.py /path/to/eurlex.db
    python3 add_fts_to_eurlex.py  # Uses default path: ../markdowned/eurlex.db
"""

import sqlite3
import sys
from pathlib import Path

# Default path relative to script location
SCRIPT_DIR = Path(__file__).parent
DEFAULT_DB_PATH = SCRIPT_DIR.parent / "markdowned" / "eurlex.db"


def add_fts_tables(db_path: Path):
    """Add FTS5 virtual tables to existing eurlex.db"""

    if not db_path.exists():
        print(f"Error: Database not found at {db_path}")
        return False

    print(f"Adding FTS5 tables to: {db_path}")

    conn = sqlite3.connect(str(db_path))
    cursor = conn.cursor()

    # Check if FTS tables already exist
    cursor.execute("""
        SELECT name FROM sqlite_master
        WHERE type='table' AND name IN ('case_law_fts', 'legislation_fts')
    """)
    existing = [row[0] for row in cursor.fetchall()]

    if existing:
        print(f"  FTS tables already exist: {', '.join(existing)}")
        response = input("  Drop and recreate? [y/N]: ").strip().lower()
        if response != 'y':
            print("  Aborted.")
            return False

        # Drop existing FTS tables and triggers
        for table in existing:
            cursor.execute(f"DROP TABLE IF EXISTS {table}")
            cursor.execute(f"DROP TRIGGER IF EXISTS {table.replace('_fts', '')}_fts_ai")
            cursor.execute(f"DROP TRIGGER IF EXISTS {table.replace('_fts', '')}_fts_ad")
            cursor.execute(f"DROP TRIGGER IF EXISTS {table.replace('_fts', '')}_fts_au")
        conn.commit()
        print("  Dropped existing FTS tables.")

    # Create case_law_fts
    print("  Creating case_law_fts...")
    cursor.execute("""
        CREATE VIRTUAL TABLE IF NOT EXISTS case_law_fts USING fts5(
            case_number,
            title,
            parties,
            celex,
            ecli,
            content='case_law',
            content_rowid='rowid',
            tokenize='unicode61 remove_diacritics 2'
        )
    """)

    # Create legislation_fts
    print("  Creating legislation_fts...")
    cursor.execute("""
        CREATE VIRTUAL TABLE IF NOT EXISTS legislation_fts USING fts5(
            title,
            celex,
            short_title,
            subject_matter,
            content='legislation',
            content_rowid='rowid',
            tokenize='unicode61 remove_diacritics 2'
        )
    """)

    conn.commit()

    # Populate FTS indexes
    print("  Populating case_law_fts...")
    cursor.execute("""
        INSERT INTO case_law_fts(rowid, case_number, title, parties, celex, ecli)
        SELECT rowid, case_number, title, parties, celex, ecli FROM case_law
    """)

    print("  Populating legislation_fts...")
    cursor.execute("""
        INSERT INTO legislation_fts(rowid, title, celex, short_title, subject_matter)
        SELECT rowid, title, celex, short_title, subject_matter FROM legislation
    """)

    conn.commit()

    # Create triggers
    print("  Creating sync triggers...")
    cursor.executescript("""
        -- Case law FTS triggers
        CREATE TRIGGER IF NOT EXISTS case_law_fts_ai AFTER INSERT ON case_law BEGIN
            INSERT INTO case_law_fts(rowid, case_number, title, parties, celex, ecli)
            VALUES (NEW.rowid, NEW.case_number, NEW.title, NEW.parties, NEW.celex, NEW.ecli);
        END;

        CREATE TRIGGER IF NOT EXISTS case_law_fts_ad AFTER DELETE ON case_law BEGIN
            INSERT INTO case_law_fts(case_law_fts, rowid, case_number, title, parties, celex, ecli)
            VALUES ('delete', OLD.rowid, OLD.case_number, OLD.title, OLD.parties, OLD.celex, OLD.ecli);
        END;

        CREATE TRIGGER IF NOT EXISTS case_law_fts_au AFTER UPDATE ON case_law BEGIN
            INSERT INTO case_law_fts(case_law_fts, rowid, case_number, title, parties, celex, ecli)
            VALUES ('delete', OLD.rowid, OLD.case_number, OLD.title, OLD.parties, OLD.celex, OLD.ecli);
            INSERT INTO case_law_fts(rowid, case_number, title, parties, celex, ecli)
            VALUES (NEW.rowid, NEW.case_number, NEW.title, NEW.parties, NEW.celex, NEW.ecli);
        END;

        -- Legislation FTS triggers
        CREATE TRIGGER IF NOT EXISTS legislation_fts_ai AFTER INSERT ON legislation BEGIN
            INSERT INTO legislation_fts(rowid, title, celex, short_title, subject_matter)
            VALUES (NEW.rowid, NEW.title, NEW.celex, NEW.short_title, NEW.subject_matter);
        END;

        CREATE TRIGGER IF NOT EXISTS legislation_fts_ad AFTER DELETE ON legislation BEGIN
            INSERT INTO legislation_fts(legislation_fts, rowid, title, celex, short_title, subject_matter)
            VALUES ('delete', OLD.rowid, OLD.title, OLD.celex, OLD.short_title, OLD.subject_matter);
        END;

        CREATE TRIGGER IF NOT EXISTS legislation_fts_au AFTER UPDATE ON legislation BEGIN
            INSERT INTO legislation_fts(legislation_fts, rowid, title, celex, short_title, subject_matter)
            VALUES ('delete', OLD.rowid, OLD.title, OLD.celex, OLD.short_title, OLD.subject_matter);
            INSERT INTO legislation_fts(rowid, title, celex, short_title, subject_matter)
            VALUES (NEW.rowid, NEW.title, NEW.celex, NEW.short_title, NEW.subject_matter);
        END;
    """)

    conn.commit()

    # Verify
    cursor.execute("SELECT COUNT(*) FROM case_law_fts")
    case_count = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM legislation_fts")
    leg_count = cursor.fetchone()[0]

    print(f"\nFTS indexes created successfully!")
    print(f"  case_law_fts: {case_count} entries")
    print(f"  legislation_fts: {leg_count} entries")

    # Test search
    print("\nTesting FTS search...")
    cursor.execute("""
        SELECT case_number, bm25(case_law_fts) as rank
        FROM case_law_fts
        WHERE case_law_fts MATCH 'Commission'
        ORDER BY rank
        LIMIT 3
    """)
    results = cursor.fetchall()
    if results:
        print("  Case law search for 'Commission':")
        for row in results:
            print(f"    {row[0]} (rank: {row[1]:.4f})")

    cursor.execute("""
        SELECT celex, bm25(legislation_fts) as rank
        FROM legislation_fts
        WHERE legislation_fts MATCH 'regulation'
        ORDER BY rank
        LIMIT 3
    """)
    results = cursor.fetchall()
    if results:
        print("  Legislation search for 'regulation':")
        for row in results:
            print(f"    {row[0]} (rank: {row[1]:.4f})")

    conn.close()

    # Show file size
    size_mb = db_path.stat().st_size / (1024 * 1024)
    print(f"\nDatabase size: {size_mb:.2f} MB")
    print("\nDone! Copy this database to your app bundle.")

    return True


if __name__ == "__main__":
    if len(sys.argv) > 1:
        db_path = Path(sys.argv[1])
    else:
        db_path = DEFAULT_DB_PATH
        print(f"Using default path: {db_path}")

    success = add_fts_tables(db_path)
    sys.exit(0 if success else 1)
