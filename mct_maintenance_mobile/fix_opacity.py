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
                    new_content = re.sub(r'\.withOpacity\((.*?)\)', r'.withValues(alpha: \1)', content)
                    if new_content != content:
                        with open(path, 'w') as f:
                            f.write(new_content)
                        count += 1
    print(f"Fixed opacity in {count} files.")

if __name__ == "__main__":
    main()
