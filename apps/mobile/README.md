# KARTA Mobile

Flutter mobile client for KARTA.

Alpha 0.1 target flow:

Register → Login → Secure wallet → Identity profile → Documents

No real identity documents should be used during development.


Android build with PDF viewing and export:

```sh
flutter create --platforms=android --android-language=kotlin --project-name=karta_wallet --org=com.karta.identity --no-pub .
python3 scripts/install_android.py
flutter pub get
flutter test
flutter build apk --debug
```

PDF viewing uses Android PdfRenderer and a temporary private file unlinked once opened. Export uses the Android document destination picker only after confirmation. Existing encrypted files and keys are retained. Password-protected PDFs show an error; this version does not support PDF passwords.
