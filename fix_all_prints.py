#!/usr/bin/env python3
import re
import os

def fix_print_in_file(filepath):
    """Fix all print statements in a file to proper Dart syntax"""
    if not os.path.exists(filepath):
        return False
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Pattern 1: print with message, name, and error/stackTrace parameters
    # Example: print('message', name: 'Name', error: {...});
    pattern1 = r"print\(\s*(['\"])(.*?)\1\s*,\s*name:\s*['\"][^'\"]*['\"]\s*,\s*(?:error|stackTrace):\s*([^;]+)\s*\);"
    content = re.sub(pattern1, lambda m: f"print('[{m.group(2)}] ' + {m.group(3)}.toString());", content)
    
    # Pattern 2: print with message and name only
    # Example: print('message', name: 'Name');
    pattern2 = r"print\(\s*(['\"])(.*?)\1\s*,\s*name:\s*['\"][^'\"]*['\"]\s*\);"
    content = re.sub(pattern2, lambda m: f"print('{m.group(2)}');", content)
    
    # Pattern 3: developer.log calls (replace with print)
    pattern3 = r"developer\.log\(([^)]+)\);"
    content = re.sub(pattern3, r"print(\1);", content)
    
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

# List of files to fix
files_to_fix = [
    'lib/features/posts/presentation/mobile/screens/feed_screen.dart',
    'lib/features/posts/presentation/mobile/screens/post_detail_screen.dart',
    'lib/features/posts/presentation/mobile/screens/video_detail_screen.dart',
    'lib/features/posts/presentation/mobile/screens/saved_content_screen.dart',
    'lib/features/posts/presentation/shared/widgets/full_article_dialog.dart',
    'lib/features/posts/presentation/shared/widgets/opposition_dialog.dart',
    'lib/features/posts/presentation/shared/widgets/feed_item.dart',
    'lib/features/profile/data/repositories/profile_repository_impl.dart',
    'lib/features/settings/presentation/mobile/screens/subscriptions_screen.dart',
    'lib/core/navigation/app_router.dart',
]

print("Fixing print statements...")
for filepath in files_to_fix:
    if fix_print_in_file(filepath):
        print(f"✓ Fixed: {filepath}")
    else:
        print(f"✗ Skipped: {filepath} (not found or no changes)")

print("\nDone!")
