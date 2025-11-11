#!/usr/bin/env python3
import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove the developer.log import if present
    content = re.sub(r"import 'dart:developer' as developer;\n", '', content)
    
    # Pattern 1: Simple print calls that are already corrupted with extra params
    # print('message', ...) or print('message'\n   name: 'name',\n   error: {...})
    # We need to extract just the message
    
    # First, let's handle multiline print statements with name: and error: parameters
    def replace_multiline_print(match):
        full_match = match.group(0)
        # Extract the first string parameter
        message_match = re.search(r"print\(\s*'([^']*)'", full_match)
        if message_match:
            message = message_match.group(1)
            # Get the indentation
            indent_match = re.search(r'^(\s*)', full_match)
            indent = indent_match.group(1) if indent_match else ''
            return f"{indent}print('{message}');"
        return full_match
    
    # Match print statements that span multiple lines with name: or error: parameters
    pattern = r"([ \t]*)print\(\s*'[^']*'[^;]*?(name:\s*[^,]+|error:\s*\{[^}]*\})[^;]*?\);"
    content = re.sub(pattern, replace_multiline_print, content, flags=re.MULTILINE | re.DOTALL)
    
    # Now handle broken statements like: print('message'),
    # These appear when there's a comma instead of semicolon
    content = re.sub(r"print\('([^']*)'\),", r"print('\1');", content)
    
    # Handle pattern like: print('message') {
    content = re.sub(r"print\('([^']*)'\)\s*\{", r"print('\1');\n    } catch (e) {", content)
    
    # Handle patterns like:  print('message') => p.id).toList(),
    content = re.sub(r"print\('([^']*)'\)\s*=>", r"print('\1');\n      //", content)
    
    # Clean up any remaining broken syntax from the conversion
    lines = content.split('\n')
    fixed_lines = []
    skip_until_semicolon = False
    
    for i, line in enumerate(lines):
        if skip_until_semicolon:
            if ';' in line or '}' in line:
                skip_until_semicolon = False
            continue
            
        # If we find a line with just parameters after a print statement
        if re.match(r'^\s*(\'[^\']*\':\s*|name:\s*|error:\s*)', line):
            skip_until_semicolon = True
            continue
        
        fixed_lines.append(line)
    
    content = '\n'.join(fixed_lines)
    
    # Write the fixed content
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Fixed {filepath}")

fix_file('lib/features/posts/presentation/mobile/screens/details/post_detail_screen.dart')

