#!/usr/bin/env python3
"""
CELLAR XML Metadata Extractor

Extracts comprehensive metadata from CELLAR tree XML notices and outputs
structured JSON files matching the JS app schema.

Usage:
    # Single document
    python cellar_metadata_extractor.py --folder /path/to/doc/folder
    
    # Batch processing
    python cellar_metadata_extractor.py --root /path/to/root --limit 5
"""

import json
import re
import argparse
from pathlib import Path
from datetime import datetime
from lxml import etree

class ArticleReferenceParser:
    """Parse article references from case law annotations"""
    
    # Regex patterns
    SIMPLE_PATTERN = re.compile(r'^A(\d+)(?:P(\d+))?$')
    COMPLEX_PATTERN = re.compile(
        r'\{AR\|[^\}]*\}\s*(\d+)(?:\s*\{PA\|[^\}]*\}\s*(\d+))?(?:\s*\{PTA\|[^\}]*\}\s*\(([^\)]+)\))?'
    )
    
    @classmethod
    def parse(cls, reference):
        """
        Parse article reference into structured format.
        
        Args:
            reference: Raw reference string
            
        Returns:
            dict with raw, parsed, components, and type
        """
        if not reference or reference == 'Not specified':
            return {
                'raw': reference,
                'parsed': 'Not specified',
                'type': 'none',
                'components': {}
            }
        
        # Try complex URI-structured format first
        complex_match = cls.COMPLEX_PATTERN.search(reference)
        if complex_match:
            article = complex_match.group(1)
            paragraph = complex_match.group(2)
            point = complex_match.group(3)
            
            parsed = f"Article {article}"
            components = {'article': int(article)}
            
            if paragraph:
                parsed += f", Paragraph {paragraph}"
                components['paragraph'] = int(paragraph)
            
            if point:
                parsed += f", Point ({point})"
                components['point'] = point
            
            return {
                'raw': reference,
                'parsed': parsed,
                'type': 'uri_structured',
                'components': components
            }
        
        # Try simple format (A58P5)
        simple_match = cls.SIMPLE_PATTERN.match(reference)
        if simple_match:
            article = simple_match.group(1)
            paragraph = simple_match.group(2)
            
            parsed = f"Article {article}"
            components = {'article': int(article)}
            
            if paragraph:
                parsed += f", Paragraph {paragraph}"
                components['paragraph'] = int(paragraph)
            
            return {
                'raw': reference,
                'parsed': parsed,
                'type': 'simple',
                'components': components
            }
        
        # Try to extract any numbers as potential articles
        number_match = re.search(r'\b(\d+)\b', reference)
        if number_match:
            article = number_match.group(1)
            return {
                'raw': reference,
                'parsed': f"Article {article} (inferred)",
                'type': 'inferred',
                'components': {'article': int(article)}
            }
        
        # Return as-is if can't parse
        return {
            'raw': reference,
            'parsed': reference,
            'type': 'original',
            'components': {}
        }


class CellarXMLParser:
    """Main parser for CELLAR tree XML notices"""
    
    def __init__(self, config_path='cellar_xpath_config.json'):
        """Initialize parser with XPath configuration"""
        with open(config_path, 'r', encoding='utf-8') as f:
            self.config = json.load(f)
    
    def parse_xml_file(self, xml_path):
        """Parse XML file and return lxml tree"""
        try:
            parser = etree.XMLParser(remove_blank_text=True, huge_tree=True)
            tree = etree.parse(str(xml_path), parser)
            return tree
        except Exception as e:
            raise Exception(f"Failed to parse XML: {e}")
    
    def identify_main_work(self, tree, celex_hint=None):
        """
        Identify the main WORK element to extract from.
        
        Strategy:
        1. Use celex_hint from folder name if provided
        2. Prefer CELEX starting with '3' (original acts)
        3. Return the WORK element containing that CELEX
        
        Args:
            tree: lxml tree
            celex_hint: CELEX ID from folder name (e.g., '32016R0679')
            
        Returns:
            lxml Element for the main WORK, or None
        """
        # Find all WORK elements with RESOURCE_LEGAL_ID_CELEX
        works = tree.xpath("//WORK[.//RESOURCE_LEGAL_ID_CELEX]")
        
        if not works:
            # Fallback: find any WORK element
            works = tree.xpath("//WORK")
        
        if not works:
            return None
        
        # If celex_hint provided, find matching WORK
        if celex_hint:
            for work in works:
                celex_values = work.xpath(".//RESOURCE_LEGAL_ID_CELEX/VALUE/text()")
                if celex_hint in celex_values:
                    return work
        
        # Fallback: Find work with CELEX starting with '3' (original acts)
        for work in works:
            celex_values = work.xpath(".//RESOURCE_LEGAL_ID_CELEX/VALUE/text()")
            for celex in celex_values:
                if celex and celex.startswith('3'):
                    return work
        
        # Last resort: return first WORK
        return works[0]
    
    def extract_text_from_element(self, element, xpath):
        """Extract single text value from an element using relative XPath"""
        try:
            result = element.xpath(xpath)
            if result and len(result) > 0:
                text = result[0].text if hasattr(result[0], 'text') else str(result[0])
                return text.strip() if text else None
            return None
        except Exception as e:
            return None
    
    def extract_array_from_element(self, element, xpath):
        """Extract array of text values from an element using relative XPath"""
        try:
            results = element.xpath(xpath)
            values = []
            for result in results:
                text = result.text if hasattr(result, 'text') else str(result)
                if text and text.strip():
                    values.append(text.strip())
            return values
        except Exception as e:
            return []
    
    def extract_text(self, tree, xpath):
        """Extract single text value using XPath"""
        try:
            result = tree.xpath(xpath)
            if result and len(result) > 0:
                text = result[0].text if hasattr(result[0], 'text') else str(result[0])
                return text.strip() if text else None
            return None
        except Exception as e:
            return None
    
    def extract_array(self, tree, xpath):
        """Extract array of text values using XPath"""
        try:
            results = tree.xpath(xpath)
            values = []
            for result in results:
                text = result.text if hasattr(result, 'text') else str(result)
                if text and text.strip():
                    values.append(text.strip())
            return values
        except Exception as e:
            return []
    
    def detect_languages(self, tree):
        """Detect available languages in the document"""
        languages = set()
        
        # Method 1: EXPRESSION_USES_LANGUAGE
        lang_elements = tree.xpath('//EXPRESSION_USES_LANGUAGE/URI/IDENTIFIER')
        for elem in lang_elements:
            if elem.text:
                # Extract language code (e.g., 'ENG' from URI)
                lang = elem.text.strip().split('/')[-1].lower()
                if len(lang) == 3:
                    languages.add(lang)
        
        # Method 2: LANG elements
        lang_tags = tree.xpath('//LANG')
        for elem in lang_tags:
            if elem.text and len(elem.text.strip()) == 3:
                languages.add(elem.text.strip().lower())
        
        # Method 3: xml:lang attributes
        lang_attrs = tree.xpath('//*[@xml:lang]/@xml:lang | //*[@lang]/@lang')
        for lang in lang_attrs:
            if lang and len(lang) in [2, 3]:
                languages.add(lang.lower())
        
        return sorted(list(languages))
    
    def extract_title(self, tree, main_work):
        """Extract all title information from main work context"""
        cfg = self.config['title']
        
        # Find English expression within the main WORK
        primary_title = 'Not found'
        short_title = []
        subtitle = []
        
        # Get expressions from the main work
        if main_work is not None:
            # Check if this is /NOTICE/WORK (expressions are siblings at /NOTICE/EXPRESSION)
            parent = main_work.getparent()
            if parent is not None and parent.tag == 'NOTICE':
                expressions = parent.xpath('./EXPRESSION')
            else:
                # Expressions are descendants of the work
                expressions = main_work.xpath('.//EXPRESSION')
        else:
            # Fallback to tree-level search
            expressions = tree.xpath('//EXPRESSION')
        
        for expr in expressions:
            # Check language
            lang_elem = expr.xpath('./EXPRESSION_USES_LANGUAGE/URI/IDENTIFIER')
            if lang_elem and lang_elem[0].text:
                lang = lang_elem[0].text.strip().split('/')[-1].upper()
                
                if lang == 'ENG':
                    # Get title from this English expression
                    title_elem = expr.xpath('./EXPRESSION_TITLE/VALUE')
                    if title_elem and title_elem[0].text:
                        primary_title = title_elem[0].text.strip()
                    
                    # Get short title
                    short_elem = expr.xpath('./EXPRESSION_TITLE_SHORT/VALUE')
                    if short_elem and short_elem[0].text:
                        short_title = [short_elem[0].text.strip()]
                    
                    # Get subtitle
                    sub_elem = expr.xpath('./EXPRESSION_SUBTITLE/VALUE')
                    if sub_elem and sub_elem[0].text:
                        subtitle = [sub_elem[0].text.strip()]
                    
                    break
        
        # Fallback to old method if English not found
        if primary_title == 'Not found':
            title_results = tree.xpath('//EXPRESSION_TITLE/VALUE')
            if title_results and len(title_results) > 1 and title_results[1].text:
                primary_title = title_results[1].text.strip()
        
        # Get multilingual titles
        multilingual = {}
        for expr in expressions:
            lang_elem = expr.xpath('./EXPRESSION_USES_LANGUAGE/URI/IDENTIFIER')
            title_elem = expr.xpath('./EXPRESSION_TITLE/VALUE')
            
            if lang_elem and lang_elem[0].text and title_elem and title_elem[0].text:
                lang = lang_elem[0].text.strip().split('/')[-1].lower()
                if lang not in multilingual:
                    multilingual[lang] = []
                multilingual[lang].append(title_elem[0].text.strip())
        
        return {
            'primary': primary_title,
            'work': self.extract_text(tree, cfg['work']) or 'Not found',
            'alternative': self.extract_array(tree, cfg['alternative']),
            'subtitle': subtitle,
            'short': short_title,
            'multilingual': multilingual
        }
    
    def extract_dates(self, tree, main_work):
        """Extract all date information from main work context"""
        cfg = self.config['dates']
        
        # Extract from main work if available
        if main_work is not None:
            # Use direct children (./...) not all descendants (.//...) to avoid embedded documents
            doc_date = self.extract_text_from_element(main_work, './WORK_DATE_DOCUMENT/VALUE')
            if not doc_date:
                year = self.extract_text_from_element(main_work, './WORK_DATE_DOCUMENT/YEAR')
                month = self.extract_text_from_element(main_work, './WORK_DATE_DOCUMENT/MONTH')
                day = self.extract_text_from_element(main_work, './WORK_DATE_DOCUMENT/DAY')
                if year and month and day:
                    doc_date = f"{year}-{month.zfill(2)}-{day.zfill(2)}"
            
            return {
                'document': doc_date or 'Not found',
                'publication': self.extract_text_from_element(main_work, './RESOURCE_LEGAL_PUBLISHED_IN_OFFICIAL-JOURNAL/EMBEDDED_NOTICE/WORK/DATE_PUBLICATION/VALUE') or 'Not found',
                'signature': self.extract_text_from_element(main_work, './RESOURCE_LEGAL_DATE_SIGNATURE/VALUE') or 'Not found',
                'entryIntoForce': self.extract_text_from_element(main_work, './RESOURCE_LEGAL_DATE_ENTRY-INTO-FORCE/VALUE') or 'Not found',
                'endOfValidity': self.extract_text_from_element(main_work, './RESOURCE_LEGAL_DATE_END-OF-VALIDITY/VALUE') or 'Not found',
                'transpositionDeadline': self.extract_text_from_element(main_work, './RESOURCE_LEGAL_DATE_DEADLINE/VALUE') or 'Not found'
            }
        else:
            # Fallback to tree-level extraction
            doc_date = self.extract_text(tree, cfg['document'])
            if not doc_date:
                year = self.extract_text(tree, cfg['document_year'])
                month = self.extract_text(tree, cfg['document_month'])
                day = self.extract_text(tree, cfg['document_day'])
                if year and month and day:
                    doc_date = f"{year}-{month.zfill(2)}-{day.zfill(2)}"
            
            return {
                'document': doc_date or 'Not found',
                'publication': self.extract_text(tree, cfg['publication']) or 'Not found',
                'signature': self.extract_text(tree, cfg['signature']) or 'Not found',
                'entryIntoForce': self.extract_text(tree, cfg['entry_into_force']) or 'Not found',
                'endOfValidity': self.extract_text(tree, cfg['end_of_validity']) or 'Not found',
                'transpositionDeadline': self.extract_text(tree, cfg['transposition_deadline']) or 'Not found'
            }
    
    def extract_identifiers(self, tree, main_work):
        """Extract all identifier information from main work context"""
        cfg = self.config['identifiers']
        
        if main_work is not None:
            # Get CELEX from main work - prefer original acts (starting with '3')
            celex = None
            celex_values = main_work.xpath('.//RESOURCE_LEGAL_ID_CELEX/VALUE/text()')
            
            # First try to find a CELEX starting with '3' (original acts)
            for val in celex_values:
                if val and val.strip().startswith('3'):
                    celex = val.strip()
                    break
            
            # If no '3' CELEX found, use the first one
            if not celex and celex_values:
                celex = celex_values[0].strip() if celex_values[0] else None
            
            # Fallback to ID_CELEX
            if not celex:
                celex = self.extract_text_from_element(main_work, './/ID_CELEX/VALUE')
            
            # Get ELI from main work
            eli = self.extract_text_from_element(main_work, './/RESOURCE_LEGAL_ELI/VALUE')
            if not eli:
                eli = self.extract_text_from_element(main_work, './/ELI/VALUE')
            
            return {
                'celex': celex or 'Not found',
                'eli': eli or 'Not found',
                'ojReference': self.extract_text_from_element(main_work, './/SAMEAS[URI/TYPE="oj"]/URI/IDENTIFIER') or 'Not found',
                'immc': self.extract_text_from_element(main_work, './/SAMEAS[URI/TYPE="immc"]/URI/IDENTIFIER') or 'Not found',
                'naturalNumber': self.extract_text_from_element(main_work, './/RESOURCE_LEGAL_NUMBER_NATURAL_CELEX/VALUE') or 'Not found',
                'type': self.extract_text_from_element(main_work, './/RESOURCE_LEGAL_TYPE/VALUE') or 'Not found',
                'year': self.extract_text_from_element(main_work, './/RESOURCE_LEGAL_YEAR/VALUE') or 'Not found',
                'sector': self.extract_text_from_element(main_work, './/ID_SECTOR/VALUE') or 'Not found'
            }
        else:
            # Fallback to tree-level extraction
            celex = self.extract_text(tree, cfg['celex'])
            if not celex:
                celex = self.extract_text(tree, cfg['celex_secondary'])
            
            eli = self.extract_text(tree, cfg['eli'])
            if not eli:
                eli = self.extract_text(tree, cfg['resource_legal_eli'])
            
            return {
                'celex': celex or 'Not found',
                'eli': eli or 'Not found',
                'ojReference': self.extract_text(tree, cfg['oj_reference']) or 'Not found',
                'immc': self.extract_text(tree, cfg['immc']) or 'Not found',
                'naturalNumber': self.extract_text(tree, cfg['natural_number']) or 'Not found',
                'type': self.extract_text(tree, cfg['type']) or 'Not found',
                'year': self.extract_text(tree, cfg['year']) or 'Not found',
                'sector': self.extract_text(tree, cfg['sector']) or 'Not found'
            }
    
    def extract_eurovoc(self, tree, main_work):
        """Extract Eurovoc classifications with IDs and labels from main work context"""
        cfg = self.config['eurovoc']
        
        # Use main_work if available, otherwise use tree
        search_context = main_work if main_work is not None else tree
        
        def extract_eurovoc_category(id_xpath, label_xpath):
            """Extract Eurovoc items with IDs and labels"""
            items = []
            # Make xpath relative if we have main_work
            if main_work is not None:
                id_xpath_rel = './/' + id_xpath.lstrip('/')
                label_xpath_rel = './/' + label_xpath.lstrip('/')
                id_elements = search_context.xpath(id_xpath_rel)
                label_elements = search_context.xpath(label_xpath_rel)
            else:
                id_elements = search_context.xpath(id_xpath)
                label_elements = search_context.xpath(label_xpath)
            
            for i, id_elem in enumerate(id_elements):
                if id_elem.text:
                    item = {
                        'id': id_elem.text.strip(),
                        'label': 'No label',
                        'language': 'unknown'
                    }
                    
                    # Try to match with corresponding label
                    if i < len(label_elements):
                        label_elem = label_elements[i]
                        if label_elem.text:
                            item['label'] = label_elem.text.strip()
                        lang = label_elem.get('xml:lang') or label_elem.get('lang')
                        if lang:
                            item['language'] = lang
                    
                    items.append(item)
            
            return items
        
        return {
            'concepts': extract_eurovoc_category(cfg['concept_id'], cfg['concept_label']),
            'domains': extract_eurovoc_category(cfg['domain_id'], cfg['domain_label']),
            'microthesaurus': extract_eurovoc_category(cfg['microthesaurus_id'], cfg['microthesaurus_label']),
            'terms': extract_eurovoc_category(cfg['term_id'], cfg['term_label'])
        }
    
    def extract_caselaw(self, tree):
        """Extract and categorize case law references with article parsing"""
        cfg = self.config['caselaw']
        caselaw_items = []
        
        for case_type, case_cfg in cfg.items():
            # Find all elements of this case law type
            case_elements = tree.xpath(case_cfg['xpath'])
            
            for case_elem in case_elements:
                # Extract CELEX ID
                celex_elements = case_elem.xpath(case_cfg['celex'])
                if not celex_elements:
                    # Fall back to any identifier
                    celex_elements = case_elem.xpath(case_cfg['identifier'])
                
                for celex_elem in celex_elements:
                    if celex_elem.text:
                        celex_id = celex_elem.text.strip()
                        
                        # Extract ECLI if available
                        ecli = None
                        if 'ecli' in case_cfg:
                            ecli_elements = case_elem.xpath(case_cfg['ecli'])
                            if ecli_elements and ecli_elements[0].text:
                                ecli = ecli_elements[0].text.strip()
                        
                        # Extract article references if available
                        articles = []
                        parsed_articles = []
                        
                        if 'articles' in case_cfg:
                            article_elements = case_elem.xpath(case_cfg['articles'])
                            for art_elem in article_elements:
                                if art_elem.text:
                                    article_ref = art_elem.text.strip()
                                    articles.append(article_ref)
                                    
                                    # Parse the article reference
                                    parsed = ArticleReferenceParser.parse(article_ref)
                                    parsed_articles.append(parsed)
                        
                        # If no articles found, add placeholder
                        if not articles:
                            articles = ['Not specified']
                            parsed_articles = [ArticleReferenceParser.parse('Not specified')]
                        
                        caselaw_items.append({
                            'celexId': celex_id,
                            'ecli': ecli,
                            'articles': articles,
                            'parsedArticles': parsed_articles,
                            'type': case_cfg['type']
                        })
        
        return caselaw_items
    
    def extract_implementation(self, tree):
        """Extract implementation information"""
        cfg = self.config['implementation']
        implementations = []
        
        impl_elements = tree.xpath(cfg['xpath'])
        for impl_elem in impl_elements:
            identifier_elem = impl_elem.xpath(cfg['identifier'])
            country_elem = impl_elem.xpath(cfg['country'])
            
            if identifier_elem and identifier_elem[0].text:
                implementations.append({
                    'identifier': identifier_elem[0].text.strip(),
                    'country': country_elem[0].text.strip() if country_elem and country_elem[0].text else 'Unknown',
                    'status': 'Implemented'
                })
        
        return implementations
    
    def extract_legal_relations(self, tree, main_work):
        """Extract legal relationships from main work context"""
        cfg = self.config['legal_relations']
        
        if main_work is not None:
            # For based_on and repeals, merge results from multiple XPaths
            based_on = self.extract_array_from_element(main_work, './/BASED_ON/SAMEAS/URI/IDENTIFIER')
            based_on.extend(self.extract_array_from_element(main_work, './/RESOURCE_LEGAL_BASED_ON_RESOURCE_LEGAL/SAMEAS/URI/IDENTIFIER'))
            
            repeals = self.extract_array_from_element(main_work, './/RESOURCE_LEGAL_REPEALS_RESOURCE_LEGAL/SAMEAS/URI/IDENTIFIER')
            repeals.extend(self.extract_array_from_element(main_work, './/RESOURCE_LEGAL_DOES_REPEAL_OF_RESOURCE_LEGAL/SAMEAS/URI/IDENTIFIER'))
            
            return {
                'basedOn': list(set(based_on)),  # Remove duplicates
                'cites': self.extract_array_from_element(main_work, './/WORK_CITES_WORK/SAMEAS/URI/IDENTIFIER'),
                'amends': self.extract_array_from_element(main_work, './/RESOURCE_LEGAL_AMENDS_RESOURCE_LEGAL/SAMEAS/URI/IDENTIFIER'),
                'repeals': list(set(repeals)),  # Remove duplicates
                'consolidatedBy': self.extract_array_from_element(main_work, './/RESOURCE_LEGAL_CONSOLIDATED_BY_ACT_CONSOLIDATED/SAMEAS/URI/IDENTIFIER'),
                'correctedBy': self.extract_array_from_element(main_work, './/RESOURCE_LEGAL_CORRECTED_BY_RESOURCE_LEGAL/SAMEAS/URI/IDENTIFIER'),
                'treatyBasis': self.extract_array_from_element(main_work, './/RESOURCE_LEGAL_BASED_ON_CONCEPT_TREATY/PREFLABEL')
            }
        else:
            # Fallback to tree-level extraction
            based_on = self.extract_array(tree, cfg['based_on'])
            based_on.extend(self.extract_array(tree, cfg['based_on_legal']))
            
            repeals = self.extract_array(tree, cfg['repeals'])
            repeals.extend(self.extract_array(tree, cfg['repeals_alt']))
            
            return {
                'basedOn': list(set(based_on)),  # Remove duplicates
                'cites': self.extract_array(tree, cfg['cites']),
                'amends': self.extract_array(tree, cfg['amends']),
                'repeals': list(set(repeals)),  # Remove duplicates
                'consolidatedBy': self.extract_array(tree, cfg['consolidated_by']),
                'correctedBy': self.extract_array(tree, cfg['corrected_by']),
                'treatyBasis': self.extract_array(tree, cfg['treaty_basis'])
            }
    
    def extract_metadata(self, tree, main_work):
        """Extract additional metadata from main work context"""
        cfg = self.config['metadata']
        
        if main_work is not None:
            # Try both paths for created_by
            created_by = self.extract_text_from_element(main_work, './/WORK_CREATED_BY_AGENT/PREFLABEL')
            if not created_by:
                created_by = self.extract_text_from_element(main_work, './/CREATED_BY/PREFLABEL')
            
            return {
                'createdBy': created_by or 'Not found',
                'responsibleAgent': self.extract_text_from_element(main_work, './/RESOURCE_LEGAL_RESPONSIBILITY_OF_AGENT/PREFLABEL') or 'Not found',
                'inForce': self.extract_text_from_element(main_work, './/RESOURCE_LEGAL_IN-FORCE/VALUE') or 'Not found',
                'subjectMatter': self.extract_text_from_element(main_work, './/RESOURCE_LEGAL_IS_ABOUT_SUBJECT-MATTER_1/PREFLABEL') or 'Not found',
                'dossierReference': self.extract_text_from_element(main_work, './/WORK_PART_OF_DOSSIER/SAMEAS/URI/IDENTIFIER') or 'Not found',
                'version': self.extract_text_from_element(main_work, './/VERSION/VALUE') or 'Not found',
                'lastModified': self.extract_text_from_element(main_work, './/LASTMODIFICATIONDATE/VALUE') or 'Not found'
            }
        else:
            # Fallback to tree-level extraction
            created_by = self.extract_text(tree, cfg['created_by'])
            if not created_by:
                created_by = self.extract_text(tree, cfg['created_by_alt'])
            
            return {
                'createdBy': created_by or 'Not found',
                'responsibleAgent': self.extract_text(tree, cfg['responsible_agent']) or 'Not found',
                'inForce': self.extract_text(tree, cfg['in_force']) or 'Not found',
                'subjectMatter': self.extract_text(tree, cfg['subject_matter']) or 'Not found',
                'dossierReference': self.extract_text(tree, cfg['dossier_reference']) or 'Not found',
                'version': self.extract_text(tree, cfg['version']) or 'Not found',
                'lastModified': self.extract_text(tree, cfg['last_modified']) or 'Not found'
            }
    
    def calculate_stats(self, document_data):
        """Calculate statistics from extracted data"""
        eurovoc = document_data.get('eurovoc', {})
        caselaw = document_data.get('caselaw', [])
        relations = document_data.get('legalRelations', {})
        implementation = document_data.get('implementation', [])
        
        # Count total Eurovoc items
        total_eurovoc = (
            len(eurovoc.get('concepts', [])) +
            len(eurovoc.get('domains', [])) +
            len(eurovoc.get('microthesaurus', [])) +
            len(eurovoc.get('terms', []))
        )
        
        # Count total articles mentioned in case law
        total_articles = sum(
            len([a for a in case.get('parsedArticles', []) if a.get('type') != 'none'])
            for case in caselaw
        )
        
        # Count total legal relations
        total_relations = sum(
            len(relations.get(key, []))
            for key in ['basedOn', 'cites', 'amends', 'repeals', 'consolidatedBy', 'correctedBy', 'treatyBasis']
        )
        
        return {
            'languages': len(document_data.get('languages', [])),
            'cases': len(caselaw),
            'eurovoc': total_eurovoc,
            'articles': total_articles,
            'relations': total_relations,
            'implementations': len(implementation)
        }
    
    def build_metadata_json(self, tree, main_work, celex):
        """Build complete JSON structure matching the schema"""
        languages = self.detect_languages(tree)
        
        document_data = {
            'languages': languages,
            'title': self.extract_title(tree, main_work),
            'dates': self.extract_dates(tree, main_work),
            'identifiers': self.extract_identifiers(tree, main_work),
            'eurovoc': self.extract_eurovoc(tree, main_work),
            'caselaw': self.extract_caselaw(tree),
            'implementation': self.extract_implementation(tree),
            'legalRelations': self.extract_legal_relations(tree, main_work),
            'metadata': self.extract_metadata(tree, main_work)
        }
        
        # Calculate statistics
        stats = self.calculate_stats(document_data)
        
        return {
            'extraction_timestamp': datetime.now().isoformat(),
            'selected_language': 'eng',
            'available_languages': languages,
            'document': document_data,
            'stats': stats
        }
    
    def save_json(self, data, output_path):
        """Save metadata as formatted JSON"""
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
    
    def process_document(self, xml_path, celex=None, output_dir=None):
        """
        Process a single document.
        
        Args:
            xml_path: Path to XML file
            celex: CELEX ID (will be extracted if not provided)
            output_dir: Output directory (uses XML directory if not provided)
            
        Returns:
            tuple: (success, output_path, error_message)
        """
        try:
            xml_path = Path(xml_path)
            
            # Parse XML
            tree = self.parse_xml_file(xml_path)
            
            # Extract CELEX hint from folder name if not provided
            celex_hint = celex
            if not celex_hint:
                folder_name = xml_path.parent.name
                # Try to extract from folder like "REG-2016-679" or "DIR-94-21"
                celex_match = re.search(r'(\w+(?:-\w+)?)-(\d{4})-(\d+)', folder_name)
                if celex_match:
                    doc_type_str = celex_match.group(1)
                    year = celex_match.group(2)
                    number = celex_match.group(3)
                    
                    # Map document type to CELEX format
                    type_map = {
                        'REG': 'R',
                        'REG-IMPL': 'R',
                        'REG-DELEG': 'R',
                        'DIR': 'L',
                        'DEC': 'D',
                        'DEC-IMPL': 'D'
                    }
                    doc_type = type_map.get(doc_type_str, 'R')
                    celex_hint = f"3{year}{doc_type}{number.zfill(4)}"
            
            # Identify the main WORK element
            main_work = self.identify_main_work(tree, celex_hint)
            
            # Extract CELEX from the identified main work - prefer original acts (starting with '3')
            if not celex:
                if main_work is not None:
                    celex_values = main_work.xpath('.//RESOURCE_LEGAL_ID_CELEX/VALUE/text()')
                    # Prefer CELEX starting with '3'
                    for val in celex_values:
                        if val and val.strip().startswith('3'):
                            celex = val.strip()
                            break
                    # Fallback to first CELEX
                    if not celex and celex_values:
                        celex = celex_values[0].strip() if celex_values[0] else None
                if not celex:
                    celex = celex_hint if celex_hint else 'unknown'
            
            # Build metadata
            metadata = self.build_metadata_json(tree, main_work, celex)
            
            # Determine output path
            if output_dir:
                output_path = Path(output_dir) / f"{celex}_metadata.json"
            else:
                output_path = xml_path.parent / f"{celex}_metadata.json"
            
            # Save JSON
            self.save_json(metadata, output_path)
            
            return (True, output_path, None)
            
        except Exception as e:
            return (False, None, str(e))
    
    def process_batch(self, root_dir, limit=None, skip_existing=True, verbose=False):
        """
        Process multiple documents in a directory tree.
        
        Args:
            root_dir: Root directory to scan
            limit: Max number of documents to process
            skip_existing: Skip if JSON already exists
            verbose: Print detailed progress
            
        Returns:
            dict: Statistics about processing
        """
        root_dir = Path(root_dir)
        results = {
            'success': 0,
            'failed': 0,
            'skipped': 0,
            'errors': []
        }
        
        # Find all cellar_tree_notice.xml files
        xml_files = list(root_dir.rglob('cellar_tree_notice.xml'))
        
        if limit:
            xml_files = xml_files[:limit]
        
        print(f"Found {len(xml_files)} XML files to process")
        
        for i, xml_path in enumerate(xml_files, 1):
            # Extract CELEX from folder name or XML
            folder_name = xml_path.parent.name
            celex = None
            
            # Try to extract CELEX from folder name
            celex_match = re.search(r'([0-9]{5}[A-Z]{1,2}[0-9]{4}[A-Z]*\(?[0-9]*\)?)', folder_name)
            if celex_match:
                celex = celex_match.group(1)
            
            # Check if output already exists
            if celex:
                output_path = xml_path.parent / f"{celex}_metadata.json"
                if skip_existing and output_path.exists():
                    results['skipped'] += 1
                    if verbose:
                        print(f"[{i}/{len(xml_files)}] Skipped: {celex} (already exists)")
                    continue
            
            # Process document
            if verbose:
                print(f"[{i}/{len(xml_files)}] Processing: {xml_path.parent.name}")
            
            success, out_path, error = self.process_document(xml_path, celex)
            
            if success:
                results['success'] += 1
                if verbose:
                    print(f"  ✓ Success: {out_path.name}")
            else:
                results['failed'] += 1
                results['errors'].append({
                    'file': str(xml_path),
                    'error': error
                })
                if verbose:
                    print(f"  ✗ Failed: {error}")
        
        return results


def main():
    """CLI entry point"""
    parser = argparse.ArgumentParser(
        description='Extract metadata from CELLAR XML notices'
    )
    
    parser.add_argument('--xml', type=str, help='Single XML file to process')
    parser.add_argument('--celex', type=str, help='CELEX ID for single file mode')
    parser.add_argument('--output', type=str, help='Output directory for single file')
    parser.add_argument('--folder', type=str, help='Single folder to process')
    parser.add_argument('--root', type=str, help='Root directory to scan recursively')
    parser.add_argument('--limit', type=int, help='Max number of documents to process')
    parser.add_argument('--skip-existing', action='store_true', default=True,
                       help='Skip if JSON already exists')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Print detailed progress')
    parser.add_argument('--config', type=str, default='cellar_xpath_config.json',
                       help='Path to XPath configuration file')
    
    args = parser.parse_args()
    
    # Initialize parser
    try:
        extractor = CellarXMLParser(args.config)
    except Exception as e:
        print(f"Error loading configuration: {e}")
        return 1
    
    # Single file mode
    if args.xml:
        print(f"Processing single file: {args.xml}")
        success, output_path, error = extractor.process_document(
            args.xml, args.celex, args.output
        )
        
        if success:
            print(f"✓ Success! Output: {output_path}")
            return 0
        else:
            print(f"✗ Failed: {error}")
            return 1
    
    # Folder mode
    elif args.folder:
        folder_path = Path(args.folder)
        xml_path = folder_path / 'cellar_tree_notice.xml'
        
        if not xml_path.exists():
            print(f"Error: No cellar_tree_notice.xml found in {folder_path}")
            return 1
        
        print(f"Processing folder: {folder_path.name}")
        success, output_path, error = extractor.process_document(xml_path)
        
        if success:
            print(f"✓ Success! Output: {output_path}")
            return 0
        else:
            print(f"✗ Failed: {error}")
            return 1
    
    # Batch mode
    elif args.root:
        print(f"Scanning directory: {args.root}")
        results = extractor.process_batch(
            args.root,
            limit=args.limit,
            skip_existing=args.skip_existing,
            verbose=args.verbose
        )
        
        # Print summary
        print("\n" + "="*60)
        print("PROCESSING SUMMARY")
        print("="*60)
        print(f"✓ Success: {results['success']}")
        print(f"✗ Failed:  {results['failed']}")
        print(f"⏭ Skipped: {results['skipped']}")
        
        if results['errors']:
            print(f"\nErrors ({len(results['errors'])}):")
            for err in results['errors'][:5]:
                print(f"  - {Path(err['file']).parent.name}: {err['error']}")
            if len(results['errors']) > 5:
                print(f"  ... and {len(results['errors']) - 5} more")
        
        return 0 if results['failed'] == 0 else 1
    
    else:
        parser.print_help()
        return 1


if __name__ == '__main__':
    exit(main())

