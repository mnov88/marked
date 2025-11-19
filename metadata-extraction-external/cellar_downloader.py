#!/usr/bin/env python3
"""
CELLAR XML Downloader - Downloads full tree XML notices for EUR-Lex documents
"""

import csv
import time
import requests
from pathlib import Path
from datetime import datetime

def download_cellar_xml(celex, output_path, delay=2):
    """
    Download CELLAR tree XML notice for a given CELEX number.
    
    Args:
        celex: CELEX identifier (e.g., '32016R0679')
        output_path: Path to save the XML file
        delay: Seconds to wait between requests (rate limiting)
    
    Returns:
        tuple: (success: bool, status_code: int, message: str)
    """
    url = f"https://publications.europa.eu/resource/celex/{celex}?language=eng"
    headers = {
        'Accept': 'application/xml;notice=tree',
        'User-Agent': 'EUR-Lex Research Tool/1.0'
    }
    
    try:
        print(f"⬇️  Downloading: {celex}")
        print(f"   URL: {url}")
        
        response = requests.get(url, headers=headers, allow_redirects=True, timeout=30)
        
        if response.status_code == 200:
            # Save XML
            output_path.parent.mkdir(parents=True, exist_ok=True)
            output_path.write_text(response.text, encoding='utf-8')
            
            size_kb = len(response.text) / 1024
            print(f"✅ Success: {celex} ({size_kb:.1f} KB)")
            
            # Rate limiting
            time.sleep(delay)
            
            return (True, 200, f"Downloaded successfully ({size_kb:.1f} KB)")
        else:
            print(f"❌ Failed: {celex} - HTTP {response.status_code}")
            time.sleep(delay)  # Still rate limit on errors
            return (False, response.status_code, f"HTTP {response.status_code}")
            
    except requests.exceptions.Timeout:
        print(f"⏱️  Timeout: {celex}")
        time.sleep(delay)
        return (False, 0, "Timeout")
    except Exception as e:
        print(f"💥 Error: {celex} - {str(e)}")
        time.sleep(delay)
        return (False, 0, str(e))


def test_single_download():
    """Test with a single well-known document (GDPR)"""
    print("\n" + "="*60)
    print("🧪 TESTING: Single CELLAR XML Download")
    print("="*60 + "\n")
    
    # Test with GDPR
    celex = "32016R0679"
    output_dir = Path("/Users/milos/Coding/eurlex-organized/REG/REG-2016-679")
    output_file = output_dir / "cellar_tree_notice.xml"
    
    success, status, msg = download_cellar_xml(celex, output_file, delay=1)
    
    if success:
        print(f"\n🎉 Test successful! File saved to:\n   {output_file}")
        print(f"\n📊 File info:")
        print(f"   Size: {output_file.stat().st_size / 1024:.1f} KB")
        print(f"   Lines: {len(output_file.read_text().splitlines())}")
    else:
        print(f"\n❌ Test failed: {msg}")
    
    return success


def download_from_csv_batch(csv_path, organized_root, batch_size=10, start_index=0):
    """
    Download XMLs for a batch of documents from the CSV.
    
    Args:
        csv_path: Path to eurlex_metadata_enhanced.csv
        organized_root: Root of organized folder structure
        batch_size: Number of documents to process
        start_index: CSV row to start from (0-based, excluding header)
    """
    print("\n" + "="*60)
    print(f"📦 BATCH DOWNLOAD: {batch_size} documents")
    print("="*60 + "\n")
    
    results = {
        'success': 0,
        'failed': 0,
        'skipped': 0,
        'errors': []
    }
    
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        rows = list(reader)
    
    # Select batch
    batch = rows[start_index:start_index + batch_size]
    
    print(f"Processing rows {start_index} to {start_index + len(batch)}")
    print(f"Total rows in CSV: {len(rows)}\n")
    
    for i, row in enumerate(batch, start=start_index):
        celex = row.get('celex', '').strip()
        doc_type = row.get('type', '').strip()
        suggested_filename = row.get('suggested_filename', '').strip()
        status = row.get('status', '').strip()
        
        # Skip if no CELEX or status not OK
        if not celex or status != 'OK':
            print(f"⏭️  Skipping row {i}: No CELEX or status={status}")
            results['skipped'] += 1
            continue
        
        # Build output path
        output_dir = Path(organized_root) / doc_type / suggested_filename
        output_file = output_dir / "cellar_tree_notice.xml"
        
        # Skip if already exists
        if output_file.exists():
            print(f"⏭️  Skipping {celex}: Already exists")
            results['skipped'] += 1
            continue
        
        # Download
        success, status_code, msg = download_cellar_xml(celex, output_file, delay=2)
        
        if success:
            results['success'] += 1
        else:
            results['failed'] += 1
            results['errors'].append({
                'celex': celex,
                'status_code': status_code,
                'message': msg
            })
    
    # Summary
    print("\n" + "="*60)
    print("📊 BATCH SUMMARY")
    print("="*60)
    print(f"✅ Success: {results['success']}")
    print(f"❌ Failed:  {results['failed']}")
    print(f"⏭️  Skipped: {results['skipped']}")
    
    if results['errors']:
        print(f"\n❌ Errors:")
        for err in results['errors'][:5]:  # Show first 5
            print(f"   {err['celex']}: {err['message']}")
        if len(results['errors']) > 5:
            print(f"   ... and {len(results['errors']) - 5} more")
    
    return results


if __name__ == "__main__":
    # Test single download first
    if test_single_download():
        print("\n" + "="*60)
        print("✅ Single test passed! Ready for batch.")
        print("="*60)
        
        # Uncomment to run batch downloads:
        # 
        # Small test batch (10 docs):
        # download_from_csv_batch(
        #     csv_path="/Users/milos/Desktop/markdowned/eurlex_metadata_enhanced.csv",
        #     organized_root="/Users/milos/Coding/eurlex-organized",
        #     batch_size=10,
        #     start_index=0
        # )
        # 
        # Medium batch (100 docs):
        # download_from_csv_batch(
        #     csv_path="/Users/milos/Desktop/markdowned/eurlex_metadata_enhanced.csv",
        #     organized_root="/Users/milos/Coding/eurlex-organized",
        #     batch_size=100,
        #     start_index=0
        # )
        # 
        # Full run (ALL 24K docs - will take ~13 hours):
        # download_from_csv_batch(
        #     csv_path="/Users/milos/Desktop/markdowned/eurlex_metadata_enhanced.csv",
        #     organized_root="/Users/milos/Coding/eurlex-organized",
        #     batch_size=24076,
        #     start_index=0
        # )

