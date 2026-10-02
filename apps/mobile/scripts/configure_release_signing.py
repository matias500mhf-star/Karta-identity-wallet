import os
from pathlib import Path

required_env = (
    'KARTA_KEYSTORE_PATH',
    'KARTA_KEY_ALIAS',
    'KARTA_KEYSTORE_PASSWORD',
    'KARTA_KEY_PASSWORD',
)
missing = [name for name in required_env if not os.environ.get(name)]
if missing:
    raise SystemExit(
        'Missing required release-signing environment variables: '
        + ', '.join(missing)
    )

keystore = Path(os.environ['KARTA_KEYSTORE_PATH']).expanduser().resolve()
if not keystore.is_file():
    raise SystemExit('KARTA_KEYSTORE_PATH does not point to an existing file.')

kts = Path('android/app/build.gradle.kts')
groovy = Path('android/app/build.gradle')

if kts.exists():
    path = kts
    text = path.read_text(encoding='utf-8')
    if 'create("release")' not in text:
        marker = '    buildTypes {'
        if marker not in text:
            raise SystemExit('Cannot find buildTypes block in build.gradle.kts')
        signing = '''    signingConfigs {\n        create("release") {\n            keyAlias = System.getenv("KARTA_KEY_ALIAS")\n            keyPassword = System.getenv("KARTA_KEY_PASSWORD")\n            storeFile = file(System.getenv("KARTA_KEYSTORE_PATH"))\n            storePassword = System.getenv("KARTA_KEYSTORE_PASSWORD")\n        }\n    }\n\n'''
        text = text.replace(marker, signing + marker, 1)
    debug_line = 'signingConfig = signingConfigs.getByName("debug")'
    if debug_line in text:
        text = text.replace(debug_line, 'signingConfig = signingConfigs.getByName("release")', 1)
    elif 'signingConfig = signingConfigs.getByName("release")' not in text:
        raise SystemExit('Cannot locate release signingConfig in build.gradle.kts')
    path.write_text(text, encoding='utf-8')
    print(f'Configured release signing in {path} using an external keystore path')
elif groovy.exists():
    path = groovy
    text = path.read_text(encoding='utf-8')
    if 'KARTA_KEY_ALIAS' not in text:
        marker = '    buildTypes {'
        if marker not in text:
            raise SystemExit('Cannot find buildTypes block in build.gradle')
        signing = '''    signingConfigs {\n        release {\n            keyAlias System.getenv('KARTA_KEY_ALIAS')\n            keyPassword System.getenv('KARTA_KEY_PASSWORD')\n            storeFile file(System.getenv('KARTA_KEYSTORE_PATH'))\n            storePassword System.getenv('KARTA_KEYSTORE_PASSWORD')\n        }\n    }\n\n'''
        text = text.replace(marker, signing + marker, 1)
    text = text.replace('signingConfig signingConfigs.debug', 'signingConfig signingConfigs.release', 1)
    if 'signingConfig signingConfigs.release' not in text:
        raise SystemExit('Cannot locate release signingConfig in build.gradle')
    path.write_text(text, encoding='utf-8')
    print(f'Configured release signing in {path}')
else:
    raise SystemExit('Android Gradle app file not found')
