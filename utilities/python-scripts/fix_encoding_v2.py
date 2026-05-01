#!/usr/bin/env python3
"""Fix all encoding issues in markdown file"""

filePath = r"C:\Users\e135408\IdeaProjects\MODERNIZATION\Agentic_AI_Flow_Framework_Migration\ultimate-atf-to-flow-migrator\PYTHON_SCRIPTS_COMPLETE_GROUPING.md"

with open(filePath, 'r', encoding='utf-8') as f:
    content = f.read()

# Find and display what still needs fixing
import re

# More comprehensive replacements for common UTF-8 encoding issues
replacements = {
    # En-dash variations
    'â€"': '–',
    'â€"': '–',
    'â€\u201c': '–',
    # Em-dash variations
    'â€\u2019': '–',
    # Smart quotes
    'â€œ': '"',
    'â€\u009d': '"',
    'â€˜': "'",
    'â€™': "'",
    'â€\u009e': "'",
    # Other common ones
    'âœ…': '✅',
    'âŒ': '❌',
    'â†': '→',
    'â†"': '↔',
    'â†'': '↔',
    'Â': '',  # Extra byte from bad encoding
}

# Additional pattern-based replacements
pattern_replacements = [
    (r'ðŸ[^\s]*', lambda m: {
        'ðŸ—‚ï¸': '📋',
        'ðŸ"': '📁',
        'ðŸ"–': '📖',
        'ðŸ"Š': '📊',
        'ðŸ"‚': '📂',
    }.get(m.group(), m.group())),
]

for old, new in replacements.items():
    content = content.replace(old, new)

# Clean up any remaining double-encoded characters by normalizing whitespace
content = re.sub(r'\s+', lambda m: ' ' if m.group() == ' ' else m.group(), content)

with open(filePath, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ File cleaned successfully!")

