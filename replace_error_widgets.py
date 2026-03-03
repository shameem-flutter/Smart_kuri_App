import os
import re

screens_dir = r'c:\Development\work\kuri\kuri_app\lib\screens'

import_statement = "\nimport 'package:kuri_app/widgets/custom_error_widget.dart';\n"

# Matches `final varName = ref.watch(providerName);`
watch_pattern = re.compile(r'(?:final|var)\s+(\w+)\s*=\s*ref\.watch\((.*?)\);', re.DOTALL)

for root, _, files in os.walk(screens_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            if '.when(' in content and 'error:' in content:
                # Find all watches to map var_name -> provider
                watch_map = {}
                for m in watch_pattern.finditer(content):
                    var_name = m.group(1)
                    provider = m.group(2)
                    watch_map[var_name] = provider
                
                # Now find `.when(` usages
                # Format: `varName.when(`
                when_pattern = re.compile(r'(\w+)\s*\.\s*when\s*\(')
                
                new_content = content
                modified = False
                
                # We will iteratively replace the error: blocks
                for when_match in when_pattern.finditer(content):
                    var_name = when_match.group(1)
                    if var_name in watch_map:
                        provider = watch_map[var_name]
                        
                        # Find the corresponding error block after this when_match
                        # Regex to find `error: (err, stack) => ... ,`
                        start_idx = when_match.end()
                        
                        # A loose regex to find `error: (e, s) => X,`
                        # We need to be careful with nested brackets.
                        # Instead of full AST parsing, let's use a non-greedy match that stops at the next comma at the same level, or just rely on a regex for standard single-line/short error widgets.
                        error_pattern = re.compile(r'error:\s*\([^,]+,\s*[^)]+\)\s*=>\s*(.*?)(?=,\s*(?:data:|loading:|\))|(?:\)\s*,))', re.DOTALL)
                        
                        # Only search in the substring after the .when(
                        search_area = new_content[start_idx:start_idx+1000] # 1000 chars should be enough for the when block
                        error_match = error_pattern.search(search_area)
                        
                        if error_match:
                            original_error_block = error_match.group(0)
                            # Extract the parameter names, e.g., (err, stack)
                            param_match = re.search(r'error:\s*\(([^,]+),\s*([^)]+)\)\s*=>', original_error_block)
                            err_var = 'error'
                            if param_match:
                                err_var = param_match.group(1).strip()
                            
                            replacement = f"error: ({err_var}, stack) => CustomErrorWidget(error: {err_var}.toString(), onRetry: () => ref.invalidate({provider}))"
                            
                            new_search_area = search_area.replace(original_error_block, replacement)
                            new_content = new_content[:start_idx] + new_search_area + new_content[start_idx+1000:]
                            modified = True
                
                if modified:
                    if 'custom_error_widget.dart' not in new_content:
                        # Add import after the last import
                        last_import = new_content.rfind("import '")
                        if last_import != -1:
                            end_of_import = new_content.find(';', last_import) + 1
                            new_content = new_content[:end_of_import] + import_statement + new_content[end_of_import:]
                    
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Updated {file}")

print("Done screens update.")
