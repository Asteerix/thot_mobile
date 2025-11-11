#!/usr/bin/env python3
import re

def clean_fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Pattern: print('[Message] ' + {map},  followed by stuff and .toString());
    # Replace with debugPrint using string interpolation
    def replace_print_with_map(match):
        message = match.group(1)
        map_content = match.group(2)
        # Extract key-value pairs from map
        return f"debugPrint('{message}');"
    
    # Remove all multi-line prints with maps - just keep the message
    content = re.sub(
        r"print\(\s*'([^']+)'\s*\+\s*\{[^}]+\}[^;]*\);",
        replace_print_with_map,
        content,
        flags=re.DOTALL
    )
    
    # Remove problematic .toString() calls
    content = re.sub(r'\.toString\(\)\s*\);', ');', content)
    content = re.sub(r',\s*\.toString\(\);', ');', content)
    
    with open(filepath, 'w') as f:
        f.write(content)

files = [
    'lib/features/posts/presentation/mobile/screens/feed_screen.dart',
    'lib/features/posts/presentation/mobile/screens/post_detail_screen.dart',
    'lib/core/navigation/app_router.dart',
    'lib/features/posts/presentation/mobile/screens/saved_content_screen.dart',
    'lib/features/profile/data/repositories/profile_repository_impl.dart',
    'lib/features/posts/presentation/shared/widgets/feed_item.dart',
    'lib/features/posts/presentation/shared/widgets/opposition_dialog.dart',
]

for f in files:
    try:
        clean_fix_file(f)
        print(f'✓ {f}')
    except Exception as e:
        print(f'✗ {f}: {e}')
