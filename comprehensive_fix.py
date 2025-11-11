#!/usr/bin/env python3
import re

def comprehensive_fix(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Fix 1: Remove any duplicate SafeNavigation or HapticFeedback classes
    # These are imported and shouldn't be redefined
    content = re.sub(r'class SafeNavigation\s*\{[^}]*\}', '', content, flags=re.DOTALL)
    content = re.sub(r'class HapticFeedback\s*\{[^}]*\}', '', content, flags=re.DOTALL)
    
    # Fix 2: Remove any function declarations at top level that look like they're trying to redefine standard functions
    content = re.sub(r'^(Future<void>|void|Widget|dynamic)\s+(showModalBottomSheet|print|setState)\s*\([^{]*\)\s*\{[^}]*\}$', '', content, flags=re.MULTILINE)
    
    # Fix 3: Ensure all try blocks have catch blocks
    # Find try blocks without catch
    lines = content.split('\n')
    fixed_lines = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # If this is a try block
        if re.match(r'^\s*try\s*\{', line):
            # Collect the try block
            try_start = i
            brace_count = line.count('{') - line.count('}')
            j = i + 1
            
            while j < len(lines) and brace_count > 0:
                brace_count += lines[j].count('{') - lines[j].count('}')
                j += 1
            
            # Now check if the next non-empty line is a catch/finally
            k = j
            while k < len(lines) and lines[k].strip() == '':
                k += 1
            
            if k < len(lines) and not re.match(r'^\s*(catch|on|finally)', lines[k]):
                # No catch block found, we need to add one
                # Add the try block lines
                for idx in range(i, j):
                    fixed_lines.append(lines[idx])
                
                # Add a catch block
                indent = len(lines[i]) - len(lines[i].lstrip())
                fixed_lines.append(' ' * indent + '} catch (e) {')
                fixed_lines.append(' ' * (indent + 2) + '// Error caught')
                
                i = j
                continue
        
        fixed_lines.append(line)
        i += 1
    
    content = '\n'.join(fixed_lines)
    
    # Write back if changed
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {filepath}")
        return True
    else:
        print(f"No changes needed for {filepath}")
        return False

comprehensive_fix('lib/features/posts/presentation/mobile/screens/details/post_detail_screen.dart')

