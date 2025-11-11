#!/usr/bin/env python3
import re

def ultimate_fix(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Replace all malformed print statements with debugPrint and proper string interpolation
    # Pattern: print('[Message] ' + {map}.toString());
    content = re.sub(
        r"print\(\s*'([^']+)'\s*\+\s*(\{[^}]+\})\.toString\(\)\s*\);",
        lambda m: f"debugPrint('{m.group(1)} | ' + {m.group(2)}.entries.map((e) => '${{e.key}}: ${{e.value}}').join(', '));",
        content
    )
    
    # Pattern: print('[Message] ' + e, .toString());
    content = re.sub(
        r"print\(\s*'([^']+)'\s*\+\s*(\w+)\s*,\s*\.toString\(\)\s*\);",
        lambda m: f"debugPrint('{m.group(1)} | ' + {m.group(2)}.toString());",
        content
    )
    
    # Pattern: print('Message', );
    content = re.sub(
        r"print\(\s*'([^']+)'\s*,\s*\);",
        lambda m: f"debugPrint('{m.group(1)}');",
        content
    )
    
    # Replace remaining developer.log with debugPrint
    content = re.sub(
        r"developer\.log\('([^']+)'\);",
        lambda m: f"debugPrint('{m.group(1)}');",
        content
    )
    
    with open(filepath, 'w') as f:
        f.write(content)

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
        ultimate_fix(f)
        print(f'✓ {f}')
    except Exception as e:
        print(f'✗ {f}: {e}')

print('\nAll done!')
