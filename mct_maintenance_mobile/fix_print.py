import os
import re

def main():
    count = 0
    for folder in ['lib', 'test', 'integration_test']:
        for root, dirs, files in os.walk(folder):
            for file in files:
                if file.endswith('.dart'):
                    path = os.path.join(root, file)
                    with open(path, 'r') as f:
                        content = f.read()
                    
                    new_content = re.sub(r'(?<!//)(?<!/\*)\bprint\(', r'debugPrint(', content)
                    
                    if new_content != content:
                        if 'package:flutter/foundation.dart' not in new_content and 'package:flutter/material.dart' not in new_content:
                            new_content = "import 'package:flutter/foundation.dart';\n" + new_content
                        # Fix potential foundation.dart partial imports
                        new_content = new_content.replace("import 'package:flutter/foundation.dart' show kIsWeb;", "import 'package:flutter/foundation.dart';")
                        
                        with open(path, 'w') as f:
                            f.write(new_content)
                        count += 1
    print(f"Fixed print in {count} files.")

if __name__ == "__main__":
    main()
