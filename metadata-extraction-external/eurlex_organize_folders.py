#!/usr/bin/env python3
"""
EURLEX Folder Organizer
Reorganizes EURLEX UUID folders into type-based structure with proper names.
"""

import csv
import os
import sys
import shutil
from pathlib import Path
from collections import Counter


def organize_folders(csv_file, output_base_dir, dry_run=False):
    """
    Organize EURLEX folders based on CSV metadata.
    
    Args:
        csv_file: Path to the metadata CSV
        output_base_dir: Base directory for organized structure
        dry_run: If True, only show what would be done without copying
    """
    output_path = Path(output_base_dir)
    
    if not dry_run:
        output_path.mkdir(parents=True, exist_ok=True)
        print(f"Created output directory: {output_path}\n")
    
    stats = {
        'processed': 0,
        'skipped': 0,
        'errors': 0,
        'types': Counter(),
    }
    
    skipped_reasons = Counter()
    errors = []
    
    print(f"Reading CSV: {csv_file}")
    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        
        for idx, row in enumerate(reader, 1):
            original_path = row['original_path']
            doc_type = row['type']
            suggested_filename = row['suggested_filename']
            status = row['status']
            flag_reason = row['flag_reason']
            
            # Skip flagged entries
            if status == 'FLAGGED':
                stats['skipped'] += 1
                skipped_reasons[flag_reason] += 1
                continue
            
            # Validate we have all required info
            if not doc_type or not suggested_filename:
                stats['skipped'] += 1
                skipped_reasons['Missing type or filename'] += 1
                continue
            
            # Check source exists
            source_path = Path(original_path)
            if not source_path.exists():
                stats['errors'] += 1
                errors.append(f"Source not found: {original_path}")
                continue
            
            # Create type subfolder
            type_folder = output_path / doc_type
            dest_path = type_folder / suggested_filename
            
            if dry_run:
                if idx <= 10:  # Show first 10 in dry run
                    print(f"[DRY RUN] Would copy:")
                    print(f"  FROM: {source_path}")
                    print(f"  TO:   {dest_path}\n")
            else:
                try:
                    # Create type folder if needed
                    type_folder.mkdir(parents=True, exist_ok=True)
                    
                    # Check if destination already exists
                    if dest_path.exists():
                        print(f"⚠️  Destination already exists, skipping: {dest_path}")
                        stats['skipped'] += 1
                        skipped_reasons['Destination already exists'] += 1
                        continue
                    
                    # Copy the folder
                    shutil.copytree(source_path, dest_path)
                    
                    stats['processed'] += 1
                    stats['types'][doc_type] += 1
                    
                    # Progress indicator every 100 items
                    if stats['processed'] % 100 == 0:
                        print(f"Processed {stats['processed']} documents...")
                
                except Exception as e:
                    stats['errors'] += 1
                    error_msg = f"Error copying {original_path} to {dest_path}: {e}"
                    errors.append(error_msg)
                    print(f"❌ {error_msg}")
    
    # Print summary
    print("\n" + "=" * 80)
    print("ORGANIZATION SUMMARY")
    print("=" * 80)
    
    if dry_run:
        print("\n[DRY RUN MODE - No files were copied]")
        print(f"\nWould process {reader.line_num - 1 - stats['skipped']} documents")
    else:
        print(f"\nSuccessfully processed: {stats['processed']}")
        print(f"Skipped: {stats['skipped']}")
        print(f"Errors: {stats['errors']}")
        
        if stats['types']:
            print("\n" + "-" * 60)
            print("Documents by Type:")
            print("-" * 60)
            for doc_type, count in sorted(stats['types'].items()):
                print(f"  {doc_type:20s}: {count:5d} documents")
    
    if skipped_reasons:
        print("\n" + "-" * 60)
        print("Skipped Reasons:")
        print("-" * 60)
        for reason, count in skipped_reasons.most_common():
            print(f"  {count:5d} - {reason}")
    
    if errors:
        print("\n" + "-" * 60)
        print(f"Errors ({len(errors)}):")
        print("-" * 60)
        for error in errors[:10]:  # Show first 10 errors
            print(f"  - {error}")
        if len(errors) > 10:
            print(f"  ... and {len(errors) - 10} more errors")
    
    if not dry_run and stats['processed'] > 0:
        print("\n" + "=" * 80)
        print(f"✓ Organization complete!")
        print(f"✓ Output directory: {output_path}")
        print("=" * 80)
    
    return stats


def main():
    if len(sys.argv) < 3:
        print("Usage: python eurlex_organize_folders.py <csv_file> <output_directory> [--dry-run]")
        print("\nExample:")
        print("  # Dry run (preview only)")
        print("  python eurlex_organize_folders.py eurlex_metadata.csv /Users/milos/Coding/eurlex-organized --dry-run")
        print("\n  # Actual run")
        print("  python eurlex_organize_folders.py eurlex_metadata.csv /Users/milos/Coding/eurlex-organized")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    output_dir = sys.argv[2]
    dry_run = '--dry-run' in sys.argv
    
    if not os.path.exists(csv_file):
        print(f"Error: CSV file not found: {csv_file}", file=sys.stderr)
        sys.exit(1)
    
    if dry_run:
        print("\n" + "=" * 80)
        print("DRY RUN MODE - No files will be copied")
        print("=" * 80 + "\n")
    
    organize_folders(csv_file, output_dir, dry_run=dry_run)


if __name__ == '__main__':
    main()




