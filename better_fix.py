#!/usr/bin/env python3
import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    new_lines = []
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Check if this line has a print with trailing comma and map literal
        if 'print(' in line and ('{' in line or "'" in line or '"' in line):
            # Collect multi-line print statement
            full_statement = line
            open_braces = line.count('{') - line.count('}')
            open_parens = line.count('(') - line.count(')')
            
            # Continue collecting lines if braces or parens aren't balanced
            while (open_braces > 0 or open_parens > 0 or not full_statement.rstrip().endswith(');')) and i + 1 < len(lines):
                i += 1
                next_line = lines[i]
                full_statement += next_line
                open_braces += next_line.count('{') - next_line.count('}')
                open_parens += next_line.count('(') - next_line.count(')')
            
            # Remove trailing comma before closing paren if exists
            # Pattern: }, \n .toString()); or similar
            full_statement = re.sub(r'},\s*\n\s*\.toString\(\);', '}.toString();', full_statement)
            
            # Remove standalone .toString() lines
            full_statement = re.sub(r'\s*\n\s*\.toString\(\);', '.toString();', full_statement)
            
            # Remove name: parameter if it exists
            full_statement = re.sub(r',\s*name:\s*[\'"][^\'"]*[\'"]', '', full_statement)
            
            # Remove stackTrace: parameter if it exists  
            full_statement = re.sub(r',\s*stackTrace:\s*[^,)]+', '', full_statement)
            
            new_lines.append(full_statement)
        else:
            new_lines.append(line)
        
        i += 1
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)

files = [
    'lib/features/posts/presentation/mobile/screens/feed_screen.dart',
    'lib/features/posts/presentation/mobile/screens/post_detail_screen.dart',
    'lib/features/posts/presentation/mobile/screens/video_detail_screen.dart',
    'lib/features/posts/presentation/mobile/screens/saved_content_screen.dart',
    'lib/features/posts/presentation/shared/widgets/full_article_dialog.dart',
    'lib/features/posts/presentation/shared/widgets/opposition_dialog.dart',
    'lib/features/posts/presentation/shared/widgets/feed_item.dart',
    'lib/features/profile/data/repositories/profile_repository_impl.dart',
    'lib/core/navigation/app_router.dart',
]

for f in files:
    try:
        fix_file(f)
        print(f'✓ {f}')
    except Exception as e:
        print(f'✗ {f}: {e}')
