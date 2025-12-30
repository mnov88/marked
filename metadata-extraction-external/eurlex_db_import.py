#!/usr/bin/env python3
"""
EUR-Lex Database Import Script

Reads extracted JSON metadata files and outputs:
1. SQLite database (eurlex.db)
2. CSV files per table (for pandas, R, etc.)
3. JSON export (optional, for web APIs)

Usage:
    python3 eurlex_db_import.py --help
    python3 eurlex_db_import.py --metadata-root /path/to/eurlex-organized --output-dir ./output
    python3 eurlex_db_import.py --metadata-root /path/to/eurlex-organized --output-dir ./output --format all
"""

import argparse
import csv
import json
import os
import re
import sqlite3
import uuid
from collections import defaultdict
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple


# =============================================================================
# SCHEMA DEFINITION (Standard level)
# =============================================================================

SCHEMA_SQL = """
-- Core legislation documents
CREATE TABLE IF NOT EXISTS legislation (
    id              TEXT PRIMARY KEY,
    celex           TEXT NOT NULL UNIQUE,
    eli             TEXT,
    doc_type        TEXT NOT NULL,
    doc_year        INTEGER NOT NULL,
    doc_number      INTEGER,
    title           TEXT NOT NULL,
    short_title     TEXT,
    date_document   TEXT,
    date_in_force   TEXT,
    date_end_validity TEXT,
    in_force        INTEGER DEFAULT 1,
    created_by      TEXT,
    subject_matter  TEXT,
    imported_at     TEXT NOT NULL,
    updated_at      TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_legislation_celex ON legislation(celex);
CREATE INDEX IF NOT EXISTS idx_legislation_type_year ON legislation(doc_type, doc_year);

-- EU Case Law
CREATE TABLE IF NOT EXISTS case_law (
    id              TEXT PRIMARY KEY,
    celex           TEXT NOT NULL UNIQUE,
    ecli            TEXT,
    case_number     TEXT,
    title           TEXT,
    short_title     TEXT,
    parties         TEXT,
    court           TEXT,
    procedure_type  TEXT,
    origin_country  TEXT,
    date_judgment   TEXT,
    date_request    TEXT,
    has_ag_opinion  INTEGER DEFAULT 0,
    ag_opinion_ecli TEXT,
    imported_at     TEXT NOT NULL,
    updated_at      TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_case_law_celex ON case_law(celex);
CREATE INDEX IF NOT EXISTS idx_case_law_ecli ON case_law(ecli);
CREATE INDEX IF NOT EXISTS idx_case_law_date ON case_law(date_judgment);

-- Articles within legislation
CREATE TABLE IF NOT EXISTS article (
    id              TEXT PRIMARY KEY,
    legislation_id  TEXT NOT NULL REFERENCES legislation(id) ON DELETE CASCADE,
    article_num     INTEGER NOT NULL,
    paragraph_num   INTEGER,
    point           TEXT,
    display_text    TEXT NOT NULL,
    raw_reference   TEXT,
    UNIQUE(legislation_id, article_num, paragraph_num, point)
);

CREATE INDEX IF NOT EXISTS idx_article_legislation ON article(legislation_id);
CREATE INDEX IF NOT EXISTS idx_article_num ON article(article_num);

-- Case interprets specific articles
CREATE TABLE IF NOT EXISTS case_article_interpretation (
    id              TEXT PRIMARY KEY,
    case_id         TEXT NOT NULL REFERENCES case_law(id) ON DELETE CASCADE,
    article_id      TEXT NOT NULL REFERENCES article(id) ON DELETE CASCADE,
    interpretation_type TEXT DEFAULT 'interprets',
    UNIQUE(case_id, article_id)
);

CREATE INDEX IF NOT EXISTS idx_cai_case ON case_article_interpretation(case_id);
CREATE INDEX IF NOT EXISTS idx_cai_article ON case_article_interpretation(article_id);

-- Legal relationships between legislation
CREATE TABLE IF NOT EXISTS legal_relation (
    id              TEXT PRIMARY KEY,
    source_id       TEXT NOT NULL REFERENCES legislation(id) ON DELETE CASCADE,
    target_celex    TEXT NOT NULL,
    target_id       TEXT REFERENCES legislation(id) ON DELETE SET NULL,
    relation_type   TEXT NOT NULL,
    UNIQUE(source_id, target_celex, relation_type)
);

CREATE INDEX IF NOT EXISTS idx_legal_relation_source ON legal_relation(source_id);
CREATE INDEX IF NOT EXISTS idx_legal_relation_target ON legal_relation(target_id);
CREATE INDEX IF NOT EXISTS idx_legal_relation_type ON legal_relation(relation_type);

-- Eurovoc concepts
CREATE TABLE IF NOT EXISTS eurovoc_concept (
    id              TEXT PRIMARY KEY,
    label           TEXT NOT NULL,
    domain_id       TEXT,
    domain_label    TEXT
);

CREATE INDEX IF NOT EXISTS idx_eurovoc_label ON eurovoc_concept(label);

-- Legislation tagged with Eurovoc
CREATE TABLE IF NOT EXISTS legislation_eurovoc (
    legislation_id  TEXT NOT NULL REFERENCES legislation(id) ON DELETE CASCADE,
    eurovoc_id      TEXT NOT NULL REFERENCES eurovoc_concept(id) ON DELETE CASCADE,
    PRIMARY KEY (legislation_id, eurovoc_id)
);

CREATE INDEX IF NOT EXISTS idx_leg_eurovoc_leg ON legislation_eurovoc(legislation_id);
CREATE INDEX IF NOT EXISTS idx_leg_eurovoc_ev ON legislation_eurovoc(eurovoc_id);

-- Multilingual titles
CREATE TABLE IF NOT EXISTS legislation_title (
    id              TEXT PRIMARY KEY,
    legislation_id  TEXT NOT NULL REFERENCES legislation(id) ON DELETE CASCADE,
    language        TEXT NOT NULL,
    title           TEXT NOT NULL,
    UNIQUE(legislation_id, language)
);

CREATE INDEX IF NOT EXISTS idx_leg_title_leg ON legislation_title(legislation_id);

-- Case citations
CREATE TABLE IF NOT EXISTS case_citation (
    id              TEXT PRIMARY KEY,
    citing_case_id  TEXT NOT NULL REFERENCES case_law(id) ON DELETE CASCADE,
    cited_celex     TEXT NOT NULL,
    cited_case_id   TEXT REFERENCES case_law(id) ON DELETE SET NULL,
    cited_ecli      TEXT,
    UNIQUE(citing_case_id, cited_celex)
);

CREATE INDEX IF NOT EXISTS idx_case_citation_citing ON case_citation(citing_case_id);
CREATE INDEX IF NOT EXISTS idx_case_citation_cited ON case_citation(cited_case_id);

-- Additional indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_case_law_court ON case_law(court);
CREATE INDEX IF NOT EXISTS idx_case_law_origin ON case_law(origin_country);
CREATE INDEX IF NOT EXISTS idx_legal_relation_target_type ON legal_relation(target_celex, relation_type);
"""

# FTS5 virtual tables for full-text search (created after data import)
FTS5_SCHEMA_SQL = """
-- FTS5 full-text search for case law
-- Uses content= for external content table (keeps FTS in sync with case_law)
CREATE VIRTUAL TABLE IF NOT EXISTS case_law_fts USING fts5(
    celex,
    ecli,
    case_number,
    title,
    short_title,
    parties,
    court,
    content=case_law,
    content_rowid=rowid,
    tokenize='unicode61'
);

-- FTS5 full-text search for legislation
CREATE VIRTUAL TABLE IF NOT EXISTS legislation_fts USING fts5(
    celex,
    eli,
    title,
    short_title,
    subject_matter,
    created_by,
    content=legislation,
    content_rowid=rowid,
    tokenize='unicode61'
);
"""


# =============================================================================
# DATA STRUCTURES FOR EXPORT
# =============================================================================

class DataStore:
    """In-memory store for all extracted data, supports multiple export formats."""

    def __init__(self):
        self.legislation: Dict[str, Dict] = {}  # celex -> row
        self.case_law: Dict[str, Dict] = {}  # celex -> row
        self.articles: Dict[str, Dict] = {}  # id -> row
        self.case_article_interpretations: List[Dict] = []
        self.legal_relations: List[Dict] = []
        self.eurovoc_concepts: Dict[str, Dict] = {}  # id -> row
        self.legislation_eurovoc: List[Dict] = []
        self.legislation_titles: List[Dict] = []
        self.case_citations: List[Dict] = []

        # Track article uniqueness
        self._article_keys: Set[Tuple] = set()
        # Track interpretation uniqueness
        self._interpretation_keys: Set[Tuple] = set()
        # Track relation uniqueness
        self._relation_keys: Set[Tuple] = set()
        # Track eurovoc link uniqueness
        self._eurovoc_link_keys: Set[Tuple] = set()
        # Track legislation title uniqueness
        self._title_keys: Set[Tuple] = set()
        # Track case citation uniqueness
        self._citation_keys: Set[Tuple] = set()

    def add_legislation(self, data: Dict) -> Optional[str]:
        """Add legislation record, return ID if new."""
        celex = data.get('celex')
        if not celex or celex in self.legislation:
            return self.legislation.get(celex, {}).get('id')

        leg_id = str(uuid.uuid4())
        now = datetime.utcnow().isoformat()

        self.legislation[celex] = {
            'id': leg_id,
            'celex': celex,
            'eli': data.get('eli'),
            'doc_type': data.get('doc_type', ''),
            'doc_year': data.get('doc_year', 0),
            'doc_number': data.get('doc_number'),
            'title': data.get('title', ''),
            'short_title': data.get('short_title'),
            'date_document': data.get('date_document'),
            'date_in_force': data.get('date_in_force'),
            'date_end_validity': data.get('date_end_validity'),
            'in_force': 1 if data.get('in_force', True) else 0,
            'created_by': data.get('created_by'),
            'subject_matter': data.get('subject_matter'),
            'imported_at': now,
            'updated_at': now,
        }
        return leg_id

    def add_case(self, data: Dict) -> Optional[str]:
        """Add case law record, return ID if new."""
        celex = data.get('celex')
        if not celex:
            return None
        if celex in self.case_law:
            return self.case_law[celex]['id']

        case_id = str(uuid.uuid4())
        now = datetime.utcnow().isoformat()

        self.case_law[celex] = {
            'id': case_id,
            'celex': celex,
            'ecli': data.get('ecli'),
            'case_number': data.get('case_number'),
            'title': data.get('title'),
            'short_title': data.get('short_title'),
            'parties': data.get('parties'),
            'court': data.get('court'),
            'procedure_type': data.get('procedure_type'),
            'origin_country': data.get('origin_country'),
            'date_judgment': data.get('date_judgment'),
            'date_request': data.get('date_request'),
            'has_ag_opinion': 1 if data.get('has_ag_opinion') else 0,
            'ag_opinion_ecli': data.get('ag_opinion_ecli'),
            'imported_at': now,
            'updated_at': now,
        }
        return case_id

    def add_article(self, legislation_id: str, components: Dict, raw_ref: str = None) -> Optional[str]:
        """Add article record, return ID. Handles deduplication."""
        article_num = components.get('article')
        if article_num is None:
            return None

        paragraph_num = components.get('paragraph')
        point = components.get('point')

        # Create unique key
        key = (legislation_id, article_num, paragraph_num, point)
        if key in self._article_keys:
            # Find existing article
            for art_id, art in self.articles.items():
                if (art['legislation_id'] == legislation_id and
                    art['article_num'] == article_num and
                    art['paragraph_num'] == paragraph_num and
                    art['point'] == point):
                    return art_id
            return None

        self._article_keys.add(key)
        art_id = str(uuid.uuid4())

        # Build display text
        display = f"Article {article_num}"
        if paragraph_num is not None:
            display += f", Paragraph {paragraph_num}"
        if point is not None:
            display += f", Point ({point})"

        self.articles[art_id] = {
            'id': art_id,
            'legislation_id': legislation_id,
            'article_num': article_num,
            'paragraph_num': paragraph_num,
            'point': str(point) if point is not None else None,
            'display_text': display,
            'raw_reference': raw_ref,
        }
        return art_id

    def add_interpretation(self, case_id: str, article_id: str, interp_type: str = 'interprets'):
        """Link case to article interpretation."""
        key = (case_id, article_id)
        if key in self._interpretation_keys:
            return
        self._interpretation_keys.add(key)

        self.case_article_interpretations.append({
            'id': str(uuid.uuid4()),
            'case_id': case_id,
            'article_id': article_id,
            'interpretation_type': interp_type,
        })

    def add_legal_relation(self, source_id: str, target_celex: str, relation_type: str):
        """Add legal relation between legislation."""
        # Normalize relation type
        rel_type = relation_type.lower().replace(' ', '_')

        key = (source_id, target_celex, rel_type)
        if key in self._relation_keys:
            return
        self._relation_keys.add(key)

        # Check if target is imported
        target_id = None
        if target_celex in self.legislation:
            target_id = self.legislation[target_celex]['id']

        self.legal_relations.append({
            'id': str(uuid.uuid4()),
            'source_id': source_id,
            'target_celex': target_celex,
            'target_id': target_id,
            'relation_type': rel_type,
        })

    def add_eurovoc(self, concept_id: str, label: str, domain_id: str = None, domain_label: str = None):
        """Add Eurovoc concept."""
        if concept_id in self.eurovoc_concepts:
            return
        self.eurovoc_concepts[concept_id] = {
            'id': concept_id,
            'label': label,
            'domain_id': domain_id,
            'domain_label': domain_label,
        }

    def link_legislation_eurovoc(self, legislation_id: str, eurovoc_id: str):
        """Link legislation to Eurovoc concept."""
        key = (legislation_id, eurovoc_id)
        if key in self._eurovoc_link_keys:
            return
        self._eurovoc_link_keys.add(key)
        
        self.legislation_eurovoc.append({
            'legislation_id': legislation_id,
            'eurovoc_id': eurovoc_id,
        })

    def add_legislation_title(self, legislation_id: str, language: str, title: str):
        """Add multilingual title."""
        key = (legislation_id, language)
        if key in self._title_keys:
            return
        self._title_keys.add(key)
        
        self.legislation_titles.append({
            'id': str(uuid.uuid4()),
            'legislation_id': legislation_id,
            'language': language,
            'title': title,
        })

    def add_case_citation(self, citing_case_id: str, cited_celex: str, cited_case_id: str = None, cited_ecli: str = None):
        """Add case citation."""
        key = (citing_case_id, cited_celex)
        if key in self._citation_keys:
            return
        self._citation_keys.add(key)
        
        self.case_citations.append({
            'id': str(uuid.uuid4()),
            'citing_case_id': citing_case_id,
            'cited_celex': cited_celex,
            'cited_case_id': cited_case_id,
            'cited_ecli': cited_ecli,
        })


# =============================================================================
# PARSING HELPERS
# =============================================================================

def parse_celex(celex: str) -> Dict:
    """Extract type, year, number from CELEX ID."""
    # CELEX format: SYYYYTNNNN (e.g., 32016R0679)
    result = {'doc_type': '', 'doc_year': 0, 'doc_number': None}

    if not celex or len(celex) < 6:
        return result

    # Try to extract year (positions 1-4)
    try:
        result['doc_year'] = int(celex[1:5])
    except ValueError:
        pass

    # Extract type letter(s) and number
    rest = celex[5:]
    match = re.match(r'([A-Z]+)(\d+)', rest)
    if match:
        result['doc_type'] = match.group(1)
        try:
            result['doc_number'] = int(match.group(2))
        except ValueError:
            pass

    return result


def extract_celex_from_reference(ref: str) -> Optional[str]:
    """Extract CELEX from various reference formats."""
    if not ref:
        return None

    # Direct CELEX (e.g., 32016R0679)
    if re.match(r'^[0-9][0-9]{4}[A-Z]', ref):
        return ref

    # ELI format (e.g., reg:2016:679:oj) - extract CELEX
    eli_match = re.match(r'(\w+):(\d{4}):(\d+)', ref)
    if eli_match:
        type_map = {'reg': 'R', 'dir': 'L', 'dec': 'D'}
        t = type_map.get(eli_match.group(1).lower(), eli_match.group(1)[0].upper())
        return f"3{eli_match.group(2)}{t}{eli_match.group(3).zfill(4)}"

    return None


# =============================================================================
# JSON PROCESSING
# =============================================================================

def process_legislation_json(json_path: Path, store: DataStore, verbose: bool = False) -> bool:
    """Process a single legislation metadata JSON file."""
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except (json.JSONDecodeError, IOError) as e:
        if verbose:
            print(f"  ⚠️  Failed to read {json_path}: {e}")
        return False

    doc = data.get('document', {})
    identifiers = doc.get('identifiers', {})
    dates = doc.get('dates', {})
    metadata = doc.get('metadata', {})
    title_data = doc.get('title', {})

    celex = identifiers.get('celex')
    if not celex:
        if verbose:
            print(f"  ⚠️  No CELEX in {json_path}")
        return False

    # Use extracted resourceType if available, fallback to CELEX parsing
    doc_type = identifiers.get('resourceType', '').strip()
    if not doc_type or doc_type == 'Not found':
        # Fallback: parse CELEX for type/year/number
        celex_info = parse_celex(celex)
        doc_type = celex_info['doc_type']
        doc_year = celex_info['doc_year']
        doc_number = celex_info['doc_number']
    else:
        # Use extracted resourceType, still parse CELEX for year/number
        celex_info = parse_celex(celex)
        doc_year = celex_info['doc_year']
        doc_number = celex_info['doc_number']

    # Determine short title
    short_titles = title_data.get('short', [])
    short_title = short_titles[0] if short_titles else None

    # Add legislation
    leg_id = store.add_legislation({
        'celex': celex,
        'eli': identifiers.get('eli'),
        'doc_type': doc_type,
        'doc_year': doc_year,
        'doc_number': doc_number,
        'title': title_data.get('primary', ''),
        'short_title': short_title,
        'date_document': dates.get('document'),
        'date_in_force': dates.get('entryIntoForce'),
        'date_end_validity': dates.get('endOfValidity'),
        'in_force': metadata.get('inForce', 'true').lower() == 'true',
        'created_by': metadata.get('createdBy'),
        'subject_matter': metadata.get('subjectMatter'),
    })

    if not leg_id:
        return False  # Duplicate

    # Process case law references
    for case_ref in doc.get('caselaw', []):
        case_celex = case_ref.get('celexId')  # Note: JSON uses 'celexId' not 'celex'
        if not case_celex:
            continue

        # Add case (minimal info from legislation perspective)
        case_id = store.add_case({
            'celex': case_celex,
            'ecli': case_ref.get('ecli'),
        })

        if not case_id:
            continue

        # Process parsed articles
        for parsed in case_ref.get('parsedArticles', []):
            if parsed.get('type') in ('none', None):
                continue

            components = parsed.get('components', {})
            if not components.get('article'):
                continue

            art_id = store.add_article(leg_id, components, parsed.get('raw'))
            if art_id:
                interp_type = case_ref.get('type', 'interprets').lower().replace(' ', '_')
                store.add_interpretation(case_id, art_id, interp_type)

    # Process legal relations
    legal_relations = doc.get('legalRelations', {})
    relation_map = {
        'basedOn': 'based_on',
        'cites': 'cites',
        'amends': 'amends',
        'repeals': 'repeals',
        'consolidatedBy': 'consolidated_by',
        'correctedBy': 'corrected_by',
        'treatyBasis': 'treaty_basis',
    }

    for rel_key, rel_type in relation_map.items():
        targets = legal_relations.get(rel_key, [])
        for target in targets:
            if isinstance(target, str) and target:
                # Try to extract CELEX from various formats
                target_celex = extract_celex_from_reference(target)
                store.add_legal_relation(leg_id, target_celex or target, rel_type)

    # Process Eurovoc concepts
    eurovoc = doc.get('eurovoc', {})
    for concept in eurovoc.get('concepts', []):
        if isinstance(concept, dict) and concept.get('id'):
            store.add_eurovoc(
                concept['id'],
                concept.get('label', 'Unknown'),
                concept.get('domain_id'),
                concept.get('domain_label'),
            )
            store.link_legislation_eurovoc(leg_id, concept['id'])

    # Process multilingual titles (top 5 languages)
    multilingual = title_data.get('multilingual', {})
    priority_langs = ['eng', 'fra', 'deu', 'spa', 'ita']
    for lang in priority_langs:
        titles = multilingual.get(lang, [])
        if titles:
            store.add_legislation_title(leg_id, lang, titles[0])

    return True


def process_case_json(json_path: Path, store: DataStore, verbose: bool = False) -> bool:
    """Process a single case law metadata JSON file."""
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except (json.JSONDecodeError, IOError) as e:
        if verbose:
            print(f"  ⚠️  Failed to read {json_path}: {e}")
        return False

    case = data.get('case', {})
    identifiers = case.get('identifiers', {})
    dates = case.get('dates', {})
    court = case.get('court', {})
    title_data = case.get('title', {})

    celex = identifiers.get('celex')
    if not celex:
        if verbose:
            print(f"  ⚠️  No CELEX in {json_path}")
        return False

    # Get ECLI (may be list)
    ecli = identifiers.get('ecli')
    if isinstance(ecli, list):
        ecli = ecli[0] if ecli else None

    # Get parties
    parties = case.get('parties', {})
    parties_text = parties.get('eng', [''])[0] if isinstance(parties, dict) else str(parties)

    # Short title
    short_titles = title_data.get('short', [])
    short_title = short_titles[0] if short_titles else None

    # Get title
    multilingual = title_data.get('multilingual', {})
    title = multilingual.get('eng', [''])[0] if multilingual.get('eng') else ''

    # Add case
    case_id = store.add_case({
        'celex': celex,
        'ecli': ecli,
        'case_number': identifiers.get('caseNumber'),
        'title': title,
        'short_title': short_title,
        'parties': parties_text,
        'court': court.get('name'),
        'procedure_type': court.get('procedureType'),
        'origin_country': court.get('originCountry'),
        'date_judgment': dates.get('judgment'),
        'date_request': dates.get('request'),
    })

    if not case_id:
        return False  # Duplicate

    # Process interpreted legislation
    for interp in case.get('interpretedLegislation', []):
        leg_celex = interp.get('celex')
        if not leg_celex:
            continue

        # Check if legislation exists
        if leg_celex not in store.legislation:
            continue  # Can't link to non-imported legislation

        leg_id = store.legislation[leg_celex]['id']

        # Process articles
        for parsed in interp.get('parsedArticles', []):
            if parsed.get('type') in ('none', None):
                continue

            components = parsed.get('components', {})
            if not components.get('article'):
                continue

            art_id = store.add_article(leg_id, components, parsed.get('raw'))
            if art_id:
                store.add_interpretation(case_id, art_id, 'interprets')

    # Process case citations
    citations = case.get('citations', {})
    for cited_celex in citations.get('celex', []):
        if cited_celex and cited_celex != celex:
            cited_case_id = store.case_law.get(cited_celex, {}).get('id')
            store.add_case_citation(case_id, cited_celex, cited_case_id)

    return True


# =============================================================================
# EXPORT FUNCTIONS
# =============================================================================

def export_sqlite(store: DataStore, output_path: Path, verbose: bool = False):
    """Export data to SQLite database."""
    if verbose:
        print(f"\n📦 Exporting SQLite database to {output_path}")

    # Remove existing file
    if output_path.exists():
        output_path.unlink()

    conn = sqlite3.connect(str(output_path))
    conn.executescript(SCHEMA_SQL)

    # Insert legislation
    conn.executemany(
        """INSERT INTO legislation (id, celex, eli, doc_type, doc_year, doc_number,
           title, short_title, date_document, date_in_force, date_end_validity,
           in_force, created_by, subject_matter, imported_at, updated_at)
           VALUES (:id, :celex, :eli, :doc_type, :doc_year, :doc_number,
           :title, :short_title, :date_document, :date_in_force, :date_end_validity,
           :in_force, :created_by, :subject_matter, :imported_at, :updated_at)""",
        store.legislation.values()
    )

    # Insert case law
    conn.executemany(
        """INSERT INTO case_law (id, celex, ecli, case_number, title, short_title,
           parties, court, procedure_type, origin_country, date_judgment, date_request,
           has_ag_opinion, ag_opinion_ecli, imported_at, updated_at)
           VALUES (:id, :celex, :ecli, :case_number, :title, :short_title,
           :parties, :court, :procedure_type, :origin_country, :date_judgment, :date_request,
           :has_ag_opinion, :ag_opinion_ecli, :imported_at, :updated_at)""",
        store.case_law.values()
    )

    # Insert articles
    conn.executemany(
        """INSERT INTO article (id, legislation_id, article_num, paragraph_num, point,
           display_text, raw_reference)
           VALUES (:id, :legislation_id, :article_num, :paragraph_num, :point,
           :display_text, :raw_reference)""",
        store.articles.values()
    )

    # Insert interpretations
    conn.executemany(
        """INSERT INTO case_article_interpretation (id, case_id, article_id, interpretation_type)
           VALUES (:id, :case_id, :article_id, :interpretation_type)""",
        store.case_article_interpretations
    )

    # Insert legal relations
    conn.executemany(
        """INSERT INTO legal_relation (id, source_id, target_celex, target_id, relation_type)
           VALUES (:id, :source_id, :target_celex, :target_id, :relation_type)""",
        store.legal_relations
    )

    # Insert Eurovoc concepts
    conn.executemany(
        """INSERT INTO eurovoc_concept (id, label, domain_id, domain_label)
           VALUES (:id, :label, :domain_id, :domain_label)""",
        store.eurovoc_concepts.values()
    )

    # Insert legislation-eurovoc links
    conn.executemany(
        """INSERT INTO legislation_eurovoc (legislation_id, eurovoc_id)
           VALUES (:legislation_id, :eurovoc_id)""",
        store.legislation_eurovoc
    )

    # Insert multilingual titles
    conn.executemany(
        """INSERT INTO legislation_title (id, legislation_id, language, title)
           VALUES (:id, :legislation_id, :language, :title)""",
        store.legislation_titles
    )

    # Insert case citations
    conn.executemany(
        """INSERT INTO case_citation (id, citing_case_id, cited_celex, cited_case_id, cited_ecli)
           VALUES (:id, :citing_case_id, :cited_celex, :cited_case_id, :cited_ecli)""",
        store.case_citations
    )

    # Create FTS5 virtual tables for full-text search
    if verbose:
        print("  📝 Creating FTS5 search indexes...")
    conn.executescript(FTS5_SCHEMA_SQL)

    # Rebuild FTS indexes to populate with data
    conn.execute("INSERT INTO case_law_fts(case_law_fts) VALUES('rebuild')")
    conn.execute("INSERT INTO legislation_fts(legislation_fts) VALUES('rebuild')")

    conn.commit()
    conn.close()

    if verbose:
        print(f"  ✅ SQLite export complete: {output_path}")


def export_csv(store: DataStore, output_dir: Path, verbose: bool = False):
    """Export data to CSV files (one per table)."""
    if verbose:
        print(f"\n📄 Exporting CSV files to {output_dir}")

    output_dir.mkdir(parents=True, exist_ok=True)

    def write_csv(filename: str, data: List[Dict], fieldnames: List[str] = None):
        if not data:
            return
        filepath = output_dir / filename
        fieldnames = fieldnames or list(data[0].keys())
        with open(filepath, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(data)
        if verbose:
            print(f"  ✅ {filename}: {len(data)} rows")

    # Export each table
    write_csv('legislation.csv', list(store.legislation.values()))
    write_csv('case_law.csv', list(store.case_law.values()))
    write_csv('article.csv', list(store.articles.values()))
    write_csv('case_article_interpretation.csv', store.case_article_interpretations)
    write_csv('legal_relation.csv', store.legal_relations)
    write_csv('eurovoc_concept.csv', list(store.eurovoc_concepts.values()))
    write_csv('legislation_eurovoc.csv', store.legislation_eurovoc)
    write_csv('legislation_title.csv', store.legislation_titles)
    write_csv('case_citation.csv', store.case_citations)


def export_json(store: DataStore, output_path: Path, verbose: bool = False):
    """Export all data to a single JSON file."""
    if verbose:
        print(f"\n📋 Exporting JSON to {output_path}")

    export_data = {
        'metadata': {
            'exported_at': datetime.utcnow().isoformat(),
            'schema_version': 'standard_v1',
            'counts': {
                'legislation': len(store.legislation),
                'case_law': len(store.case_law),
                'articles': len(store.articles),
                'interpretations': len(store.case_article_interpretations),
                'legal_relations': len(store.legal_relations),
                'eurovoc_concepts': len(store.eurovoc_concepts),
            }
        },
        'legislation': list(store.legislation.values()),
        'case_law': list(store.case_law.values()),
        'articles': list(store.articles.values()),
        'case_article_interpretations': store.case_article_interpretations,
        'legal_relations': store.legal_relations,
        'eurovoc_concepts': list(store.eurovoc_concepts.values()),
        'legislation_eurovoc': store.legislation_eurovoc,
        'legislation_titles': store.legislation_titles,
        'case_citations': store.case_citations,
    }

    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(export_data, f, indent=2, ensure_ascii=False)

    if verbose:
        print(f"  ✅ JSON export complete: {output_path}")


# =============================================================================
# MAIN
# =============================================================================

def find_metadata_files(root: Path) -> Tuple[List[Path], List[Path]]:
    """Find legislation and case law metadata JSON files."""
    legislation_files = []
    case_files = []

    for json_file in root.rglob('*_metadata.json'):
        # Skip case metadata files for legislation pass
        if '_case_metadata.json' in json_file.name:
            case_files.append(json_file)
        else:
            legislation_files.append(json_file)

    return legislation_files, case_files


def main():
    parser = argparse.ArgumentParser(
        description='Import EUR-Lex metadata JSON files to database and export formats',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Basic import (all formats)
  python3 eurlex_db_import.py --metadata-root /path/to/eurlex-organized --output-dir ./output

  # SQLite only
  python3 eurlex_db_import.py --metadata-root /path/to/eurlex-organized --output-dir ./output --format sqlite

  # CSV only
  python3 eurlex_db_import.py --metadata-root /path/to/eurlex-organized --output-dir ./output --format csv

  # With case law metadata
  python3 eurlex_db_import.py --metadata-root /path/to/eurlex-organized --case-root /path/to/case-cache --output-dir ./output
  
  # Filter by document types (only Regulations and Directives)
  python3 eurlex_db_import.py --metadata-root /path/to/eurlex-organized --output-dir ./output --types REG DIR
        """
    )

    parser.add_argument('--metadata-root', required=True, type=Path,
                        help='Root directory containing *_metadata.json files')
    parser.add_argument('--case-root', type=Path,
                        help='Root directory containing *_case_metadata.json files (optional)')
    parser.add_argument('--output-dir', required=True, type=Path,
                        help='Output directory for database and exports')
    parser.add_argument('--format', choices=['all', 'sqlite', 'csv', 'json'], default='all',
                        help='Export format(s) (default: all)')
    parser.add_argument('--types', nargs='+', type=str,
                        help='Filter by document types (e.g., REG DIR DEC)')
    parser.add_argument('--limit', type=int,
                        help='Limit number of files to process (for testing)')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Verbose output')

    args = parser.parse_args()

    # Validate input
    if not args.metadata_root.exists():
        print(f"❌ Metadata root not found: {args.metadata_root}")
        return 1

    # Create output directory
    args.output_dir.mkdir(parents=True, exist_ok=True)

    # Initialize data store
    store = DataStore()

    # Find metadata files
    print(f"🔍 Scanning {args.metadata_root} for metadata files...")
    legislation_files, case_files = find_metadata_files(args.metadata_root)

    if args.case_root and args.case_root.exists():
        _, additional_cases = find_metadata_files(args.case_root)
        case_files.extend(additional_cases)

    print(f"  📋 Found {len(legislation_files)} legislation files")
    print(f"  ⚖️  Found {len(case_files)} case law files")

    # Apply limit
    if args.limit:
        legislation_files = legislation_files[:args.limit]
        case_files = case_files[:args.limit]
        print(f"  ⚠️  Limited to {args.limit} files each")

    # Filter by types if specified
    if args.types:
        print(f"  🔍 Filtering by types: {', '.join(args.types)}")
        filtered_leg = []
        for json_file in legislation_files:
            try:
                with open(json_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                doc_type = data.get('document', {}).get('identifiers', {}).get('resourceType', '')
                if doc_type in args.types:
                    filtered_leg.append(json_file)
            except:
                pass  # Skip files that can't be read
        legislation_files = filtered_leg
        print(f"  ✓ Filtered to {len(legislation_files)} legislation files")

    # Process legislation first (cases reference legislation)
    print(f"\n📚 Processing legislation metadata...")
    success_leg = 0
    for i, json_file in enumerate(legislation_files):
        if process_legislation_json(json_file, store, args.verbose):
            success_leg += 1
        if (i + 1) % 100 == 0:
            print(f"  Processed {i + 1}/{len(legislation_files)}...")

    print(f"  ✅ Imported {success_leg}/{len(legislation_files)} legislation records")

    # Process case law
    if case_files:
        print(f"\n⚖️  Processing case law metadata...")
        success_case = 0
        for i, json_file in enumerate(case_files):
            if process_case_json(json_file, store, args.verbose):
                success_case += 1
            if (i + 1) % 100 == 0:
                print(f"  Processed {i + 1}/{len(case_files)}...")

        print(f"  ✅ Imported {success_case}/{len(case_files)} case law records")

    # Print summary
    print(f"\n📊 Import Summary:")
    print(f"  • Legislation: {len(store.legislation)}")
    print(f"  • Case Law: {len(store.case_law)}")
    print(f"  • Articles: {len(store.articles)}")
    print(f"  • Interpretations: {len(store.case_article_interpretations)}")
    print(f"  • Legal Relations: {len(store.legal_relations)}")
    print(f"  • Eurovoc Concepts: {len(store.eurovoc_concepts)}")

    # Export
    if args.format in ('all', 'sqlite'):
        export_sqlite(store, args.output_dir / 'eurlex.db', args.verbose)

    if args.format in ('all', 'csv'):
        export_csv(store, args.output_dir / 'csv', args.verbose)

    if args.format in ('all', 'json'):
        export_json(store, args.output_dir / 'eurlex_export.json', args.verbose)

    print(f"\n✅ Export complete! Output in {args.output_dir}")
    return 0


if __name__ == '__main__':
    exit(main())
