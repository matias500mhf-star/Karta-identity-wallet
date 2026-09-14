"""Install KARTA's native document bridge after flutter create."""
from pathlib import Path
import shutil
root = Path(__file__).resolve().parents[1]
target = root / 'android/app/src/main/kotlin/com/karta/identity/karta_wallet/MainActivity.kt'
target.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(root / 'platform/android/MainActivity.kt', target)
