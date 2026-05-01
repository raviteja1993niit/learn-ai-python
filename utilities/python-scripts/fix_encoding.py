#!/usr/bin/env python3
"""Fix encoding issues in markdown file.

DEPRECATED: Superseded by fix_encoding_v2.py which handles additional edge cases
and non-UTF-8 source files. Kept for reference only — do not use in production.
Use fix_encoding_v2.py instead.
"""

filePath = r"C:\Users\e135408\IdeaProjects\MODERNIZATION\Agentic_AI_Flow_Framework_Migration\ultimate-atf-to-flow-migrator\PYTHON_SCRIPTS_COMPLETE_GROUPING.md"

with open(filePath, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace garbled characters with correct emojis and symbols
replacements = {
    # Emojis
    'ðŸ—‚ï¸': '📋',
    'ðŸ"': '📁',
    'ðŸ"–': '📖',
    'ðŸ"Š': '📊',
    'ðŸ"‚': '📂',
    # Checkmarks and X marks
    'âœ…': '✅',
    'âŒ': '❌',
    # Quotes and dashes
    'â€"': '–',
    'â€˜': "'",
    'â€™': "'",
    'â€œ': '"',
    'â€\u009d': '"',
    'â€Ž': '"',
    # Arrows
    'â†': '→',
    'â†'': '↔',
    'â†"': '→',
    # Long dashes
    'â€"': '—',
    'â€Š': '–',
}

for old, new in replacements.items():
    content = content.replace(old, new)

with open(filePath, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ File cleaned successfully!")



