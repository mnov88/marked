#!/usr/bin/env python3
"""
Simplified EUR-Lex Database Import Script

Reads JSON metadata files and produces a SQLite database for SwiftUI search.
Replaces the overcomplicated eurlex_db_import.py with a focused implementation.

Usage:
    python3 eurlex_db_import_simple.py \
        --metadata-root /path/to/eurlex-organized \
        --case-root /path/to/CASE_LAW \
        --output ./eurlex.db \
        --verbose
"""

import argparse
import json
import re
import sqlite3
import uuid
import warnings
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Optional

try:
    from tqdm import tqdm
except ImportError:
    # Fallback if tqdm not installed
    def tqdm(iterable, **kwargs):
        return iterable


# =============================================================================
# Schema Definition
# =============================================================================

SCHEMA_SQL = """
-- legislation (16 columns) - matches DBLegislation.swift
CREATE TABLE IF NOT EXISTS legislation (
    id TEXT PRIMARY KEY,
    celex TEXT NOT NULL UNIQUE,
    eli TEXT,
    doc_type TEXT NOT NULL,
    doc_year INTEGER NOT NULL,
    doc_number INTEGER,
    title TEXT NOT NULL,
    short_title TEXT,
    date_document TEXT,
    date_in_force TEXT,
    date_end_validity TEXT,
    in_force INTEGER DEFAULT 1,
    created_by TEXT,
    subject_matter TEXT,
    imported_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- case_law (16 columns) - matches DBCaseLaw.swift
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
    has_ag_opinion INTEGER DEFAULT 0,
    ag_opinion_ecli TEXT,
    imported_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- article (7 columns) - matches DBArticle
CREATE TABLE IF NOT EXISTS article (
    id TEXT PRIMARY KEY,
    legislation_id TEXT NOT NULL,
    article_num INTEGER NOT NULL,
    paragraph_num INTEGER,
    point TEXT,
    display_text TEXT NOT NULL,
    raw_reference TEXT,
    UNIQUE(legislation_id, article_num, paragraph_num, point)
);

-- case_article_interpretation (4 columns) - matches DBCaseArticleInterpretation
CREATE TABLE IF NOT EXISTS case_article_interpretation (
    id TEXT PRIMARY KEY,
    case_id TEXT NOT NULL,
    article_id TEXT NOT NULL,
    interpretation_type TEXT DEFAULT 'interprets',
    UNIQUE(case_id, article_id)
);

-- eurovoc_concept (4 columns) - matches DBEurovocConcept
CREATE TABLE IF NOT EXISTS eurovoc_concept (
    id TEXT PRIMARY KEY,
    label TEXT NOT NULL UNIQUE,
    domain_id TEXT,
    domain_label TEXT
);

-- legislation_eurovoc (2 columns, composite PK)
CREATE TABLE IF NOT EXISTS legislation_eurovoc (
    legislation_id TEXT NOT NULL,
    eurovoc_id TEXT NOT NULL,
    PRIMARY KEY (legislation_id, eurovoc_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_legislation_celex ON legislation(celex);
CREATE INDEX IF NOT EXISTS idx_legislation_doc_type ON legislation(doc_type);
CREATE INDEX IF NOT EXISTS idx_legislation_doc_year ON legislation(doc_year);
CREATE INDEX IF NOT EXISTS idx_case_law_celex ON case_law(celex);
CREATE INDEX IF NOT EXISTS idx_article_legislation ON article(legislation_id);
CREATE INDEX IF NOT EXISTS idx_interpretation_case ON case_article_interpretation(case_id);
CREATE INDEX IF NOT EXISTS idx_interpretation_article ON case_article_interpretation(article_id);

-- FTS5 virtual tables
CREATE VIRTUAL TABLE IF NOT EXISTS legislation_fts USING fts5(
    celex, eli, title, short_title, subject_matter, created_by,
    content=legislation, content_rowid=rowid, tokenize='unicode61'
);

CREATE VIRTUAL TABLE IF NOT EXISTS case_law_fts USING fts5(
    celex, ecli, case_number, title, short_title, parties, court,
    content=case_law, content_rowid=rowid, tokenize='unicode61'
);
"""


# =============================================================================
# Title Extraction with Cascade Fallback
# =============================================================================

def extract_legislation_title(doc: dict) -> tuple[str, Optional[str]]:
    """
    Extract title and short_title from legislation JSON with cascade fallback.

    Returns: (title, short_title)
    """
    title_data = doc.get('title', {})
    short_titles = title_data.get('short', [])
    multilingual = title_data.get('multilingual', {})

    title = None
    short_title = None

    # Get short_title from short array
    if short_titles and short_titles[0]:
        short_title = short_titles[0]

    # 1. Try primary title
    primary = title_data.get('primary')
    if primary and primary != 'Not found' and primary.strip():
        title = primary

    # 2. Try short title as fallback for title
    if not title and short_title:
        title = short_title

    # 3. Try English multilingual (3-letter code 'eng')
    if not title:
        eng_titles = multilingual.get('eng', [])
        if eng_titles and eng_titles[0]:
            title = eng_titles[0]

    # 4. Try any available language
    if not title:
        for lang, titles in multilingual.items():
            if titles and titles[0]:
                title = titles[0]
                break

    # 5. Fallback to CELEX
    if not title:
        celex = doc.get('identifiers', {}).get('celex', 'Unknown')
        title = f"Document {celex}"
        warnings.warn(f"No title found for legislation {celex}, using fallback")

    return title, short_title


def extract_case_title(case_data: dict) -> tuple[str, Optional[str]]:
    """
    Extract title and short_title from case law JSON with cascade fallback.

    Returns: (title, short_title)
    """
    title_data = case_data.get('title', {})
    short_titles = title_data.get('short', [])
    multilingual = title_data.get('multilingual', {})
    identifiers = case_data.get('identifiers', {})

    title = None
    short_title = None

    # Get short_title (filter out language-suffixed duplicates)
    if short_titles:
        for st in short_titles:
            if st and not st.endswith(('el', 'pl', 'nl', 'mt', 'pt', 'es', 'sk', 'bg', 'fi', 'sl', 'fr', 'cs', 'hr', 'sv', 'ro', 'de', 'lv', 'et', 'en', 'hu', 'it', 'da', 'lt')):
                short_title = st
                break

    # 1. Try English multilingual (2-letter code 'en')
    eng_titles = multilingual.get('en', [])
    if eng_titles and eng_titles[0]:
        title = eng_titles[0]

    # 2. Try 3-letter 'eng' as backup
    if not title:
        eng_titles = multilingual.get('eng', [])
        if eng_titles and eng_titles[0]:
            title = eng_titles[0]

    # 3. Try any available language (prefer common EU languages)
    if not title:
        for lang in ['de', 'fr', 'es', 'it', 'nl', 'pt']:
            titles = multilingual.get(lang, [])
            if titles and titles[0]:
                title = titles[0]
                break

    # 4. Try any remaining language
    if not title:
        for lang, titles in multilingual.items():
            if lang != 'unknown' and titles and titles[0]:
                title = titles[0]
                break

    # 5. Use case number as fallback
    if not title:
        case_number = identifiers.get('caseNumber')
        if case_number:
            title = case_number

    # 6. Last resort: CELEX
    if not title:
        celex = identifiers.get('celex', 'Unknown')
        title = f"Case {celex}"
        warnings.warn(f"No title found for case {celex}, using fallback")

    return title, short_title


# =============================================================================
# CELEX Parsing
# =============================================================================

def parse_celex(celex: str) -> dict:
    """
    Parse CELEX number to extract document type, year, and number.
    Format: SYYYYTNNNN where S=sector, YYYY=year, T=type letter(s), NNNN=number

    Examples:
        32016R0679 -> {doc_type: 'REG', doc_year: 2016, doc_number: 679}
        32019L1937 -> {doc_type: 'DIR', doc_year: 2019, doc_number: 1937}
        62012CJ0060 -> {doc_type: 'CJ', doc_year: 2012, doc_number: 60}
    """
    result = {'doc_type': 'UNKNOWN', 'doc_year': 0, 'doc_number': None}

    if not celex or len(celex) < 6:
        return result

    # Legislation pattern: 3YYYYTNNNN
    leg_match = re.match(r'^[0-9](\d{4})([A-Z]+)(\d+)', celex)
    if leg_match:
        result['doc_year'] = int(leg_match.group(1))
        type_code = leg_match.group(2)
        result['doc_number'] = int(leg_match.group(3))

        # Map type codes
        type_map = {
            'R': 'REG', 'L': 'DIR', 'D': 'DEC',
            'Q': 'REG-IMPL', 'K': 'DEC-IMPL',
            'F': 'REG-DEL', 'J': 'DEC-DEL',
        }
        result['doc_type'] = type_map.get(type_code, type_code)
        return result

    # Case law pattern: 6YYYYXXNNNN
    case_match = re.match(r'^6(\d{4})([A-Z]+)(\d+)', celex)
    if case_match:
        result['doc_year'] = int(case_match.group(1))
        result['doc_type'] = case_match.group(2)  # CJ, CA, TJ, etc.
        result['doc_number'] = int(case_match.group(3))
        return result

    return result


# =============================================================================
# Article Parsing
# =============================================================================

def parse_article_reference(raw_ref: str) -> dict:
    """
    Parse article reference into components.

    Examples:
        A23P1 -> {article: 23, paragraph: 1}
        A06P1LA -> {article: 6, paragraph: 1, point: 'a'}
        Art. 5(1)(a) -> {article: 5, paragraph: 1, point: 'a'}
    """
    result = {'article_num': None, 'paragraph_num': None, 'point': None}

    if not raw_ref:
        return result

    # Pattern 1: Simple format A##P##
    simple = re.match(r'A(\d+)(?:P(\d+))?(?:L([A-Z]))?', raw_ref, re.IGNORECASE)
    if simple:
        result['article_num'] = int(simple.group(1))
        if simple.group(2):
            result['paragraph_num'] = int(simple.group(2))
        if simple.group(3):
            result['point'] = simple.group(3).lower()
        return result

    # Pattern 2: Art. X(Y)(z)
    formal = re.match(r'Art\.?\s*(\d+)(?:\((\d+)\))?(?:\(([a-z])\))?', raw_ref, re.IGNORECASE)
    if formal:
        result['article_num'] = int(formal.group(1))
        if formal.group(2):
            result['paragraph_num'] = int(formal.group(2))
        if formal.group(3):
            result['point'] = formal.group(3)
        return result

    # Fallback: just extract any number as article
    num_match = re.search(r'(\d+)', raw_ref)
    if num_match:
        result['article_num'] = int(num_match.group(1))

    return result


def build_display_text(components: dict) -> str:
    """Build human-readable article reference text."""
    parts = []
    if components.get('article_num'):
        parts.append(f"Article {components['article_num']}")
    if components.get('paragraph_num'):
        parts.append(f"Paragraph {components['paragraph_num']}")
    if components.get('point'):
        parts.append(f"Point ({components['point']})")
    return ', '.join(parts) if parts else 'Article (unknown)'


# =============================================================================
# Database Operations
# =============================================================================

def create_schema(conn: sqlite3.Connection):
    """Create all database tables."""
    conn.executescript(SCHEMA_SQL)
    conn.commit()


def upsert_legislation(conn: sqlite3.Connection, data: dict) -> Optional[str]:
    """Insert or update legislation record. Returns ID."""
    leg_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()

    try:
        conn.execute("""
            INSERT OR REPLACE INTO legislation
            (id, celex, eli, doc_type, doc_year, doc_number, title, short_title,
             date_document, date_in_force, date_end_validity, in_force,
             created_by, subject_matter, imported_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            leg_id, data['celex'], data.get('eli'), data['doc_type'],
            data['doc_year'], data.get('doc_number'), data['title'],
            data.get('short_title'), data.get('date_document'),
            data.get('date_in_force'), data.get('date_end_validity'),
            1 if data.get('in_force', True) else 0,
            data.get('created_by'), data.get('subject_matter'),
            now, now
        ))
        return leg_id
    except sqlite3.IntegrityError:
        # Already exists, get existing ID
        cur = conn.execute("SELECT id FROM legislation WHERE celex = ?", (data['celex'],))
        row = cur.fetchone()
        return row[0] if row else None


def upsert_case_law(conn: sqlite3.Connection, data: dict) -> Optional[str]:
    """Insert or update case law record. Returns ID."""
    case_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()

    try:
        conn.execute("""
            INSERT OR REPLACE INTO case_law
            (id, celex, ecli, case_number, title, short_title, parties,
             court, procedure_type, origin_country, date_judgment, date_request,
             has_ag_opinion, ag_opinion_ecli, imported_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            case_id, data['celex'], data.get('ecli'), data.get('case_number'),
            data.get('title'), data.get('short_title'), data.get('parties'),
            data.get('court'), data.get('procedure_type'), data.get('origin_country'),
            data.get('date_judgment'), data.get('date_request'),
            1 if data.get('has_ag_opinion', False) else 0,
            data.get('ag_opinion_ecli'),
            now, now
        ))
        return case_id
    except sqlite3.IntegrityError:
        cur = conn.execute("SELECT id FROM case_law WHERE celex = ?", (data['celex'],))
        row = cur.fetchone()
        return row[0] if row else None


def upsert_article(conn: sqlite3.Connection, legislation_id: str, components: dict, raw_ref: str) -> Optional[str]:
    """Insert or update article record. Returns ID."""
    if not components.get('article_num'):
        return None

    article_id = str(uuid.uuid4())
    display_text = build_display_text(components)

    try:
        conn.execute("""
            INSERT OR REPLACE INTO article
            (id, legislation_id, article_num, paragraph_num, point, display_text, raw_reference)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            article_id, legislation_id, components['article_num'],
            components.get('paragraph_num'), components.get('point'),
            display_text, raw_ref
        ))
        return article_id
    except sqlite3.IntegrityError:
        # Get existing
        cur = conn.execute("""
            SELECT id FROM article
            WHERE legislation_id = ? AND article_num = ?
              AND (paragraph_num = ? OR (paragraph_num IS NULL AND ? IS NULL))
              AND (point = ? OR (point IS NULL AND ? IS NULL))
        """, (
            legislation_id, components['article_num'],
            components.get('paragraph_num'), components.get('paragraph_num'),
            components.get('point'), components.get('point')
        ))
        row = cur.fetchone()
        return row[0] if row else None


def upsert_eurovoc(conn: sqlite3.Connection, concept: dict) -> Optional[str]:
    """Insert or update eurovoc concept. Returns ID."""
    if not concept.get('label'):
        return None

    concept_id = concept.get('id', str(uuid.uuid4()))

    try:
        conn.execute("""
            INSERT OR REPLACE INTO eurovoc_concept (id, label, domain_id, domain_label)
            VALUES (?, ?, ?, ?)
        """, (
            concept_id, concept['label'],
            concept.get('domain_id'), concept.get('domain_label')
        ))
        return concept_id
    except sqlite3.IntegrityError:
        cur = conn.execute("SELECT id FROM eurovoc_concept WHERE label = ?", (concept['label'],))
        row = cur.fetchone()
        return row[0] if row else None


def link_legislation_eurovoc(conn: sqlite3.Connection, legislation_id: str, eurovoc_id: str):
    """Create legislation-eurovoc link."""
    try:
        conn.execute("""
            INSERT OR IGNORE INTO legislation_eurovoc (legislation_id, eurovoc_id)
            VALUES (?, ?)
        """, (legislation_id, eurovoc_id))
    except sqlite3.IntegrityError:
        pass


def link_case_article(conn: sqlite3.Connection, case_id: str, article_id: str, interp_type: str = 'interprets'):
    """Create case-article interpretation link."""
    interp_id = str(uuid.uuid4())
    try:
        conn.execute("""
            INSERT OR IGNORE INTO case_article_interpretation
            (id, case_id, article_id, interpretation_type)
            VALUES (?, ?, ?, ?)
        """, (interp_id, case_id, article_id, interp_type))
    except sqlite3.IntegrityError:
        pass


def rebuild_fts(conn: sqlite3.Connection):
    """Rebuild FTS5 indexes."""
    conn.execute("INSERT INTO legislation_fts(legislation_fts) VALUES('rebuild')")
    conn.execute("INSERT INTO case_law_fts(case_law_fts) VALUES('rebuild')")
    conn.commit()


# =============================================================================
# Import Logic
# =============================================================================

def import_legislation_file(conn: sqlite3.Connection, json_path: Path, verbose: bool = False) -> Optional[str]:
    """
    Import single legislation JSON file.
    Returns legislation ID or None on failure.
    """
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except (json.JSONDecodeError, IOError) as e:
        warnings.warn(f"Failed to read {json_path}: {e}")
        return None

    doc = data.get('document', {})
    identifiers = doc.get('identifiers', {})

    celex = identifiers.get('celex')
    if not celex or celex == 'Not found':
        return None

    # Extract title with cascade
    title, short_title = extract_legislation_title(doc)

    # Parse CELEX for type/year/number
    celex_info = parse_celex(celex)

    # Use resourceType from JSON if available
    doc_type = identifiers.get('resourceType', '')
    if not doc_type or doc_type == 'Not found':
        doc_type = celex_info['doc_type']

    # Handle dates
    dates = doc.get('dates', {})
    date_document = dates.get('document')
    date_in_force = dates.get('entryIntoForce')
    date_end_validity = dates.get('endOfValidity')

    # Validate dates (set None if "Not found")
    if date_document == 'Not found':
        date_document = None
    if date_in_force == 'Not found':
        date_in_force = None
    if date_end_validity == 'Not found' or date_end_validity == '9999-12-31':
        date_end_validity = None

    # Metadata
    metadata = doc.get('metadata', {})
    in_force = metadata.get('inForce', 'true').lower() == 'true'
    created_by = metadata.get('createdBy')
    subject_matter = metadata.get('subjectMatter')
    if created_by == 'Not found':
        created_by = None
    if subject_matter == 'Not found':
        subject_matter = None

    # Insert legislation
    leg_data = {
        'celex': celex,
        'eli': identifiers.get('eli') if identifiers.get('eli') != 'Not found' else None,
        'doc_type': doc_type,
        'doc_year': celex_info['doc_year'],
        'doc_number': celex_info['doc_number'],
        'title': title,
        'short_title': short_title,
        'date_document': date_document,
        'date_in_force': date_in_force,
        'date_end_validity': date_end_validity,
        'in_force': in_force,
        'created_by': created_by,
        'subject_matter': subject_matter,
    }

    leg_id = upsert_legislation(conn, leg_data)
    if not leg_id:
        return None

    # Import Eurovoc concepts
    eurovoc = doc.get('eurovoc', {})
    for concept in eurovoc.get('concepts', []):
        eurovoc_id = upsert_eurovoc(conn, concept)
        if eurovoc_id:
            link_legislation_eurovoc(conn, leg_id, eurovoc_id)

    if verbose:
        print(f"  Imported legislation: {celex} - {title[:60]}...")

    return leg_id


def import_case_file(conn: sqlite3.Connection, json_path: Path, legislation_map: dict, verbose: bool = False) -> Optional[str]:
    """
    Import single case law JSON file.
    Returns case ID or None on failure.

    legislation_map: dict of celex -> legislation_id for linking
    """
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except (json.JSONDecodeError, IOError) as e:
        warnings.warn(f"Failed to read {json_path}: {e}")
        return None

    case_data = data.get('case', {})
    identifiers = case_data.get('identifiers', {})

    celex = identifiers.get('celex')
    if not celex:
        return None

    # Extract title with cascade
    title, short_title = extract_case_title(case_data)

    # Handle ECLI (may be list)
    ecli = identifiers.get('ecli')
    if isinstance(ecli, list):
        # Take first clean ECLI (without format suffix)
        for e in ecli:
            if e and not any(ext in e for ext in ['.pdf', '.html', '.txt', '.xml', '.xhtml']):
                ecli = e
                break
        else:
            ecli = ecli[0] if ecli else None

    # Case number
    case_number = identifiers.get('caseNumber')

    # Court info
    court_info = case_data.get('court', {})
    court = court_info.get('name')
    procedure_type = court_info.get('procedureType')
    origin_country = court_info.get('originCountry')

    # Dates
    dates = case_data.get('dates', {})
    date_judgment = dates.get('judgment')
    date_request = dates.get('request')

    # Parties - try multiple keys
    parties_data = case_data.get('parties', {})
    parties = None
    for key in ['en', 'eng', 'unknown']:
        if key in parties_data:
            p = parties_data[key]
            if isinstance(p, list) and p:
                parties = p[0]
            elif isinstance(p, str):
                parties = p
            if parties:
                break

    # Advocate General opinion
    participants = case_data.get('participants', {})
    ag_list = participants.get('advocatesGeneral', [])
    has_ag_opinion = len(ag_list) > 0

    # Insert case law
    case_record = {
        'celex': celex,
        'ecli': ecli,
        'case_number': case_number,
        'title': title,
        'short_title': short_title,
        'parties': parties,
        'court': court,
        'procedure_type': procedure_type,
        'origin_country': origin_country,
        'date_judgment': date_judgment,
        'date_request': date_request,
        'has_ag_opinion': has_ag_opinion,
    }

    case_id = upsert_case_law(conn, case_record)
    if not case_id:
        return None

    # Process interpreted legislation
    for interp in case_data.get('interpretedLegislation', []):
        leg_celex = interp.get('celex')
        if not leg_celex:
            continue

        # Get legislation ID from map
        leg_id = legislation_map.get(leg_celex)
        if not leg_id:
            # Legislation not imported, skip
            continue

        # Process articles
        articles = interp.get('articles', [])
        parsed_articles = interp.get('parsedArticles', [])

        # Use parsed articles if available, otherwise parse raw
        for i, art in enumerate(parsed_articles or articles):
            if isinstance(art, dict):
                raw_ref = art.get('raw', '')
                components = art.get('components', {})
                if not components:
                    components = parse_article_reference(raw_ref)
                else:
                    # Normalize keys
                    components = {
                        'article_num': components.get('article'),
                        'paragraph_num': components.get('paragraph'),
                        'point': components.get('point'),
                    }
            else:
                raw_ref = str(art)
                components = parse_article_reference(raw_ref)

            if components.get('article_num'):
                article_id = upsert_article(conn, leg_id, components, raw_ref)
                if article_id:
                    link_case_article(conn, case_id, article_id)

    if verbose:
        print(f"  Imported case: {celex} - {title[:60]}...")

    return case_id


# =============================================================================
# Main
# =============================================================================

def main():
    parser = argparse.ArgumentParser(
        description='Import EUR-Lex metadata JSON to SQLite database',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 eurlex_db_import_simple.py \\
      --metadata-root /Users/milos/Coding/eurlex-organized \\
      --case-root /Users/milos/Coding/eurlex-organized/CASE_LAW \\
      --output ./eurlex.db \\
      --verbose
"""
    )
    parser.add_argument('--metadata-root', required=True,
                        help='Root directory containing *_metadata.json files')
    parser.add_argument('--case-root',
                        help='Root directory containing *_case_metadata.json files')
    parser.add_argument('--output', required=True,
                        help='Output SQLite database path')
    parser.add_argument('--limit', type=int,
                        help='Limit number of files to process (for testing)')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Verbose output')

    args = parser.parse_args()

    metadata_root = Path(args.metadata_root)
    output_path = Path(args.output)

    # Delete existing database
    if output_path.exists():
        output_path.unlink()
        print(f"Removed existing database: {output_path}")

    # Create database
    conn = sqlite3.connect(str(output_path))
    create_schema(conn)
    print(f"Created database: {output_path}")

    # Find legislation files
    leg_files = list(metadata_root.rglob('*_metadata.json'))
    leg_files = [f for f in leg_files if '_case_metadata.json' not in f.name]

    if args.limit:
        leg_files = leg_files[:args.limit]

    print(f"\nProcessing {len(leg_files)} legislation files...")

    # Process legislation first (cases reference legislation)
    legislation_map = {}  # celex -> id
    for json_file in tqdm(leg_files, desc='Legislation', disable=not args.verbose):
        leg_id = import_legislation_file(conn, json_file, verbose=args.verbose)
        if leg_id:
            # Extract celex from path
            try:
                with open(json_file, 'r') as f:
                    data = json.load(f)
                    celex = data.get('document', {}).get('identifiers', {}).get('celex')
                    if celex:
                        legislation_map[celex] = leg_id
            except:
                pass

    conn.commit()

    leg_count = len(legislation_map)
    print(f"Imported {leg_count} legislation documents")

    # Process case law
    case_count = 0
    if args.case_root:
        case_root = Path(args.case_root)
        case_files = list(case_root.rglob('*_case_metadata.json'))

        if args.limit:
            case_files = case_files[:args.limit]

        print(f"\nProcessing {len(case_files)} case law files...")

        for json_file in tqdm(case_files, desc='Case Law', disable=not args.verbose):
            case_id = import_case_file(conn, json_file, legislation_map, verbose=args.verbose)
            if case_id:
                case_count += 1

        conn.commit()
        print(f"Imported {case_count} case law documents")

    # Rebuild FTS indexes
    print("\nRebuilding FTS5 indexes...")
    rebuild_fts(conn)

    # Final stats
    cur = conn.execute("SELECT COUNT(*) FROM legislation")
    final_leg = cur.fetchone()[0]
    cur = conn.execute("SELECT COUNT(*) FROM case_law")
    final_case = cur.fetchone()[0]
    cur = conn.execute("SELECT COUNT(*) FROM article")
    final_art = cur.fetchone()[0]
    cur = conn.execute("SELECT COUNT(*) FROM case_article_interpretation")
    final_interp = cur.fetchone()[0]
    cur = conn.execute("SELECT COUNT(*) FROM eurovoc_concept")
    final_eurovoc = cur.fetchone()[0]

    print(f"""
Database created: {output_path}
  Legislation: {final_leg}
  Case Law: {final_case}
  Articles: {final_art}
  Interpretations: {final_interp}
  Eurovoc Concepts: {final_eurovoc}
""")

    conn.close()


if __name__ == '__main__':
    main()
