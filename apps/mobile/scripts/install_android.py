"""Install KARTA's native document bridge after flutter create."""
from pathlib import Path
import shutil
root = Path(__file__).resolve().parents[1]
target = root / 'android/app/src/main/kotlin/com/karta/identity/karta_wallet/MainActivity.kt'
target.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(root / 'platform/android/MainActivity.kt', target)

import re
manifest = root / 'android/app/src/main/AndroidManifest.xml'
text = manifest.read_text()
if 'android.permission.USE_BIOMETRIC' not in text:
    text = text.replace('<application', '<uses-permission android:name="android.permission.USE_BIOMETRIC"/>\n    <application', 1)
if '${applicationId}.karta.files' not in text:
    text = text.replace('</application>', '''<provider android:name="androidx.core.content.FileProvider"
        android:authorities="${applicationId}.karta.files" android:exported="false" android:grantUriPermissions="true">
        <meta-data android:name="android.support.FILE_PROVIDER_PATHS" android:resource="@xml/karta_share_paths"/>
    </provider></application>''')
# Device backups must not separate encrypted files from their Keystore keys.
text = text.replace('<application', '<application android:allowBackup="false"', 1) if 'android:allowBackup=' not in text else re.sub(r'android:allowBackup="[^"]*"', 'android:allowBackup="false"', text)
manifest.write_text(text)
paths = root / 'android/app/src/main/res/xml/karta_share_paths.xml'
paths.parent.mkdir(parents=True, exist_ok=True)
paths.write_text('<paths xmlns:android="http://schemas.android.com/apk/res/android"><cache-path name="shared" path="karta-shares/"/></paths>')
for styles in (root / 'android/app/src/main/res').glob('values*/styles.xml'):
    styles.write_text(re.sub(r'parent="@android:style/Theme\.(?:Light|Black)\.NoTitleBar"', 'parent="Theme.AppCompat.DayNight.NoActionBar"', styles.read_text()))
build = root / 'android/app/build.gradle.kts'
build.write_text(build.read_text().replace('minSdk = flutter.minSdkVersion', 'minSdk = maxOf(24, flutter.minSdkVersion)'))
