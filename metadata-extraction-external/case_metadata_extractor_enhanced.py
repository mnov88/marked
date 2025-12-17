#!/usr/bin/env python3
"""
Case-law metadata extractor (Enhanced)

Enhanced version with:
- Progress bar (tqdm)
- Skip existing JSON files
- Stats summary (success/skipped/failed)
- Faster execution

Reads CELLAR case notices (XML) and outputs structured JSON using XPath mappings
from case_xpath_config.json.
"""

import argparse
import json
import re
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple
from tqdm import tqdm

from lxml import etree


class ExtractionStats:
    """Track extraction statistics."""
    def __init__(self):
        self.success = 0
        self.skipped = 0
        self.failed = 0
        self.errors = []

    def add_success(self):
        self.success += 1

    def add_skipped(self):
        self.skipped += 1

    def add_failed(self, path: str, error: str):
        self.failed += 1
        self.errors.append((path, error))


def load_config(path: Path) -> Dict[str, Dict[str, str]]:
    """Load XPath configuration for case-law."""
    return json.loads(path.read_text(encoding="utf-8"))


def extract_all(tree: etree._ElementTree, xpath: str) -> List[str]:
    """Extract all text values for an XPath (supports union paths)."""
    try:
        results = tree.xpath(xpath, namespaces=tree.getroot().nsmap)
    except Exception:
        return []

    values: List[str] = []
    for item in results:
        if isinstance(item, etree._Element):
            text = "".join(item.itertext()).strip()
        else:
            text = str(item).strip()
        if text:
            values.append(text)
    return values


def extract_first(values: List[str]) -> Optional[str]:
    """Return the first value or None."""
    return values[0] if values else None


def build_sections(tree: etree._ElementTree, config: Dict[str, Dict[str, str]]) -> Dict[str, Dict[str, Any]]:
    """Apply all configured XPaths to the XML tree."""
    sections: Dict[str, Dict[str, Any]] = {}
    for section_name, fields in config.items():
        section: Dict[str, Any] = {}
        for field, xpath in fields.items():
            values = extract_all(tree, xpath)
            section[field] = values
        sections[section_name] = section
    return sections


def parse_article_reference(ref: str) -> Dict[str, Any]:
    """Parse article reference strings into structured components (aligned with legislation parser)."""
    if not ref or ref == "Not specified":
        return {"raw": ref, "parsed": "Not specified", "type": "none", "components": {}}

    original = ref
    ref = ref.strip()
    parsed = ref
    components: Dict[str, Any] = {}
    rtype = "original"

    # URI-structured references: {AR|...} 23 {PA|...} 1 {PTA|...} (e)
    if "{AR|" in ref:
        article_match = re.search(r"\{AR\|[^}]*\}\s*(\d+)", ref)
        paragraph_match = re.search(r"\{PA\|[^}]*\}\s*(\d+)", ref)
        point_match = re.search(r"\{PTA\|[^}]*\}\s*\(([^)]+)\)", ref)
        parts: List[str] = []
        if article_match:
            article_val = int(article_match.group(1))
            components["article"] = article_val
            parts.append(f"Article {article_val}")
        if paragraph_match:
            para_val = int(paragraph_match.group(1))
            components["paragraph"] = para_val
            parts.append(f"Paragraph {para_val}")
        if point_match:
            point_val = point_match.group(1)
            components["point"] = point_val
            parts.append(f"Point ({point_val})")
        if parts:
            parsed = ", ".join(parts)
            rtype = "uri_structured"
    # Simple refs: A06P1LA, A04PT11, A05P3
    elif re.match(r"^A(\d+)(?:P(\d+))?(?:PT(\d+))?(?:L[A-Z])?$", ref):
        m = re.match(r"^A(\d+)(?:P(\d+))?(?:PT(\d+))?(?:L[A-Z])?$", ref)
        if m:
            article_val = int(m.group(1))
            components["article"] = article_val
            parts = [f"Article {article_val}"]
            if m.group(2):
                para_val = int(m.group(2))
                components["paragraph"] = para_val
                parts.append(f"Paragraph {para_val}")
            if m.group(3):
                point_val = m.group(3)
                components["point"] = point_val
                parts.append(f"Point {point_val}")
            parsed = ", ".join(parts)
            rtype = "simple"
    # Recitals: C17
    elif re.match(r"^C(\d+)$", ref):
        m = re.match(r"^C(\d+)$", ref)
        if m:
            rec_val = int(m.group(1))
            components["recital"] = rec_val
            parsed = f"Recital {rec_val}"
            rtype = "recital"
    # Colon structured: ART:55 ALN:1
    elif "ART:" in ref or "ALN:" in ref:
        art_match = re.search(r"ART:(\d+)", ref)
        aln_match = re.search(r"ALN:(\d+)", ref)
        parts = []
        if art_match:
            article_val = int(art_match.group(1))
            components["article"] = article_val
            parts.append(f"Article {article_val}")
        if aln_match:
            para_val = int(aln_match.group(1))
            components["paragraph"] = para_val
            parts.append(f"Paragraph {para_val}")
        if parts:
            parsed = " ".join(parts)
            rtype = "colon_structured"
    # Fragment numbers: N 41 47
    elif ref.startswith("N "):
        numbers = [n for n in ref.replace("N", "").split() if n.isdigit()]
        if numbers:
            nums_int = [int(n) for n in numbers]
            components["paragraphs"] = nums_int
            if len(nums_int) == 1:
                parsed = f"Paragraph {nums_int[0]}"
            else:
                parsed = f"Paragraphs {nums_int[0]} to {nums_int[-1]}"
            rtype = "fragment"
    else:
        number_match = re.search(r"\b(\d+)\b", ref)
        if number_match:
            article_val = int(number_match.group(1))
            components["article"] = article_val
            parsed = f"Article {article_val} (inferred)"
            rtype = "inferred"

    return {"raw": original, "parsed": parsed, "type": rtype, "components": components}


def detect_languages(tree: etree._ElementTree) -> List[str]:
    """Detect languages from lang attributes and LANG elements."""
    langs: set[str] = set()
    root = tree.getroot()
    for element in root.iter():
        for attr in ("lang", "{http://www.w3.org/XML/1998/namespace}lang"):
            val = element.get(attr)
            if val:
                langs.add(val.lower())
    # LANG elements
    for elem in tree.xpath("//LANG | //TITLE/LANG | //EXPRESSION_TITLE/LANG"):
        text = "".join(elem.itertext()).strip().lower()
        if text:
            langs.add(text)
    return sorted(langs)


def normalize_language_codes(codes: List[str]) -> List[str]:
    """Normalize language codes (lowercase 2-3 letter, drop empties)."""
    norm: set[str] = set()
    three_to_two = {
        "eng": "en", "fra": "fr", "deu": "de", "ger": "de", "spa": "es",
        "ita": "it", "nld": "nl", "dut": "nl", "por": "pt", "pol": "pl",
        "ron": "ro", "rum": "ro", "bul": "bg", "ces": "cs", "cze": "cs",
        "dan": "da", "est": "et", "fin": "fi", "ell": "el", "gre": "el",
        "hrv": "hr", "hun": "hu", "lav": "lv", "lit": "lt", "mlt": "mt",
        "slk": "sk", "slo": "sk", "slv": "sl", "swe": "sv", "gle": "ga"
    }
    for code in codes:
        c = (code or "").strip().lower()
        if not c:
            continue
        if len(c) == 3 and c in three_to_two:
            c = three_to_two[c]
        norm.add(c)
    return sorted(norm)


def extract_multilingual(tree: etree._ElementTree, xpath: str) -> Dict[str, List[str]]:
    """Build a language -> [values] map using LANG sibling/attributes."""
    results: Dict[str, List[str]] = {}
    try:
        nodes = tree.xpath(xpath, namespaces=tree.getroot().nsmap)
    except Exception:
        nodes = []
    for node in nodes:
        if isinstance(node, etree._Element):
            text = "".join(node.itertext()).strip()
            if not text:
                continue
            lang = None
            # sibling LANG
            sibling_lang = node.xpath("LANG/text()")
            if sibling_lang:
                lang = sibling_lang[0].strip().lower()
            # attribute lang
            if not lang:
                lang = (node.get("lang") or node.get("{http://www.w3.org/XML/1998/namespace}lang") or "").lower()
            if not lang:
                parent = node.getparent()
                if parent is not None:
                    lang = (parent.get("lang") or parent.get("{http://www.w3.org/XML/1998/namespace}lang") or "").lower()
            if not lang:
                lang = "unknown"
            results.setdefault(lang, []).append(text)
    return results


def infer_celex(sections: Dict[str, Dict[str, Any]], xml_path: Path) -> str:
    """Determine CELEX from identifiers or path fallback."""
    celex = extract_first(sections.get("identifiers", {}).get("celex", []))
    if celex:
        return celex

    match = re.search(r"6\d{3,}C?J?\d+", xml_path.name)
    if match:
        return match.group(0)
    
    # Try parent folder name
    match = re.search(r"6\d{3,}C?J?\d+", xml_path.parent.name)
    if match:
        return match.group(0)
    
    return "unknown"


def process_file(xml_file: Path, config: Dict[str, Dict[str, str]], output_root: Optional[Path], 
                 skip_existing: bool, verbose: bool, stats: ExtractionStats) -> Optional[Path]:
    """Parse a single XML file and write JSON."""
    try:
        # Quick CELEX inference to check if output exists
        celex_from_path = None
        match = re.search(r"6\d{3,}C?J?\d+", xml_file.parent.name)
        if match:
            celex_from_path = match.group(0)
        
        # Determine output path
        output_dir = output_root if output_root else xml_file.parent
        if celex_from_path:
            output_path = output_dir / f"{celex_from_path}_case_metadata.json"
        else:
            # Fallback - will compute after parsing
            output_path = None
        
        # Skip if exists
        if skip_existing and output_path and output_path.exists():
            stats.add_skipped()
            return None
        
        # Parse XML
        parser = etree.XMLParser(remove_blank_text=True)
        tree = etree.parse(str(xml_file), parser)
    except Exception as exc:
        stats.add_failed(str(xml_file), f"Parse error: {exc}")
        if verbose:
            print(f"Failed to parse {xml_file}: {exc}")
        return None

    try:
        sections = build_sections(tree, config)
        celex = infer_celex(sections, xml_file)

        # Languages
        langs = normalize_language_codes(detect_languages(tree))

        # Parsed interpreted legislation (pair CELEX with articles and parsed forms)
        interpreted_celex = sections.get("interpreted_legislation", {}).get("interpreted_celex", [])
        interpreted_articles = sections.get("interpreted_legislation", {}).get("interpreted_articles", [])
        interpreted_entries = []
        max_len = max(len(interpreted_celex), len(interpreted_articles))
        for idx in range(max_len):
            celex_val = interpreted_celex[idx] if idx < len(interpreted_celex) else None
            art_val = interpreted_articles[idx] if idx < len(interpreted_articles) else None
            parsed = parse_article_reference(art_val) if art_val else None
            interpreted_entries.append({
                "celex": celex_val,
                "articles": [art_val] if art_val else [],
                "parsedArticles": [parsed] if parsed else [],
                "type": "interprets"
            })

        document = {
            "identifiers": {
                "celex": extract_first(sections.get("identifiers", {}).get("celex", [])) or celex,
                "ecli": sections.get("identifiers", {}).get("ecli", []),
                "caseNumber": extract_first(sections.get("identifiers", {}).get("case_number", [])),
                "cellarUri": extract_first(sections.get("identifiers", {}).get("cellar_uri", [])),
                "nationalEcli": sections.get("identifiers", {}).get("national_ecli", []),
            },
            "title": {
                "multilingual": extract_multilingual(tree, config["title_and_parties"]["title"]),
                "short": sections.get("title_and_parties", {}).get("short_title", [])
            },
            "parties": extract_multilingual(tree, config["title_and_parties"]["parties"]),
            "dates": {
                "judgment": extract_first(sections.get("dates", {}).get("judgment_date", [])),
                "request": extract_first(sections.get("dates", {}).get("request_date", [])),
                "creation": extract_first(sections.get("dates", {}).get("creation_date", [])),
                "lastModified": extract_first(sections.get("dates", {}).get("last_modified", [])),
                "publication": extract_first(sections.get("dates", {}).get("publication_date", []))
            },
            "court": {
                "name": extract_first(sections.get("court_info", {}).get("court", [])),
                "code": extract_first(sections.get("court_info", {}).get("court_code", [])),
                "procedureType": extract_first(sections.get("court_info", {}).get("procedure_type", [])),
                "procedureLanguage": extract_first(sections.get("court_info", {}).get("procedure_language", [])),
                "originCountry": extract_first(sections.get("court_info", {}).get("originates_country", [])),
                "documentType": extract_first(sections.get("court_info", {}).get("document_type", []))
            },
            "participants": {
                "judges": sections.get("judges_and_ag", {}).get("judge_names", []),
                "advocatesGeneral": sections.get("judges_and_ag", {}).get("ag_names", [])
            },
            "interpretedLegislation": interpreted_entries,
            "citations": {
                "celex": sections.get("citations_and_sources", {}).get("cited_celex", []),
                "ecli": sections.get("citations_and_sources", {}).get("cited_ecli", []),
                "works": sections.get("citations_and_sources", {}).get("cites_work", []),
                "nationalJudgment": sections.get("citations_and_sources", {}).get("national_judgment", [])
            },
            "subjectMatter": {
                "primary": sections.get("subject_matter", {}).get("subject_matter_primary", []),
                "codes": sections.get("subject_matter", {}).get("subject_matter_code", []),
                "eurovoc": sections.get("subject_matter", {}).get("eurovoc_concepts", [])
            },
            "academicSources": sections.get("academic_sources", {}).get("journal_articles", []),
            "metadata": {
                "sector": extract_first(sections.get("additional_metadata", {}).get("sector", [])),
                "year": extract_first(sections.get("additional_metadata", {}).get("year", [])),
                "version": extract_first(sections.get("additional_metadata", {}).get("version", [])),
                "publishedInErecueil": extract_first(sections.get("additional_metadata", {}).get("published_in_erecueil", [])),
                "languages": sections.get("additional_metadata", {}).get("document_languages", []),
                "buildInfo": sections.get("additional_metadata", {}).get("build_info", []),
            }
        }

        stats_data = {
            "languages": len(langs),
            "interpretedActs": len([e for e in interpreted_entries if e.get("celex")]),
            "citations": len(document["citations"].get("celex", [])) + len(document["citations"].get("ecli", [])),
            "judges": len(document["participants"]["judges"]),
            "advocatesGeneral": len(document["participants"]["advocatesGeneral"]),
        }

        data = {
            "extraction_timestamp": datetime.now().isoformat(),
            "selected_language": "en",
            "available_languages": langs,
            "case": document,
            "stats": stats_data,
            "source_xml": str(xml_file),
        }

        # Final output path determination
        if not output_path:
            output_path = output_dir / f"{celex}_case_metadata.json"
        
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
        
        stats.add_success()
        if verbose:
            print(f"✓ {celex}")
        
        return output_path
        
    except Exception as exc:
        stats.add_failed(str(xml_file), f"Extraction error: {exc}")
        if verbose:
            print(f"✗ {xml_file.parent.name}: {exc}")
        return None


def iter_case_notices(root: Path) -> List[Path]:
    """Find candidate case notice XML files under root."""
    files: List[Path] = []
    for xml_file in root.rglob("*.xml"):
        name = xml_file.name
        parts = {p.name for p in xml_file.parents}
        if name == "cellar_case_notice.xml":
            files.append(xml_file)
        elif name == "cellar_tree_notice.xml" and "CASE" in parts:
            files.append(xml_file)
    return files


def main() -> None:
    parser = argparse.ArgumentParser(description="Extract metadata from CELLAR case notices (Enhanced).")
    parser.add_argument("--root", help="Root directory containing case XML notices.")
    parser.add_argument("--folder", help="Single folder containing a case XML notice.")
    parser.add_argument("--output", help="Optional output root for JSON files (defaults to alongside XML).")
    parser.add_argument("--config", default="case_xpath_config.json", help="Path to XPath config (default: case_xpath_config.json).")
    parser.add_argument("--limit", type=int, help="Optional limit of files to process.")
    parser.add_argument("--skip-existing", action="store_true", default=True, help="Skip if JSON already exists (default: True).")
    parser.add_argument("--no-skip-existing", dest="skip_existing", action="store_false", help="Process all files even if JSON exists.")
    parser.add_argument("--verbose", action="store_true", help="Verbose logging.")
    args = parser.parse_args()

    if not args.root and not args.folder:
        parser.error("Provide --root or --folder.")

    config = load_config(Path(args.config))
    output_root = Path(args.output) if args.output else None

    targets: List[Path] = []
    if args.folder:
        folder_path = Path(args.folder)
        if folder_path.is_file():
            targets = [folder_path]
        else:
            targets = iter_case_notices(folder_path)
    if args.root:
        targets.extend(iter_case_notices(Path(args.root)))

    # Deduplicate
    targets = list(dict.fromkeys(targets))
    if args.limit:
        targets = targets[: args.limit]

    if not targets:
        raise SystemExit("No case notice XML files found.")

    print(f"Found {len(targets)} case XML files")
    if args.skip_existing:
        print("Skip mode: ON (existing JSONs will be skipped)")
    else:
        print("Skip mode: OFF (all files will be reprocessed)")
    print()

    stats = ExtractionStats()
    
    # Process with progress bar
    for xml_file in tqdm(targets, desc="Extracting cases", unit="case"):
        process_file(xml_file, config, output_root, args.skip_existing, args.verbose, stats)

    # Summary
    print()
    print("=" * 60)
    print("EXTRACTION SUMMARY")
    print("=" * 60)
    print(f"✓ Success:  {stats.success}")
    print(f"⏭ Skipped:  {stats.skipped}")
    print(f"✗ Failed:   {stats.failed}")
    
    if stats.errors:
        print(f"\n❌ Errors ({len(stats.errors)}):")
        for path, error in stats.errors[:10]:
            file_name = Path(path).parent.name
            print(f"  - {file_name}: {error}")
        if len(stats.errors) > 10:
            print(f"  ... and {len(stats.errors) - 10} more")
    
    print("=" * 60)


if __name__ == "__main__":
    main()

