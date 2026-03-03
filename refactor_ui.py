import os
import re

dir_path = r'c:\Development\work\kuri\kuri_app\lib\screens'
import_stmt = "import 'package:kuri_app/widgets/custom_error_widget.dart';\n"

# Match exactly: error: (err, stack) => Center(...)
# We use non-greedy matching inside Center(...) to avoid matching across widgets.
pattern = re.compile(r'error:\s*\(([^,]+)[^)]*\)\s*=>\s*(?:Center|Scaffold|_ErrorView|_buildErrorState\(\))\([^;]*?(?=\s*,\s*(?:data:|loading:|\)|\n))', re.DOTALL)
count = 0

for root, dirs, files in os.walk(dir_path):
    for filename in files:
        if filename.endswith('.dart'):
            filepath = os.path.join(root, filename)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()

            if '.when(' in content and 'error:' in content:
                
                # find providers
                watch_matches = re.finditer(r'(?:final|var)\s+(\w+)\s*=\s*ref\.watch\((.*?)\);', content)
                watch_dict = {m.group(1): m.group(2) for m in watch_matches}

                when_provider = None
                for var, prov in watch_dict.items():
                    if var + '.when' in content:
                        when_provider = prov
                        break

                on_retry_action = '() {}'
                if when_provider:
                    on_retry_action = f'() => ref.invalidate({when_provider})'
                elif 'ref.refresh(' in content:
                    # just a fallback
                    on_retry_action = '() {}'
                
                # We do a simpler string-based replacement finding "error: (err, stack) => Center(child: Text('Error: $err'))," etc.
                # Since regex is hard here, we do:
                # Find all occurrences of "error: (err, stack) =>" that are inside `.when(`
                
                modified = False
                
                def repl(m):
                    err_var = m.group(1).strip()
                    # Just replace the whole matched Center(...) with CustomErrorWidget
                    return f'error: ({err_var}, stack) => CustomErrorWidget(error: {err_var}.toString(), onRetry: {on_retry_action})'
                
                new_content, num_subs = pattern.subn(repl, content)
                
                # Some files have `error: (error, stack) => _buildErrorState(),`
                # Our regex handles `_buildErrorState()` since we added it to the regex.
                
                if num_subs > 0:
                    if 'custom_error_widget.dart' not in new_content:
                        idx = new_content.rfind("import '")
                        if idx != -1:
                            endl = new_content.find(';', idx)
                            if endl != -1:
                                new_content = new_content[:endl+1] + '\n' + import_stmt + new_content[endl+1:]
                            else:
                                new_content = import_stmt + new_content
                        else:
                            new_content = import_stmt + new_content

                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f'Patched {filename}')
                    count += 1

print(f'{count} files patched.')
