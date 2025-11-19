#!/usr/bin/env python3
"""
CELLAR Metadata Extractor - Streamlit UI

Interactive web interface for extracting metadata from CELLAR tree XML notices.
"""

import streamlit as st
import json
import re
from pathlib import Path
from datetime import datetime
import time
from cellar_metadata_extractor import CellarXMLParser

# Helper functions for filtering
def extract_type_and_year_from_path(xml_path):
    """Extract document type and year from folder structure."""
    folder_name = xml_path.parent.name  # e.g., "REG-2016-679"
    
    # Try to match pattern: TYPE-YEAR-NUMBER
    match = re.match(r'([A-Z-]+)-(\d{4})-', folder_name)
    if match:
        return match.group(1), int(match.group(2))
    
    return None, None

def extract_filters_from_paths(xml_files):
    """Extract unique document types and years from file paths."""
    types = set()
    years = set()
    
    for xml_path in xml_files:
        doc_type, year = extract_type_and_year_from_path(xml_path)
        if doc_type:
            types.add(doc_type)
        if year:
            years.add(year)
    
    return sorted(types), sorted(years)

def filter_xml_files(xml_files, selected_types, selected_years):
    """Filter XML files by document type and year."""
    if not selected_types and not selected_years:
        return xml_files
    
    filtered = []
    for xml_path in xml_files:
        doc_type, year = extract_type_and_year_from_path(xml_path)
        
        # Check type
        if selected_types and doc_type not in selected_types:
            continue
        
        # Check year
        if selected_years and year not in selected_years:
            continue
        
        filtered.append(xml_path)
    
    return filtered

# Page configuration
st.set_page_config(
    page_title="CELLAR Metadata Extractor",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Initialize session state
if 'processing' not in st.session_state:
    st.session_state.processing = False
if 'paused' not in st.session_state:
    st.session_state.paused = False
if 'processed' not in st.session_state:
    st.session_state.processed = 0
if 'total' not in st.session_state:
    st.session_state.total = 0
if 'success' not in st.session_state:
    st.session_state.success = 0
if 'failed' not in st.session_state:
    st.session_state.failed = 0
if 'skipped' not in st.session_state:
    st.session_state.skipped = 0
if 'recent_docs' not in st.session_state:
    st.session_state.recent_docs = []
if 'errors' not in st.session_state:
    st.session_state.errors = []
if 'start_time' not in st.session_state:
    st.session_state.start_time = None
if 'stats_aggregate' not in st.session_state:
    st.session_state.stats_aggregate = {
        'total_languages': 0,
        'total_cases': 0,
        'total_eurovoc': 0,
        'total_articles': 0,
        'total_relations': 0,
        'total_implementations': 0
    }

# Title and description
st.title("📊 CELLAR Metadata Extractor")
st.markdown("""
Extract comprehensive metadata from CELLAR tree XML notices into structured JSON files.
""")

# Show active filters
if 'selected_types' in st.session_state and 'selected_years' in st.session_state:
    active_filters = []
    if st.session_state.selected_types:
        active_filters.append(f"**Types:** {', '.join(st.session_state.selected_types)}")
    if st.session_state.selected_years:
        years_str = ', '.join(map(str, st.session_state.selected_years))
        active_filters.append(f"**Years:** {years_str}")
    
    if active_filters:
        st.info(f"🔍 **Active Filters:** {' | '.join(active_filters)}")
    else:
        st.info("📋 **No filters applied** - processing all documents")

# Sidebar configuration
st.sidebar.header("⚙️ Configuration")

root_dir = st.sidebar.text_input(
    "Root Directory",
    value="/Users/milos/Coding/eurlex-organized",
    help="Directory containing document folders with cellar_tree_notice.xml files"
)

limit = st.sidebar.number_input(
    "Document Limit",
    min_value=0,
    value=0,
    help="Max documents to process (0 = all)"
)

skip_existing = st.sidebar.checkbox(
    "Skip Existing Files",
    value=True,
    help="Skip documents that already have metadata JSON files"
)

st.sidebar.markdown("---")

config_file = st.sidebar.text_input(
    "XPath Config File",
    value="cellar_xpath_config.json",
    help="Path to XPath configuration file"
)

# Scan for available documents and extract filters
root_path = Path(root_dir)
if root_path.exists():
    all_xml_files = list(root_path.rglob('cellar_tree_notice.xml'))
    available_types, available_years = extract_filters_from_paths(all_xml_files)
    
    st.sidebar.markdown("---")
    st.sidebar.header("🔍 Filters")
    
    # Initialize filter state if not exists
    if 'selected_types' not in st.session_state:
        st.session_state.selected_types = []
    if 'selected_years' not in st.session_state:
        st.session_state.selected_years = []
    
    # Document Type filter
    selected_types = st.sidebar.multiselect(
        "Document Types",
        options=available_types,
        default=st.session_state.selected_types,
        help="Select one or more document types (leave empty for all)"
    )
    st.session_state.selected_types = selected_types
    
    # Year filter
    selected_years = st.sidebar.multiselect(
        "Years",
        options=available_years,
        default=st.session_state.selected_years,
        help="Select one or more years (leave empty for all)"
    )
    st.session_state.selected_years = selected_years
    
    # Quick filter buttons
    st.sidebar.markdown("**Quick Filters:**")
    col1, col2 = st.sidebar.columns(2)
    with col1:
        if st.button("📋 All Types"):
            st.session_state.selected_types = []
            st.rerun()
    with col2:
        if st.button("📅 All Years"):
            st.session_state.selected_years = []
            st.rerun()
    
    # Apply filters
    filtered_xml_files = filter_xml_files(all_xml_files, selected_types, selected_years)
    
    # Display filter stats
    st.sidebar.markdown("---")
    st.sidebar.markdown(f"**📊 Total XML files:** {len(all_xml_files):,}")
    if selected_types or selected_years:
        st.sidebar.markdown(f"**🔍 Filtered:** {len(filtered_xml_files):,}")
        filter_pct = (len(filtered_xml_files) / len(all_xml_files) * 100) if all_xml_files else 0
        st.sidebar.markdown(f"**📈 Showing:** {filter_pct:.1f}%")
    else:
        st.sidebar.markdown(f"**🔍 No filters applied**")
else:
    all_xml_files = []
    filtered_xml_files = []
    available_types = []
    available_years = []

st.sidebar.markdown("---")
st.sidebar.markdown("### 📖 About")
st.sidebar.info("""
This tool extracts 50+ metadata fields from CELLAR XML notices:
- Titles (5 types)
- Dates (6 types)
- Identifiers (CELEX, ELI, etc.)
- Eurovoc (concepts, domains, terms)
- Case law (with article parsing)
- Legal relations
- Implementation data
""")

# Main content area
tab1, tab2, tab3 = st.tabs(["📊 Extraction", "📈 Statistics", "📄 Sample Output"])

with tab1:
    # Control buttons
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        if st.button("▶️ Start Extraction", disabled=st.session_state.processing, use_container_width=True):
            st.session_state.processing = True
            st.session_state.paused = False
            st.session_state.processed = 0
            st.session_state.success = 0
            st.session_state.failed = 0
            st.session_state.skipped = 0
            st.session_state.recent_docs = []
            st.session_state.errors = []
            st.session_state.start_time = datetime.now()
            st.session_state.stats_aggregate = {
                'total_languages': 0,
                'total_cases': 0,
                'total_eurovoc': 0,
                'total_articles': 0,
                'total_relations': 0,
                'total_implementations': 0
            }
            st.rerun()
    
    with col2:
        if st.button("⏸️ Pause", disabled=not st.session_state.processing or st.session_state.paused, use_container_width=True):
            st.session_state.paused = True
            st.rerun()
    
    with col3:
        if st.button("▶️ Resume", disabled=not st.session_state.paused, use_container_width=True):
            st.session_state.paused = False
            st.rerun()
    
    with col4:
        if st.button("⏹️ Stop", disabled=not st.session_state.processing, use_container_width=True):
            st.session_state.processing = False
            st.session_state.paused = False
            st.rerun()
    
    st.markdown("---")
    
    # Processing logic
    if st.session_state.processing and not st.session_state.paused:
        try:
            # Initialize parser
            parser = CellarXMLParser(config_file)
            
            # Use filtered XML files
            xml_files = filtered_xml_files
            
            if limit and limit > 0:
                xml_files = xml_files[:limit]
            
            st.session_state.total = len(xml_files)
            
            # Progress bar
            progress_bar = st.progress(0)
            status_text = st.empty()
            
            # Stats display
            col1, col2, col3, col4 = st.columns(4)
            stat_success = col1.empty()
            stat_failed = col2.empty()
            stat_skipped = col3.empty()
            stat_time = col4.empty()
            
            # Recent documents
            recent_container = st.container()
            
            # Process remaining documents
            start_index = st.session_state.processed
            
            for i, xml_path in enumerate(xml_files[start_index:], start=start_index):
                if not st.session_state.processing:
                    break
                
                # Check if output already exists
                folder_name = xml_path.parent.name
                celex_match = None
                celex_pattern = re.search(r'([0-9]{5}[A-Z]{1,2}[0-9]{4}[A-Z]*\(?[0-9]*\)?)', folder_name)
                if celex_pattern:
                    celex_match = celex_pattern.group(1)
                
                if celex_match:
                    output_path = xml_path.parent / f"{celex_match}_metadata.json"
                    if skip_existing and output_path.exists():
                        st.session_state.skipped += 1
                        st.session_state.processed += 1
                        continue
                
                # Process document
                success, out_path, error = parser.process_document(xml_path, celex_match)
                
                st.session_state.processed += 1
                
                if success:
                    st.session_state.success += 1
                    
                    # Load the JSON to get stats
                    try:
                        with open(out_path, 'r', encoding='utf-8') as f:
                            metadata = json.load(f)
                            stats = metadata.get('stats', {})
                            
                            # Aggregate stats
                            st.session_state.stats_aggregate['total_languages'] += stats.get('languages', 0)
                            st.session_state.stats_aggregate['total_cases'] += stats.get('cases', 0)
                            st.session_state.stats_aggregate['total_eurovoc'] += stats.get('eurovoc', 0)
                            st.session_state.stats_aggregate['total_articles'] += stats.get('articles', 0)
                            st.session_state.stats_aggregate['total_relations'] += stats.get('relations', 0)
                            st.session_state.stats_aggregate['total_implementations'] += stats.get('implementations', 0)
                    except:
                        pass
                    
                    # Add to recent docs
                    st.session_state.recent_docs.insert(0, {
                        'name': folder_name,
                        'celex': celex_match or 'Unknown',
                        'status': '✅',
                        'time': datetime.now().strftime('%H:%M:%S')
                    })
                else:
                    st.session_state.failed += 1
                    st.session_state.errors.append({
                        'name': folder_name,
                        'error': error
                    })
                    
                    st.session_state.recent_docs.insert(0, {
                        'name': folder_name,
                        'celex': celex_match or 'Unknown',
                        'status': '❌',
                        'time': datetime.now().strftime('%H:%M:%S')
                    })
                
                # Keep only last 10 recent docs
                st.session_state.recent_docs = st.session_state.recent_docs[:10]
                
                # Update UI
                progress = st.session_state.processed / st.session_state.total
                progress_bar.progress(progress)
                status_text.markdown(f"**Processing:** {folder_name} ({st.session_state.processed}/{st.session_state.total})")
                
                # Update stats
                stat_success.metric("✅ Success", st.session_state.success)
                stat_failed.metric("❌ Failed", st.session_state.failed)
                stat_skipped.metric("⏭️ Skipped", st.session_state.skipped)
                
                # Calculate elapsed time
                if st.session_state.start_time:
                    elapsed = datetime.now() - st.session_state.start_time
                    elapsed_str = str(elapsed).split('.')[0]
                    stat_time.metric("⏱️ Time", elapsed_str)
                
                # Update recent documents
                with recent_container:
                    st.markdown("### 📄 Recent Documents")
                    for doc in st.session_state.recent_docs:
                        st.markdown(f"{doc['status']} **{doc['name']}** ({doc['celex']}) - {doc['time']}")
                
                # Small delay for UI responsiveness
                time.sleep(0.1)
            
            # Mark as complete
            st.session_state.processing = False
            st.success("🎉 Extraction complete!")
            
        except Exception as e:
            st.error(f"Error: {e}")
            st.session_state.processing = False
    
    elif st.session_state.paused:
        st.info("⏸️ Extraction paused. Click Resume to continue.")
    
    # Display current status if not processing
    if not st.session_state.processing:
        if st.session_state.processed > 0:
            st.markdown("### 📊 Summary")
            
            col1, col2, col3, col4 = st.columns(4)
            col1.metric("✅ Success", st.session_state.success)
            col2.metric("❌ Failed", st.session_state.failed)
            col3.metric("⏭️ Skipped", st.session_state.skipped)
            
            if st.session_state.start_time:
                elapsed = datetime.now() - st.session_state.start_time
                elapsed_str = str(elapsed).split('.')[0]
                col4.metric("⏱️ Total Time", elapsed_str)
            
            # Show recent documents
            if st.session_state.recent_docs:
                st.markdown("### 📄 Recent Documents")
                for doc in st.session_state.recent_docs:
                    st.markdown(f"{doc['status']} **{doc['name']}** ({doc['celex']}) - {doc['time']}")
            
            # Show errors if any
            if st.session_state.errors:
                with st.expander(f"❌ Errors ({len(st.session_state.errors)})", expanded=False):
                    for err in st.session_state.errors:
                        st.error(f"**{err['name']}**: {err['error']}")

with tab2:
    st.markdown("### 📈 Aggregate Statistics")
    
    if st.session_state.success > 0:
        col1, col2, col3 = st.columns(3)
        
        col1.metric("🌍 Total Languages", st.session_state.stats_aggregate['total_languages'])
        col2.metric("⚖️ Total Case Law", st.session_state.stats_aggregate['total_cases'])
        col3.metric("🏷️ Total Eurovoc", st.session_state.stats_aggregate['total_eurovoc'])
        
        col1, col2, col3 = st.columns(3)
        
        col1.metric("📋 Total Articles", st.session_state.stats_aggregate['total_articles'])
        col2.metric("🔗 Total Relations", st.session_state.stats_aggregate['total_relations'])
        col3.metric("🌐 Total Implementations", st.session_state.stats_aggregate['total_implementations'])
        
        # Averages
        st.markdown("---")
        st.markdown("### 📊 Averages per Document")
        
        col1, col2, col3 = st.columns(3)
        
        avg_langs = st.session_state.stats_aggregate['total_languages'] / st.session_state.success if st.session_state.success > 0 else 0
        avg_cases = st.session_state.stats_aggregate['total_cases'] / st.session_state.success if st.session_state.success > 0 else 0
        avg_eurovoc = st.session_state.stats_aggregate['total_eurovoc'] / st.session_state.success if st.session_state.success > 0 else 0
        
        col1.metric("Avg Languages", f"{avg_langs:.1f}")
        col2.metric("Avg Case Law", f"{avg_cases:.1f}")
        col3.metric("Avg Eurovoc", f"{avg_eurovoc:.1f}")
        
        col1, col2, col3 = st.columns(3)
        
        avg_articles = st.session_state.stats_aggregate['total_articles'] / st.session_state.success if st.session_state.success > 0 else 0
        avg_relations = st.session_state.stats_aggregate['total_relations'] / st.session_state.success if st.session_state.success > 0 else 0
        avg_impl = st.session_state.stats_aggregate['total_implementations'] / st.session_state.success if st.session_state.success > 0 else 0
        
        col1.metric("Avg Articles", f"{avg_articles:.1f}")
        col2.metric("Avg Relations", f"{avg_relations:.1f}")
        col3.metric("Avg Implementations", f"{avg_impl:.1f}")
        
        # Processing rate
        if st.session_state.start_time and st.session_state.processed > 0:
            elapsed = (datetime.now() - st.session_state.start_time).total_seconds()
            rate = st.session_state.processed / elapsed if elapsed > 0 else 0
            
            st.markdown("---")
            st.markdown("### ⚡ Performance")
            col1, col2 = st.columns(2)
            col1.metric("Processing Rate", f"{rate:.2f} docs/sec")
            col2.metric("Avg Time per Doc", f"{1/rate:.2f} sec" if rate > 0 else "N/A")
    else:
        st.info("Start extraction to see statistics.")

with tab3:
    st.markdown("### 📄 Sample JSON Output")
    
    st.code('''
{
  "extraction_timestamp": "2025-11-07T00:06:32.643066",
  "selected_language": "eng",
  "available_languages": ["eng", "fra", "deu", ...],
  "document": {
    "languages": ["eng", "fra", "deu", ...],
    "title": {
      "primary": "Regulation (EU) 2016/679...",
      "work": "...",
      "alternative": [...],
      "subtitle": [...]
    },
    "dates": {
      "document": "2016-04-27",
      "publication": "2016-05-04",
      "entryIntoForce": "2018-05-25",
      ...
    },
    "identifiers": {
      "celex": "32016R0679",
      "eli": "http://data.europa.eu/eli/reg/2016/679/oj",
      ...
    },
    "eurovoc": {
      "concepts": [
        {"id": "5595", "label": "personal data", "language": "en"}
      ],
      ...
    },
    "caselaw": [
      {
        "celexId": "62019CJ0645",
        "articles": ["A58P5", "A61", "A62"],
        "parsedArticles": [
          {
            "raw": "A58P5",
            "parsed": "Article 58, Paragraph 5",
            "type": "simple",
            "components": {"article": 58, "paragraph": 5}
          }
        ],
        "type": "Interpreted by"
      }
    ],
    "legalRelations": {
      "basedOn": [...],
      "cites": [...],
      "amends": [...],
      ...
    },
    "metadata": {
      "createdBy": "...",
      "inForce": "true",
      ...
    }
  },
  "stats": {
    "languages": 24,
    "cases": 175,
    "eurovoc": 10,
    "articles": 659,
    "relations": 110,
    "implementations": 0
  }
}
    ''', language='json')
    
    st.markdown("""
    ### 📋 Extracted Fields
    
    - **Title**: primary, work, alternative, subtitle, multilingual
    - **Dates**: document, publication, signature, entry into force, end of validity, transposition deadline
    - **Identifiers**: CELEX, ELI, OJ reference, IMMC, natural number, type, year, sector
    - **Eurovoc**: concepts, domains, microthesaurus, terms (all with IDs and labels)
    - **Case Law**: All 7 types with article references (raw + parsed)
    - **Implementation**: National measures with countries
    - **Legal Relations**: based on, cites, amends, repeals, consolidated by, corrected by, treaty basis
    - **Metadata**: created by, responsible agent, in force, subject matter, dossier, version, last modified
    """)

# Footer
st.markdown("---")
st.markdown("""
<div style='text-align: center; color: #666;'>
    <p>CELLAR Metadata Extractor v1.0 | Extracting 50+ metadata fields per document</p>
</div>
""", unsafe_allow_html=True)

