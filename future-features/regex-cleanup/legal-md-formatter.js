#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

/**
 * Legal Markdown Formatter
 * 
 * Processes Markdown files with legal document-specific formatting:
 * - Normalizes special characters
 * - Processes headings for legal document structure
 * - Formats case numbers as wiki links
 * - Processes legal links
 * - Formats paragraph numbering and bullet points
 * 
 * Usage:
 *   node legal-md-formatter.js [path]
 *   
 * If path is a directory, processes all .md files in that directory
 * If path is a file, processes that file
 * If no path is given, processes all .md files in current directory
 */

// Helper function to read file content
function readFile(filePath) {
  return fs.readFileSync(filePath, 'utf8');
}

// Helper function to write file content
function writeFile(filePath, content) {
  fs.writeFileSync(filePath, content, 'utf8');
}

// Normalize special characters and clean text
function cleanText(text) {
  // Normalize special characters
  const replacements = {
    '–': '-',
    '—': '-',
    ''': "'",
    ''': "'",
    '"': '"',
    '"': '"',
    '…': '...',
    '\u200b': '', // zero-width space
    '\xa0': ' ',  // non-breaking space
    '\r': '\n',
    '\t': '    ',
    '\f': '\n',
    '\v': '\n',
  };
  
  // Apply all replacements
  Object.entries(replacements).forEach(([old, new_]) => {
    text = text.replaceAll(old, new_);
  });
  
  // Handle special legal formatting
  text = text.replace(/(?<=\d)\.(?=\s)/g, '.\n'); // Add newlines after numbered points
  text = text.replace(/\s*\n\s*\n\s*\n+/g, '\n\n'); // Normalize excessive line breaks
  text = text.replace(/([A-Z])\.\s+(?=[A-Z]\.)/g, '$1.\n'); // Add newlines between lettered points
  
  return text;
}

// Process short lines (paragraph numbers, bullet points, etc.)
function processShortLines(text) {
  const specialPatterns = {
    '^\d+$': 'numbered_paragraph',
    '^\(\d+\)$': 'numbered_point',
    '^[A-Z]\.?$': 'lettered_point',
    '^\([a-z]\)$': 'lettered_subpoint',
    '^–': 'bullet_point',
    '^\d+\.$': 'numbered_section'
  };
  
  const lines = text.split('\n');
  const processed = [];
  let i = 0;
  
  while (i < lines.length) {
    const currentLine = lines[i].trim();
    
    if (!currentLine) {
      processed.push('');
      i++;
      continue;
    }
    
    // Check for special patterns
    let isSpecial = false;
    for (const [pattern, caseType] of Object.entries(specialPatterns)) {
      if (new RegExp(pattern).test(currentLine)) {
        if (i + 1 < lines.length) {
          const nextLine = lines[i + 1].trim();
          if (nextLine) {
            processed.push(`**${currentLine}** ${nextLine}`);
            i += 2;
            isSpecial = true;
            break;
          }
        }
      }
    }
    
    if (!isSpecial) {
      // Handle very short lines that don't match patterns
      if (currentLine.length <= 4 && i + 1 < lines.length) {
        const nextLine = lines[i + 1].trim();
        if (nextLine) {
          processed.push(`**${currentLine}** ${nextLine}`);
          i += 2;
          continue;
        }
      }
      
      processed.push(currentLine);
      i++;
    }
  }
  
  return processed.join('\n');
}

// Process case numbers with enhanced wiki linking format
function processCaseNumbers(text) {
  const patterns = [
    'C-\\d+/\\d+(?:/[A-Z])?',
    'Joined [Cc]ases C-\\d+/\\d+(?:/[A-Z])?(?: and C-\\d+/\\d+(?:/[A-Z])?)+',
    'Cases C-\\d+/\\d+ to C-\\d+/\\d+',
    'T-\\d+/\\d+',
    'P-\\d+/\\d+',
    '(?:and |to |, )C-\\d+/\\d+(?:/[A-Z])?',
    'Cases C-\\d+/\\d+(?:/[A-Z])? and Others',
    'C‑\\d+/\\d+',
    'Joined cases [A-Z]-\\d+/\\d+ to [A-Z]-\\d+/\\d+'
  ];
  
  for (const pattern of patterns) {
    text = text.replace(new RegExp(pattern, 'g'), match => {
      if (/joined|cases|and|to/i.test(match)) {
        // Handle complex case references
        const parts = match.split(/\s+/);
        return parts.map(p => {
          if (/^[CPT]-\d+\/\d+/i.test(p)) {
            // Replace slash with mathematical slash (∕) - Unicode U+2215
            const withMathSlash = p.replace('/', '∕');
            // Create wiki link with original form using pipe
            return `[[${p.replace('/', '-')}|${withMathSlash}]]`;
          }
          return p;
        }).join(' ');
      }
      // Handle simple case references
      // Replace slash with mathematical slash (∕) - Unicode U+2215
      const withMathSlash = match.replace('/', '∕');
      // Create wiki link with original form using pipe
      return `[[${match.replace('/', '-')}|${withMathSlash}]]`;
    });
  }
  
  return text;
}

// Process links
function processLinks(text) {
  const patterns = {
    'case_link': '\\[?(C-\\d+/\\d+(?:/[A-Z])?)\\]?\\s*\\((https?://[^)]+)\\)',
    'paragraph_link': '\\[(\\d+)\\]\\s*\\((https?://[^)]+#point\\d+)\\)',
    'document_link': '\\[((?:Regulation|Directive|Decision)[^\\]]+)\\]\\s*\\((https?://[^)]+)\\)',
    'ecli_link': '\\[(EU:C:\\d{4}:\\d+)\\]\\s*\\((https?://[^)]+)\\)',
    'plain_link': '<a href="([^"]+)"[^>]*>([^<]+)</a>'
  };
  
  for (const [patternType, pattern] of Object.entries(patterns)) {
    if (patternType === 'case_link') {
      text = text.replace(new RegExp(pattern, 'g'), (_, caseRef) => {
        // Replace slash with mathematical slash (∕) - Unicode U+2215
        const withMathSlash = caseRef.replace('/', '∕');
        // Create wiki link with original form using pipe
        return `[[${caseRef.replace('/', '-')}|${withMathSlash}]]`;
      });
    } else {
      text = text.replace(new RegExp(pattern, 'g'), 
                         (_, text, url) => `[${text}](${url})`);
    }
  }
  
  return text;
}

// Process headings
function processHeadings(text) {
  const specialSections = {
    "JUDGMENT OF THE COURT": "## **{}**",
    "ORDER OF THE COURT": "## **{}**",
    "OPINION OF ADVOCATE GENERAL": "## **{}**",
    "Costs": "### **{}**",
    "Procedure": "### **{}**",
    "Legal context": "### **{}**",
    "Background to the dispute": "### **{}**",
    "Forms of order sought": "### **{}**",
    "The dispute": "### **{}**",
    "Admissibility": "### **{}**",
    "The main proceedings": "### **{}**",
    "The questions referred": "### **{}**",
    "Consideration of the questions referred": "### **{}**",
  };
  
  const questionPatterns = [
    '^Questions? \\d+( to \\d+)?$',
    '^The \\d+[a-z]{2} question$',
    '^The questions? referred(?: for a preliminary ruling)?$',
    '^Question referred for a preliminary ruling$'
  ];
  
  const lines = text.split('\n');
  const processed = [];
  
  for (const line of lines) {
    const stripped = line.trim();
    
    // Handle special sections
    if (specialSections[stripped]) {
      processed.push(specialSections[stripped].replace('{}', stripped));
      continue;
    }
    
    // Handle questions
    if (questionPatterns.some(pattern => new RegExp(pattern).test(stripped))) {
      processed.push(`### **${stripped}**`);
      continue;
    }
    
    // Handle ALL CAPS
    if (stripped === stripped.toUpperCase() && stripped && stripped.length > 5) {
      processed.push(`## **${stripped}**`);
      continue;
    }
    
    // Handle "hereby rules:"
    if (stripped.endsWith('hereby rules:')) {
      processed.push(`### **${stripped}**`);
      continue;
    }
    
    processed.push(line);
  }
  
  return processed.join('\n');
}

// Main processing function
function processMarkdown(content) {
  // First clean the text
  let processed = cleanText(content);
  
  // Process headings
  processed = processHeadings(processed);
  
  // Process case numbers and links
  processed = processCaseNumbers(processed);
  processed = processLinks(processed);
  
  // Process short lines (do this last to avoid interfering with heading detection)
  processed = processShortLines(processed);
  
  return processed;
}

// Process a single file
function processFile(filePath) {
  console.log(`Processing: ${filePath}`);
  
  try {
    // Read the file
    const content = readFile(filePath);
    
    // Process the content
    const processed = processMarkdown(content);
    
    // Write the processed content back to the file
    writeFile(filePath, processed);
    
    console.log(`✅ Processed: ${filePath}`);
    return true;
  } catch (err) {
    console.error(`❌ Error processing ${filePath}: ${err.message}`);
    return false;
  }
}

// Process all markdown files in a directory
function processDirectory(dirPath) {
  console.log(`Processing directory: ${dirPath}`);
  
  try {
    // Get all files in the directory
    const files = fs.readdirSync(dirPath);
    
    // Filter for markdown files
    const markdownFiles = files.filter(file => 
      file.toLowerCase().endsWith('.md') && 
      fs.statSync(path.join(dirPath, file)).isFile()
    );
    
    if (markdownFiles.length === 0) {
      console.log(`No markdown files found in ${dirPath}`);
      return 0;
    }
    
    console.log(`Found ${markdownFiles.length} markdown files`);
    
    // Process each file
    let successCount = 0;
    
    for (const file of markdownFiles) {
      const filePath = path.join(dirPath, file);
      const success = processFile(filePath);
      if (success) successCount++;
    }
    
    console.log(`\nSummary: Processed ${successCount} of ${markdownFiles.length} files successfully`);
    return successCount;
  } catch (err) {
    console.error(`Error processing directory ${dirPath}: ${err.message}`);
    return 0;
  }
}

// Main function
function main() {
  const args = process.argv.slice(2);
  let targetPath = process.cwd(); // Default to current directory
  
  if (args.length > 0) {
    targetPath = args[0];
  }
  
  // Check if path exists
  if (!fs.existsSync(targetPath)) {
    console.error(`Error: Path does not exist: ${targetPath}`);
    process.exit(1);
  }
  
  // Check if path is file or directory
  const stats = fs.statSync(targetPath);
  
  if (stats.isFile()) {
    // Process single file
    if (!targetPath.toLowerCase().endsWith('.md')) {
      console.error(`Error: File is not a markdown file: ${targetPath}`);
      process.exit(1);
    }
    
    const success = processFile(targetPath);
    process.exit(success ? 0 : 1);
  } else if (stats.isDirectory()) {
    // Process all markdown files in directory
    const count = processDirectory(targetPath);
    process.exit(count > 0 ? 0 : 1);
  } else {
    console.error(`Error: Path is neither a file nor a directory: ${targetPath}`);
    process.exit(1);
  }
}

// Run the main function
main();