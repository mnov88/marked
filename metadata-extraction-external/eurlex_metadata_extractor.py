#!/usr/bin/env python3
"""
EURLEX Metadata Extractor
Scans EURLEX FMX4 folders for .doc.xml files and extracts metadata to CSV.
"""

import xml.etree.ElementTree as ET
import csv
import sys
import os
from pathlib import Path
import re


def normalize_legal_type(legal_value):
    """Normalize LEGAL.VALUE to standardized format."""
    if not legal_value:
        return None
    
    # Normalize older formats and convert underscores to hyphens
    type_map = {
        'REGIMP': 'REG-IMPL',
        'REG_IMPL': 'REG-IMPL',
        'DEC_IMPL': 'DEC-IMPL',
        'DECIS': 'DEC',
    }
    
    normalized = type_map.get(legal_value, legal_value)
    # Convert any remaining underscores to hyphens
    normalized = normalized.replace('_', '-')
    
    return normalized


def extract_text_content(element):
    """Extract all text content from an XML element and its children."""
    if element is None:
        return None
    
    # Get all text, including from child elements
    text_parts = []
    for text in element.itertext():
        cleaned = text.strip()
        if cleaned:
            text_parts.append(cleaned)
    
    return ' '.join(text_parts) if text_parts else None


def parse_xml_metadata(xml_path):
    """Parse a single .doc.xml file and extract metadata."""
    try:
        tree = ET.parse(xml_path)
        root = tree.getroot()
        
        metadata = {
            'xml_file': os.path.basename(xml_path),
            'type': None,
            'formatted_number': None,
            'year': None,
            'number': None,
            'title': None,
            'date': None,
            'eli': None,
        }
        
        # Extract LEGAL.VALUE
        legal_value_elem = root.find('.//LEGAL.VALUE')
        if legal_value_elem is not None:
            metadata['type'] = normalize_legal_type(legal_value_elem.text)
        
        # Extract NO.DOC.TXT (formatted document number - preferred)
        no_doc_txt = root.find('.//NO.DOC.TXT')
        if no_doc_txt is not None:
            metadata['formatted_number'] = no_doc_txt.text
        
        # Extract YEAR
        year_elem = root.find('.//YEAR')
        if year_elem is not None:
            metadata['year'] = year_elem.text
        
        # Extract NO.CURRENT
        no_current = root.find('.//NO.CURRENT')
        if no_current is not None:
            metadata['number'] = no_current.text
        
        # Extract TITLE - look for TITLE/TI/P
        title_elem = root.find('.//TITLE/TI/P')
        if title_elem is not None:
            metadata['title'] = extract_text_content(title_elem)
        
        # Extract publication DATE
        date_elem = root.find('.//DATE[@ISO]')
        if date_elem is not None:
            metadata['date'] = date_elem.get('ISO')
        
        # Extract ELI
        eli_elem = root.find('.//NO.ELI')
        if eli_elem is not None:
            eli_text = eli_elem.text
            # Extract just the ELI URL if it has "ELI:" prefix
            if eli_text and eli_text.startswith('ELI:'):
                metadata['eli'] = eli_text[4:]  # Remove "ELI:" prefix
            else:
                metadata['eli'] = eli_text
        
        return metadata
        
    except ET.ParseError as e:
        print(f"Error parsing {xml_path}: {e}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"Unexpected error processing {xml_path}: {e}", file=sys.stderr)
        return None


def generate_suggested_filename(metadata):
    """Generate suggested folder name from metadata."""
    doc_type = metadata.get('type')
    formatted_number = metadata.get('formatted_number')
    year = metadata.get('year')
    number = metadata.get('number')
    
    if not doc_type:
        return None, "Missing document type (LEGAL.VALUE)"
    
    # Prefer formatted_number if available
    if formatted_number:
        # Replace slashes with hyphens: "2011/29/EU" -> "2011-29-EU"
        number_part = formatted_number.replace('/', '-')
        suggested = f"{doc_type}-{number_part}"
    elif year and number:
        # Fallback to constructed number
        suggested = f"{doc_type}-{year}-{number}"
    else:
        return None, "Missing year or document number"
    
    return suggested, None


def sanitize_filename(filename):
    """Sanitize filename by replacing invalid characters with hyphens."""
    if not filename:
        return None
    
    # Replace invalid characters (anything not alphanumeric or hyphen) with hyphen
    sanitized = re.sub(r'[^a-zA-Z0-9-]', '-', filename)
    
    # Replace multiple consecutive hyphens with single hyphen
    sanitized = re.sub(r'-+', '-', sanitized)
    
    # Remove leading/trailing hyphens
    sanitized = sanitized.strip('-')
    
    return sanitized if sanitized else None


def validate_filename(filename):
    """Validate if filename contains only safe characters."""
    if not filename:
        return False, "Empty filename"
    
    # Allow only alphanumeric and hyphens
    if not re.match(r'^[a-zA-Z0-9-]+$', filename):
        invalid_chars = set(re.findall(r'[^a-zA-Z0-9-]', filename))
        return False, f"Contains invalid characters: {', '.join(sorted(invalid_chars))}"
    
    return True, None


def scan_and_extract(root_dir):
    """Scan directory for .doc.xml files and extract metadata."""
    root_path = Path(root_dir)
    
    if not root_path.exists():
        print(f"Error: Directory not found: {root_dir}", file=sys.stderr)
        return []
    
    results = []
    doc_xml_files = list(root_path.glob('*/fmx4/*.doc.xml'))
    
    print(f"Found {len(doc_xml_files)} .doc.xml files to process...")
    
    for xml_file in doc_xml_files:
        # Get the UUID folder (parent of fmx4)
        uuid_folder = xml_file.parent.parent
        
        metadata = parse_xml_metadata(xml_file)
        if metadata is None:
            continue
        
        # Generate suggested filename
        suggested, gen_error = generate_suggested_filename(metadata)
        
        # Sanitize filename to fix invalid characters
        if suggested and not gen_error:
            suggested = sanitize_filename(suggested)
        
        # Validate filename
        status = "OK"
        flag_reasons = []
        
        if gen_error:
            status = "FLAGGED"
            flag_reasons.append(gen_error)
        elif not suggested:
            status = "FLAGGED"
            flag_reasons.append("Empty filename after sanitization")
        
        result = {
            'original_path': str(uuid_folder),
            'xml_file': metadata['xml_file'],
            'type': metadata['type'] or '',
            'formatted_number': metadata['formatted_number'] or '',
            'year': metadata['year'] or '',
            'number': metadata['number'] or '',
            'title': metadata['title'] or '',
            'date': metadata['date'] or '',
            'eli': metadata['eli'] or '',
            'suggested_filename': suggested or '',
            'status': status,
            'flag_reason': '; '.join(flag_reasons) if flag_reasons else '',
        }
        
        results.append(result)
    
    return results


def write_csv(results, output_file):
    """Write results to CSV file."""
    if not results:
        print("No results to write.", file=sys.stderr)
        return
    
    fieldnames = [
        'original_path',
        'xml_file',
        'type',
        'formatted_number',
        'year',
        'number',
        'title',
        'date',
        'eli',
        'suggested_filename',
        'status',
        'flag_reason',
    ]
    
    with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(results)
    
    print(f"\nWrote {len(results)} entries to {output_file}")
    
    # Print summary
    flagged = sum(1 for r in results if r['status'] == 'FLAGGED')
    print(f"Status: {len(results) - flagged} OK, {flagged} FLAGGED")


def main():
    if len(sys.argv) < 2:
        print("Usage: python eurlex_metadata_extractor.py <root_directory>", file=sys.stderr)
        print("\nExample:")
        print("  python eurlex_metadata_extractor.py /Users/milos/Coding/downlaoded-eurlex-dump/LEG_EN_FMX_20251102_01_00")
        sys.exit(1)
    
    root_dir = sys.argv[1]
    output_file = 'eurlex_metadata.csv'
    
    print(f"Scanning directory: {root_dir}")
    results = scan_and_extract(root_dir)
    
    if results:
        write_csv(results, output_file)
    else:
        print("No data extracted.", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()

