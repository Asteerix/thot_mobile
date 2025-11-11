#!/usr/bin/env python3

def clean_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    cleaned_lines = []
    for i, line in enumerate(lines):
        # Skip lines that are just whitespace + );
        if line.strip() == ');':
            continue
        # Skip lines that are just comments like: // p.id).toList(),
        if line.strip().startswith('// ') and ').toList()' in line:
            continue
        cleaned_lines.append(line)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(cleaned_lines)
    
    print(f"Cleaned {filepath}")

clean_file('lib/features/posts/presentation/mobile/screens/details/post_detail_screen.dart')

