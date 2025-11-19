#!/usr/bin/env python3
"""
CELLAR XML Downloader - Streamlit UI Version
Beautiful interface with progress tracking, pause/resume, and live stats
"""

import csv
import time
import json
import requests
import streamlit as st
from pathlib import Path
from datetime import datetime
from threading import Thread, Event
import queue

# Page config
st.set_page_config(
    page_title="CELLAR XML Downloader",
    page_icon="📥",
    layout="wide"
)

# Session state initialization
if 'download_state' not in st.session_state:
    st.session_state.download_state = {
        'is_running': False,
        'is_paused': False,
        'current_index': 0,
        'total_processed': 0,
        'success_count': 0,
        'failed_count': 0,
        'skipped_count': 0,
        'errors': [],
        'recent_downloads': [],
        'start_time': None
    }

if 'config' not in st.session_state:
    st.session_state.config = {
        'csv_path': '/Users/milos/Desktop/markdowned/eurlex_metadata_enhanced.csv',
        'output_root': '/Users/milos/Coding/eurlex-organized',
        'delay': 1.0,
        'batch_size': 100
    }

def download_cellar_xml(celex, output_path, delay=1.0):
    """Download CELLAR tree XML notice for a given CELEX number."""
    url = f"https://publications.europa.eu/resource/celex/{celex}?language=eng"
    headers = {
        'Accept': 'application/xml;notice=tree',
        'User-Agent': 'EUR-Lex Research Tool/1.0'
    }
    
    try:
        response = requests.get(url, headers=headers, allow_redirects=True, timeout=30)
        
        if response.status_code == 200:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            output_path.write_text(response.text, encoding='utf-8')
            size_kb = len(response.text) / 1024
            time.sleep(delay)
            return (True, 200, f"Downloaded successfully ({size_kb:.1f} KB)", size_kb)
        else:
            time.sleep(delay)
            return (False, response.status_code, f"HTTP {response.status_code}", 0)
            
    except requests.exceptions.Timeout:
        time.sleep(delay)
        return (False, 0, "Timeout", 0)
    except Exception as e:
        time.sleep(delay)
        return (False, 0, str(e), 0)

def load_csv_data(csv_path):
    """Load CSV data and return rows with OK status."""
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            rows = [row for row in reader if row.get('status', '').strip() == 'OK' and row.get('celex', '').strip()]
        return rows, None
    except Exception as e:
        return [], str(e)

def extract_filters_from_csv(rows):
    """Extract unique document types and years from CSV data."""
    types = set()
    years = set()
    
    for row in rows:
        doc_type = row.get('type', '').strip()
        if doc_type:
            types.add(doc_type)
        
        # Try to extract year from CELEX or year field
        year_str = row.get('year', '').strip()
        if year_str and year_str.isdigit():
            years.add(int(year_str))
        else:
            # Try extracting from CELEX (e.g., "32016R0679" -> 2016)
            celex = row.get('celex', '').strip()
            if len(celex) >= 5 and celex[1:5].isdigit():
                years.add(int(celex[1:5]))
    
    return sorted(types), sorted(years)

def filter_rows(rows, selected_types, selected_years):
    """Filter rows by document type and year."""
    if not selected_types and not selected_years:
        return rows
    
    filtered = []
    for row in rows:
        # Check type
        if selected_types:
            doc_type = row.get('type', '').strip()
            if doc_type not in selected_types:
                continue
        
        # Check year
        if selected_years:
            year_str = row.get('year', '').strip()
            year = None
            
            if year_str and year_str.isdigit():
                year = int(year_str)
            else:
                # Try from CELEX
                celex = row.get('celex', '').strip()
                if len(celex) >= 5 and celex[1:5].isdigit():
                    year = int(celex[1:5])
            
            if year not in selected_years:
                continue
        
        filtered.append(row)
    
    return filtered

def download_batch(rows, start_index, batch_size, config, state, stop_event, progress_queue):
    """Download a batch of documents with progress updates."""
    batch = rows[start_index:start_index + batch_size]
    
    for i, row in enumerate(batch):
        if stop_event.is_set():
            break
            
        celex = row.get('celex', '').strip()
        doc_type = row.get('type', '').strip()
        suggested_filename = row.get('suggested_filename', '').strip()
        
        output_dir = Path(config['output_root']) / doc_type / suggested_filename
        output_file = output_dir / "cellar_tree_notice.xml"
        
        # Check if already exists
        if output_file.exists():
            progress_queue.put({
                'type': 'skip',
                'celex': celex,
                'index': start_index + i
            })
            continue
        
        # Download
        success, status_code, msg, size_kb = download_cellar_xml(
            celex, output_file, config['delay']
        )
        
        progress_queue.put({
            'type': 'success' if success else 'error',
            'celex': celex,
            'index': start_index + i,
            'status_code': status_code,
            'message': msg,
            'size_kb': size_kb
        })

# Header
st.title("📥 CELLAR XML Downloader")
st.markdown("Download full tree XML notices from EUR-Lex CELLAR API with progress tracking and pause/resume")

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
        st.info("📋 **No filters applied** - showing all documents")

# Sidebar configuration
st.sidebar.header("⚙️ Configuration")

csv_path = st.sidebar.text_input(
    "CSV Path",
    value=st.session_state.config['csv_path'],
    help="Path to eurlex_metadata_enhanced.csv"
)

output_root = st.sidebar.text_input(
    "Output Root",
    value=st.session_state.config['output_root'],
    help="Root directory for organized files"
)

delay = st.sidebar.slider(
    "Delay (seconds)",
    min_value=0.5,
    max_value=5.0,
    value=st.session_state.config['delay'],
    step=0.5,
    help="Wait time between requests (rate limiting)"
)

batch_size = st.sidebar.number_input(
    "Batch Size",
    min_value=1,
    max_value=25000,
    value=st.session_state.config['batch_size'],
    help="Number of documents to download"
)

# Update config
st.session_state.config.update({
    'csv_path': csv_path,
    'output_root': output_root,
    'delay': delay,
    'batch_size': batch_size
})

# Load CSV data
all_rows, error = load_csv_data(csv_path)

if error:
    st.error(f"❌ Error loading CSV: {error}")
    st.stop()

# Extract available filters
available_types, available_years = extract_filters_from_csv(all_rows)

# Add filters to sidebar
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
rows = filter_rows(all_rows, selected_types, selected_years)

# Display filter stats
st.sidebar.markdown("---")
st.sidebar.markdown(f"**📊 Total in CSV:** {len(all_rows):,}")
if selected_types or selected_years:
    st.sidebar.markdown(f"**🔍 Filtered:** {len(rows):,}")
    filter_pct = (len(rows) / len(all_rows) * 100) if all_rows else 0
    st.sidebar.markdown(f"**📈 Showing:** {filter_pct:.1f}%")
else:
    st.sidebar.markdown(f"**🔍 No filters applied**")

total_available = len(rows)

# Current index selector
start_index = st.sidebar.number_input(
    "Start Index",
    min_value=0,
    max_value=max(0, total_available - 1),
    value=st.session_state.download_state['current_index'],
    help="Resume from this document"
)

# Main stats
col1, col2, col3, col4 = st.columns(4)

with col1:
    st.metric("✅ Success", st.session_state.download_state['success_count'])
with col2:
    st.metric("❌ Failed", st.session_state.download_state['failed_count'])
with col3:
    st.metric("⏭️ Skipped", st.session_state.download_state['skipped_count'])
with col4:
    total_processed = st.session_state.download_state['total_processed']
    remaining = min(batch_size, total_available - start_index) - total_processed
    st.metric("📊 Remaining", remaining)

# Progress bar
if st.session_state.download_state['is_running'] or st.session_state.download_state['total_processed'] > 0:
    progress_pct = st.session_state.download_state['total_processed'] / min(batch_size, total_available - start_index)
    st.progress(progress_pct)
    st.caption(f"Progress: {st.session_state.download_state['total_processed']} / {min(batch_size, total_available - start_index)}")

# Control buttons
col1, col2, col3, col4 = st.columns(4)

with col1:
    if st.button("▶️ Start Download", disabled=st.session_state.download_state['is_running'], type="primary"):
        st.session_state.download_state.update({
            'is_running': True,
            'is_paused': False,
            'current_index': start_index,
            'total_processed': 0,
            'success_count': 0,
            'failed_count': 0,
            'skipped_count': 0,
            'errors': [],
            'recent_downloads': [],
            'start_time': datetime.now()
        })
        st.rerun()

with col2:
    if st.button("⏸️ Pause", disabled=not st.session_state.download_state['is_running']):
        st.session_state.download_state['is_paused'] = True
        st.session_state.download_state['is_running'] = False
        st.info("⏸️ Download paused. Click 'Resume' to continue.")

with col3:
    if st.button("▶️ Resume", disabled=st.session_state.download_state['is_running'] or not st.session_state.download_state['is_paused']):
        st.session_state.download_state['is_running'] = True
        st.session_state.download_state['is_paused'] = False
        st.rerun()

with col4:
    if st.button("🔄 Reset", disabled=st.session_state.download_state['is_running']):
        st.session_state.download_state = {
            'is_running': False,
            'is_paused': False,
            'current_index': 0,
            'total_processed': 0,
            'success_count': 0,
            'failed_count': 0,
            'skipped_count': 0,
            'errors': [],
            'recent_downloads': [],
            'start_time': None
        }
        st.rerun()

# Download logic
if st.session_state.download_state['is_running']:
    state = st.session_state.download_state
    
    # Create progress containers
    status_container = st.empty()
    recent_container = st.container()
    
    # Process documents one by one
    current_idx = state['current_index'] + state['total_processed']
    end_idx = min(state['current_index'] + batch_size, total_available)
    
    if current_idx < end_idx:
        row = rows[current_idx]
        celex = row.get('celex', '').strip()
        doc_type = row.get('type', '').strip()
        suggested_filename = row.get('suggested_filename', '').strip()
        
        output_dir = Path(output_root) / doc_type / suggested_filename
        output_file = output_dir / "cellar_tree_notice.xml"
        
        # Show current download
        status_container.info(f"⬇️ Downloading {current_idx - state['current_index'] + 1}/{batch_size}: {celex}")
        
        # Check if exists
        if output_file.exists():
            state['skipped_count'] += 1
            state['total_processed'] += 1
            state['recent_downloads'].insert(0, {
                'celex': celex,
                'status': 'skipped',
                'message': 'Already exists'
            })
        else:
            # Download
            success, status_code, msg, size_kb = download_cellar_xml(celex, output_file, delay)
            
            if success:
                state['success_count'] += 1
                state['recent_downloads'].insert(0, {
                    'celex': celex,
                    'status': 'success',
                    'message': f"{size_kb:.1f} KB"
                })
            else:
                state['failed_count'] += 1
                state['errors'].append({
                    'celex': celex,
                    'status_code': status_code,
                    'message': msg
                })
                state['recent_downloads'].insert(0, {
                    'celex': celex,
                    'status': 'error',
                    'message': msg
                })
            
            state['total_processed'] += 1
        
        # Keep only last 10
        state['recent_downloads'] = state['recent_downloads'][:10]
        
        # Rerun to continue
        time.sleep(0.1)
        st.rerun()
    else:
        # Finished!
        st.session_state.download_state['is_running'] = False
        status_container.success("✅ Batch complete!")
        
        if state['start_time']:
            elapsed = (datetime.now() - state['start_time']).total_seconds()
            st.info(f"⏱️ Time elapsed: {elapsed/60:.1f} minutes")

# Recent downloads
if st.session_state.download_state['recent_downloads']:
    st.markdown("### 📋 Recent Downloads")
    for download in st.session_state.download_state['recent_downloads']:
        if download['status'] == 'success':
            st.success(f"✅ {download['celex']}: {download['message']}")
        elif download['status'] == 'error':
            st.error(f"❌ {download['celex']}: {download['message']}")
        else:
            st.info(f"⏭️ {download['celex']}: {download['message']}")

# Errors
if st.session_state.download_state['errors']:
    with st.expander(f"❌ Errors ({len(st.session_state.download_state['errors'])})", expanded=False):
        for err in st.session_state.download_state['errors']:
            st.markdown(f"- **{err['celex']}**: {err['message']} (HTTP {err['status_code']})")

# Footer
st.markdown("---")
st.markdown("💡 **Tip**: Use pause/resume to control the download process. Progress is saved automatically!")

