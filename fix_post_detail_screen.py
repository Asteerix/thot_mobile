#!/usr/bin/env python3
import re

def fix_print_calls(content):
    """Fix malformed print() calls that have named parameters"""
    
    # Pattern 1: print('message', name: 'Name', error: {...})
    # Should become: print('message')
    
    lines = content.split('\n')
    result = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # Check if this line has a print( call with a comma followed by name: or error:
        if 'print(' in line and ('name:' in line or 'error:' in line or (i + 1 < len(lines) and ('error:' in lines[i + 1] or 'name:' in lines[i + 1]))):
            # Start collecting the multiline print statement
            statement = line
            j = i + 1
            open_parens = line.count('(') - line.count(')')
            
            # Continue collecting lines until we balance parentheses
            while j < len(lines) and open_parens > 0:
                statement += '\n' + lines[j]
                open_parens += lines[j].count('(') - lines[j].count(')')
                j += 1
            
            # Now fix the statement
            # Extract just the first message parameter
            match = re.search(r"print\('([^']+)'", statement)
            if match:
                message = match.group(1)
                # Recreate simple print
                indent = len(line) - len(line.lstrip())
                result.append(' ' * indent + f"print('{message}');")
                i = j
                continue
        
        result.append(line)
        i += 1
    
    return '\n'.join(result)

# Read the file
with open('lib/features/posts/presentation/mobile/screens/details/post_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the content
fixed_content = fix_print_calls(content)

# Write back
with open('lib/features/posts/presentation/mobile/screens/details/post_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(fixed_content)

print("Fixed post_detail_screen.dart")

