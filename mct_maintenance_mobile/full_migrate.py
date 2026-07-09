import os
import shutil
import re

def move_files():
    mapping = {
        'lib/screens/auth/': 'lib/features/auth/presentation/screens/',
        'lib/screens/customer/': 'lib/features/customer/presentation/screens/',
        'lib/screens/technician/': 'lib/features/technician/presentation/screens/',
        'lib/screens/manager/': 'lib/features/manager/presentation/screens/',
        'lib/screens/admin/': 'lib/features/admin/presentation/screens/',
        'lib/screens/onboarding/': 'lib/features/onboarding/presentation/screens/',
        'lib/screens/common/': 'lib/features/common/presentation/screens/',
    }
    
    for src, dest in mapping.items():
        if os.path.exists(src):
            os.makedirs(dest, exist_ok=True)
            for item in os.listdir(src):
                s = os.path.join(src, item)
                d = os.path.join(dest, item)
                if os.path.isdir(s):
                    shutil.copytree(s, d, dirs_exist_ok=True)
                else:
                    shutil.copy2(s, d)
    
    # Remove old dirs
    for src in mapping.keys():
        if os.path.exists(src):
            shutil.rmtree(src)

def update_imports():
    package_map = {
        'package:mct_maintenance_mobile/screens/auth/': 'package:mct_maintenance_mobile/features/auth/presentation/screens/',
        'package:mct_maintenance_mobile/screens/customer/': 'package:mct_maintenance_mobile/features/customer/presentation/screens/',
        'package:mct_maintenance_mobile/screens/technician/': 'package:mct_maintenance_mobile/features/technician/presentation/screens/',
        'package:mct_maintenance_mobile/screens/manager/': 'package:mct_maintenance_mobile/features/manager/presentation/screens/',
        'package:mct_maintenance_mobile/screens/admin/': 'package:mct_maintenance_mobile/features/admin/presentation/screens/',
        'package:mct_maintenance_mobile/screens/onboarding/': 'package:mct_maintenance_mobile/features/onboarding/presentation/screens/',
        'package:mct_maintenance_mobile/screens/common/': 'package:mct_maintenance_mobile/features/common/presentation/screens/',
    }
    
    for folder in ['lib', 'test', 'integration_test']:
        for root, dirs, files in os.walk(folder):
            for file in files:
                if file.endswith('.dart'):
                    path = os.path.join(root, file)
                    with open(path, 'r') as f:
                        content = f.read()
                    
                    new_content = content
                    
                    # Convert relative imports to package imports first (SAFE VERSION)
                    def rel_to_pkg(match):
                        prefix = match.group(1)
                        quote = match.group(2)
                        rel_path = match.group(3)
                        if rel_path.startswith('package:') or rel_path.startswith('dart:') or not rel_path.startswith('.'):
                            return match.group(0)
                        dir_path = os.path.dirname(path)
                        target_path = os.path.normpath(os.path.join(dir_path, rel_path))
                        if target_path.startswith('lib/'):
                            pkg_path = 'package:mct_maintenance_mobile/' + target_path[4:]
                            return f"{prefix} {quote}{pkg_path}{quote}"
                        return match.group(0)

                    new_content = re.sub(r'(import|export)\s+([\'"])(.*?)\2', rel_to_pkg, new_content)

                    # Then apply package mapping
                    for old, new in package_map.items():
                        new_content = new_content.replace(old, new)
                    
                    # Fix specific legacy imports
                    new_content = new_content.replace("import 'auth/email_verification_screen.dart';", "import 'package:mct_maintenance_mobile/features/auth/presentation/screens/email_verification_screen.dart';")
                    new_content = new_content.replace("import 'admin/suggest_technicians_screen.dart';", "import 'package:mct_maintenance_mobile/features/admin/presentation/screens/suggest_technicians_screen.dart';")

                    if new_content != content:
                        with open(path, 'w') as f:
                            f.write(new_content)

def fix_code_bugs():
    # Fix test/widget_test.dart
    path = 'test/widget_test.dart'
    if os.path.exists(path):
        with open(path, 'r') as f:
            content = f.read()
        content = content.replace('const MyApp()', 'const App()')
        content = content.replace("import 'package:mct_maintenance_mobile/main.dart';", "import 'package:mct_maintenance_mobile/core/app.dart';")
        with open(path, 'w') as f:
            f.write(content)

    # Fix suggest_technicians_screen corruption in test_suggestions_screen.dart
    path = 'lib/features/admin/presentation/screens/test_suggestions_screen.dart'
    if os.path.exists(path):
        with open(path, 'r') as f:
            content = f.read()
        content = content.replace("import '../admin/suggest_technicians_screen.dart';", "") # It's now in the same folder or absolute
        content = "import 'suggest_technicians_screen.dart';\n" + content
        content = re.sub(r'Widget _loadScreen\(\) \{.*?import.*?return SuggestTechniciansScreen', 'Widget _loadScreen() {\n    return SuggestTechniciansScreen', content, flags=re.DOTALL)
        with open(path, 'w') as f:
            f.write(content)

if __name__ == "__main__":
    move_files()
    update_imports()
    fix_code_bugs()
    print("Comprehensive migration completed.")
