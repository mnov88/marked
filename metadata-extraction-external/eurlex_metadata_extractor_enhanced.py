#!/usr/bin/env python3
"""
EURLEX Enhanced Metadata Extractor
Extracts metadata from both FMX XML and RDF files.
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
    normalized = normalized.replace('_', '-')
    
    return normalized


def extract_text_content(element):
    """Extract all text content from an XML element."""
    if element is None:
        return None
    
    text_parts = []
    for text in element.itertext():
        cleaned = text.strip()
        if cleaned:
            text_parts.append(cleaned)
    
    return ' '.join(text_parts) if text_parts else None


def parse_fmx_metadata(xml_path):
    """Parse FMX .doc.xml file for basic metadata."""
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
        
        # Extract NO.DOC.TXT
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
        
        # Extract TITLE
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
            if eli_text and eli_text.startswith('ELI:'):
                metadata['eli'] = eli_text[4:]
            else:
                metadata['eli'] = eli_text
        
        return metadata
        
    except Exception as e:
        print(f"Error parsing FMX {xml_path}: {e}", file=sys.stderr)
        return None


def parse_rdf_metadata(rdf_path, uuid):
    """Parse RDF file for enhanced metadata."""
    try:
        # Parse with namespace awareness
        tree = ET.parse(rdf_path)
        root = tree.getroot()
        
        # Define namespaces
        ns = {
            'rdf': 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
            'cdm': 'http://publications.europa.eu/ontology/cdm#',
            'owl': 'http://www.w3.org/2002/07/owl#',
        }
        
        rdf_metadata = {
            'celex': None,
            'eli_uri': None,
            'subtitle': None,
            'document_date': None,
            'entry_into_force': None,
            'end_of_validity': None,
            'in_force': None,
            'created_by': None,
            'eea_relevant': None,
            'eurovoc_concepts': [],
            'based_on': [],
            'cites': [],
            'amends': [],
            'repeals': [],
            'adopted_by': [],
            'languages': [],
        }
        
        # Find the main work/resource_legal description
        # Look for elements containing the UUID in their rdf:about
        for desc in root.findall('.//rdf:Description', ns):
            about = desc.get('{http://www.w3.org/1999/02/22-rdf-syntax-ns#}about', '')
            
            # Check if this is the main cellar resource
            if uuid in about and 'cellar' in about and not any(c in about for c in ['.', 'manifestation', 'expression']):
                continue
                
            # Extract from any Description that has relevant fields
            for child in desc:
                tag = child.tag.split('}')[-1]  # Get tag without namespace
                
                # CELEX
                if 'resource_legal_id_celex' in tag:
                    rdf_metadata['celex'] = child.text
                
                # ELI
                elif 'resource_legal_eli' in tag:
                    rdf_metadata['eli_uri'] = child.text
                
                # Document date
                elif 'work_date_document' in tag:
                    rdf_metadata['document_date'] = child.text
                
                # Entry into force
                elif 'date_entry-into-force' in tag:
                    rdf_metadata['entry_into_force'] = child.text
                
                # End of validity
                elif 'date_end-of-validity' in tag:
                    rdf_metadata['end_of_validity'] = child.text
                
                # In force status
                elif 'resource_legal_in-force' in tag:
                    rdf_metadata['in_force'] = child.text
                
                # Created by
                elif 'work_created_by_agent' in tag:
                    resource = child.get('{http://www.w3.org/1999/02/22-rdf-syntax-ns#}resource', '')
                    if resource:
                        rdf_metadata['created_by'] = resource.split('/')[-1]
                
                # EEA
                elif 'resource_legal_eea' in tag:
                    rdf_metadata['eea_relevant'] = child.text
                
                # Subtitle
                elif 'expression_subtitle' in tag:
                    if child.text and not rdf_metadata['subtitle']:
                        rdf_metadata['subtitle'] = child.text
                
                # EUROVOC
                elif 'work_is_about_concept_eurovoc' in tag:
                    resource = child.get('{http://www.w3.org/1999/02/22-rdf-syntax-ns#}resource', '')
                    if resource and 'eurovoc' in resource:
                        concept_id = resource.split('/')[-1]
                        if concept_id not in rdf_metadata['eurovoc_concepts']:
                            rdf_metadata['eurovoc_concepts'].append(concept_id)
                
                # Based on
                elif 'resource_legal_based_on_resource_legal' in tag:
                    resource = child.get('{http://www.w3.org/1999/02/22-rdf-syntax-ns#}resource', '')
                    if resource and 'celex' in resource:
                        celex_id = resource.split('/')[-1]
                        if celex_id not in rdf_metadata['based_on']:
                            rdf_metadata['based_on'].append(celex_id)
                
                # Cites
                elif 'work_cites_work' in tag:
                    resource = child.get('{http://www.w3.org/1999/02/22-rdf-syntax-ns#}resource', '')
                    if resource and 'celex' in resource:
                        celex_id = resource.split('/')[-1]
                        if celex_id not in rdf_metadata['cites']:
                            rdf_metadata['cites'].append(celex_id)
                
                # Amends
                elif 'resource_legal_amends_resource_legal' in tag:
                    resource = child.get('{http://www.w3.org/1999/02/22-rdf-syntax-ns#}resource', '')
                    if resource and 'celex' in resource:
                        celex_id = resource.split('/')[-1]
                        if celex_id not in rdf_metadata['amends']:
                            rdf_metadata['amends'].append(celex_id)
                
                # Repeals
                elif 'repeals_resource_legal' in tag:
                    resource = child.get('{http://www.w3.org/1999/02/22-rdf-syntax-ns#}resource', '')
                    if resource and 'celex' in resource:
                        celex_id = resource.split('/')[-1]
                        if celex_id not in rdf_metadata['repeals']:
                            rdf_metadata['repeals'].append(celex_id)
                
                # Adopts
                elif 'resource_legal_adopts_resource_legal' in tag:
                    resource = child.get('{http://www.w3.org/1999/02/22-rdf-syntax-ns#}resource', '')
                    if resource and 'celex' in resource:
                        celex_id = resource.split('/')[-1]
                        if celex_id not in rdf_metadata['adopted_by']:
                            rdf_metadata['adopted_by'].append(celex_id)
        
        # Count available languages
        lang_codes = set()
        for desc in root.findall('.//rdf:Description', ns):
            for child in desc:
                if 'lang' in child.tag:
                    if child.text and len(child.text) <= 3:
                        lang_codes.add(child.text)
        rdf_metadata['languages'] = sorted(list(lang_codes))
        
        # Convert lists to strings
        rdf_metadata['eurovoc_concepts'] = ';'.join(rdf_metadata['eurovoc_concepts'][:10]) if rdf_metadata['eurovoc_concepts'] else ''
        rdf_metadata['based_on'] = ';'.join(rdf_metadata['based_on']) if rdf_metadata['based_on'] else ''
        rdf_metadata['cites'] = ';'.join(rdf_metadata['cites'][:5]) if rdf_metadata['cites'] else ''
        rdf_metadata['amends'] = ';'.join(rdf_metadata['amends']) if rdf_metadata['amends'] else ''
        rdf_metadata['repeals'] = ';'.join(rdf_metadata['repeals']) if rdf_metadata['repeals'] else ''
        rdf_metadata['adopted_by'] = ';'.join(rdf_metadata['adopted_by']) if rdf_metadata['adopted_by'] else ''
        rdf_metadata['languages'] = ';'.join(rdf_metadata['languages']) if rdf_metadata['languages'] else ''
        
        return rdf_metadata
        
    except Exception as e:
        print(f"Error parsing RDF {rdf_path}: {e}", file=sys.stderr)
        return None


def sanitize_filename(filename):
    """Sanitize filename by replacing invalid characters with hyphens."""
    if not filename:
        return None
    
    sanitized = re.sub(r'[^a-zA-Z0-9-]', '-', filename)
    sanitized = re.sub(r'-+', '-', sanitized)
    sanitized = sanitized.strip('-')
    
    return sanitized if sanitized else None


def generate_suggested_filename(metadata):
    """Generate suggested folder name from metadata."""
    doc_type = metadata.get('type')
    formatted_number = metadata.get('formatted_number')
    year = metadata.get('year')
    number = metadata.get('number')
    
    if not doc_type:
        return None, "Missing document type"
    
    if formatted_number:
        number_part = formatted_number.replace('/', '-')
        suggested = f"{doc_type}-{number_part}"
    elif year and number:
        suggested = f"{doc_type}-{year}-{number}"
    else:
        return None, "Missing year or document number"
    
    return suggested, None


def scan_and_extract(fmx_root, rdf_root):
    """Scan directories and extract metadata from both sources."""
    fmx_path = Path(fmx_root)
    rdf_path = Path(rdf_root)
    
    if not fmx_path.exists():
        print(f"Error: FMX directory not found: {fmx_root}", file=sys.stderr)
        return []
    
    if not rdf_path.exists():
        print(f"Error: RDF directory not found: {rdf_root}", file=sys.stderr)
        return []
    
    results = []
    doc_xml_files = list(fmx_path.glob('*/fmx4/*.doc.xml'))
    
    print(f"Found {len(doc_xml_files)} .doc.xml files to process...")
    
    for idx, xml_file in enumerate(doc_xml_files, 1):
        if idx % 1000 == 0:
            print(f"Processing {idx}/{len(doc_xml_files)}...")
        
        # Get UUID from path
        uuid_folder = xml_file.parent.parent
        uuid = uuid_folder.name
        
        # Parse FMX metadata
        fmx_metadata = parse_fmx_metadata(xml_file)
        if fmx_metadata is None:
            continue
        
        # Parse RDF metadata
        rdf_file = rdf_path / uuid / 'tree_non_inferred.rdf'
        rdf_metadata = {}
        if rdf_file.exists():
            rdf_metadata = parse_rdf_metadata(rdf_file, uuid) or {}
        
        # Generate suggested filename
        suggested, gen_error = generate_suggested_filename(fmx_metadata)
        if suggested and not gen_error:
            suggested = sanitize_filename(suggested)
        
        # Determine status
        status = "OK" if suggested and not gen_error else "FLAGGED"
        flag_reason = gen_error if gen_error else ""
        
        # Combine metadata
        result = {
            'uuid': uuid,
            'original_path': str(uuid_folder),
            'xml_file': fmx_metadata['xml_file'],
            'type': fmx_metadata['type'] or '',
            'formatted_number': fmx_metadata['formatted_number'] or '',
            'year': fmx_metadata['year'] or '',
            'number': fmx_metadata['number'] or '',
            'title': fmx_metadata['title'] or '',
            'date': fmx_metadata['date'] or '',
            'eli_fmx': fmx_metadata['eli'] or '',
            'suggested_filename': suggested or '',
            # RDF fields
            'celex': rdf_metadata.get('celex', ''),
            'eli_uri': rdf_metadata.get('eli_uri', ''),
            'subtitle': rdf_metadata.get('subtitle', ''),
            'document_date': rdf_metadata.get('document_date', ''),
            'entry_into_force': rdf_metadata.get('entry_into_force', ''),
            'end_of_validity': rdf_metadata.get('end_of_validity', ''),
            'in_force': rdf_metadata.get('in_force', ''),
            'created_by': rdf_metadata.get('created_by', ''),
            'eea_relevant': rdf_metadata.get('eea_relevant', ''),
            'eurovoc_concepts': rdf_metadata.get('eurovoc_concepts', ''),
            'based_on': rdf_metadata.get('based_on', ''),
            'cites': rdf_metadata.get('cites', ''),
            'amends': rdf_metadata.get('amends', ''),
            'repeals': rdf_metadata.get('repeals', ''),
            'adopts': rdf_metadata.get('adopted_by', ''),
            'languages': rdf_metadata.get('languages', ''),
            'status': status,
            'flag_reason': flag_reason,
        }
        
        results.append(result)
    
    return results


def write_csv(results, output_file):
    """Write results to CSV file."""
    if not results:
        print("No results to write.", file=sys.stderr)
        return
    
    fieldnames = [
        'uuid',
        'original_path',
        'xml_file',
        'type',
        'formatted_number',
        'year',
        'number',
        'title',
        'date',
        'eli_fmx',
        'suggested_filename',
        'celex',
        'eli_uri',
        'subtitle',
        'document_date',
        'entry_into_force',
        'end_of_validity',
        'in_force',
        'created_by',
        'eea_relevant',
        'eurovoc_concepts',
        'based_on',
        'cites',
        'amends',
        'repeals',
        'adopts',
        'languages',
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
    has_celex = sum(1 for r in results if r['celex'])
    has_eurovoc = sum(1 for r in results if r['eurovoc_concepts'])
    has_amends = sum(1 for r in results if r['amends'])
    has_repeals = sum(1 for r in results if r['repeals'])
    
    print(f"\nSummary:")
    print(f"  Status: {len(results) - flagged} OK, {flagged} FLAGGED")
    print(f"  With CELEX: {has_celex}")
    print(f"  With EUROVOC: {has_eurovoc}")
    print(f"  With Amendments: {has_amends}")
    print(f"  With Repeals: {has_repeals}")


def main():
    if len(sys.argv) < 3:
        print("Usage: python eurlex_metadata_extractor_enhanced.py <fmx_directory> <rdf_directory>", file=sys.stderr)
        print("\nExample:")
        print("  python eurlex_metadata_extractor_enhanced.py \\")
        print("    /path/to/LEG_EN_FMX_20251102_01_00 \\")
        print("    /path/to/LEG_MTD_20251102_01_00")
        sys.exit(1)
    
    fmx_root = sys.argv[1]
    rdf_root = sys.argv[2]
    output_file = 'eurlex_metadata_enhanced.csv'
    
    print(f"FMX Directory: {fmx_root}")
    print(f"RDF Directory: {rdf_root}")
    print(f"Output: {output_file}\n")
    
    results = scan_and_extract(fmx_root, rdf_root)
    
    if results:
        write_csv(results, output_file)
    else:
        print("No data extracted.", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()




