"""Install KARTA's Android bridge and definitive product branding."""
from pathlib import Path
import re
import shutil

root = Path(__file__).resolve().parents[1]
target = root / 'android/app/src/main/kotlin/com/karta/identity/karta_wallet/MainActivity.kt'
target.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(root / 'platform/android/MainActivity.kt', target)

manifest = root / 'android/app/src/main/AndroidManifest.xml'
text = manifest.read_text()
if 'android.permission.INTERNET' not in text:
    text = text.replace(
        '<application',
        '<uses-permission android:name="android.permission.INTERNET"/>\n    <application',
        1,
    )
if 'android.permission.USE_BIOMETRIC' not in text:
    text = text.replace(
        '<application',
        '<uses-permission android:name="android.permission.USE_BIOMETRIC"/>\n    <application',
        1,
    )
if '${applicationId}.karta.files' not in text:
    text = text.replace(
        '</application>',
        '''<provider android:name="androidx.core.content.FileProvider"
        android:authorities="${applicationId}.karta.files" android:exported="false" android:grantUriPermissions="true">
        <meta-data android:name="android.support.FILE_PROVIDER_PATHS" android:resource="@xml/karta_share_paths"/>
    </provider></application>''',
    )

# Device backups must not separate encrypted files from their Keystore keys.
text = (
    text.replace('<application', '<application android:allowBackup="false"', 1)
    if 'android:allowBackup=' not in text
    else re.sub(r'android:allowBackup="[^"]*"', 'android:allowBackup="false"', text)
)

# Product identity: stable public name plus vector KARTA mark.
text = re.sub(r'android:label="[^"]*"', 'android:label="KARTA"', text, count=1)
if 'android:icon=' in text:
    text = re.sub(
        r'android:icon="[^"]*"',
        'android:icon="@drawable/karta_launcher"',
        text,
        count=1,
    )
else:
    text = text.replace(
        '<application',
        '<application android:icon="@drawable/karta_launcher"',
        1,
    )
if 'android:roundIcon=' in text:
    text = re.sub(
        r'android:roundIcon="[^"]*"',
        'android:roundIcon="@drawable/karta_launcher"',
        text,
        count=1,
    )
else:
    text = text.replace(
        '<application',
        '<application android:roundIcon="@drawable/karta_launcher"',
        1,
    )
manifest.write_text(text)

paths = root / 'android/app/src/main/res/xml/karta_share_paths.xml'
paths.parent.mkdir(parents=True, exist_ok=True)
paths.write_text(
    '<paths xmlns:android="http://schemas.android.com/apk/res/android">'
    '<cache-path name="shared" path="karta-shares/"/>'
    '</paths>'
)

# Scalable KARTA launcher mark: cyan/mint vertical stem with blue diagonals.
drawable = root / 'android/app/src/main/res/drawable'
drawable.mkdir(parents=True, exist_ok=True)
(drawable / 'karta_launcher.xml').write_text(
    '''<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#04111F" android:pathData="M12,4 H96 Q104,4 104,12 V96 Q104,104 96,104 H12 Q4,104 4,96 V12 Q4,4 12,4 Z"/>
    <path android:fillColor="#58F3CF" android:pathData="M24,17 H40 V91 H24 Z"/>
    <path android:fillColor="#21DFF2" android:pathData="M37,56 L75,18 Q79,14 84,18 L92,25 Q95,28 91,32 L49,70 Z"/>
    <path android:fillColor="#087CFF" android:pathData="M43,51 L91,82 Q96,86 92,91 L85,97 Q81,100 76,96 L34,65 Z"/>
</vector>'''
)

# Branded Flutter/legacy splash screen.
(drawable / 'launch_background.xml').write_text(
    '''<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="#04111F"/>
    <item android:width="132dp" android:height="132dp" android:gravity="center" android:drawable="@drawable/karta_launcher"/>
</layer-list>'''
)

for styles in (root / 'android/app/src/main/res').glob('values*/styles.xml'):
    source = styles.read_text()
    source = re.sub(
        r'parent="@android:style/Theme\.(?:Light|Black)\.NoTitleBar"',
        'parent="Theme.AppCompat.DayNight.NoActionBar"',
        source,
    )
    source = re.sub(
        r'<item name="android:windowBackground">.*?</item>',
        '<item name="android:windowBackground">@drawable/launch_background</item>',
        source,
        count=1,
        flags=re.DOTALL,
    )
    styles.write_text(source)

build = root / 'android/app/build.gradle.kts'
build.write_text(
    build.read_text().replace(
        'minSdk = flutter.minSdkVersion',
        'minSdk = maxOf(24, flutter.minSdkVersion)',
    )
)
