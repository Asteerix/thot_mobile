import re
import os

files_to_fix = [
    "lib/features/posts/presentation/mobile/screens/feed_screen.dart",
    "lib/features/posts/presentation/mobile/screens/post_detail_screen.dart",
    "lib/core/navigation/app_router.dart",
]

def fix_print_statement(content):
    # Pattern to match print statements with name and error parameters
    pattern = r'print\(\s*([^,]+),\s*name:\s*[\'"][^\'"]*[\'"]\s*,\s*error:\s*(\{[^}]+\})\s*\);'
    
    def replace_func(match):
        message = match.group(1).strip()
        error_dict = match.group(2).strip()
        return f'print({message} + " " + {error_dict}.toString());'
    
    content = re.sub(pattern, replace_func, content, flags=re.DOTALL)
    
    # Pattern for print with just name parameter
    pattern2 = r'print\(\s*([^,]+),\s*name:\s*[\'"][^\'"]*[\'"]\s*\);'
    content = re.sub(pattern2, r'print(\1);', content)
    
    return content

for file_path in files_to_fix:
    if os.path.exists(file_path):
        print(f"Processing {file_path}")
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        content = fix_print_statement(content)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✓ Fixed {file_path}")
    else:
        print(f"✗ File not found: {file_path}")

print("\nDone!")
