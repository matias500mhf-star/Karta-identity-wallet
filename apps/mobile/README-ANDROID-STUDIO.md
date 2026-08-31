# KARTA — Android Studio Quick Start

## Requirements

- Flutter SDK installed and available as `flutter` in PATH.
- Android Studio with the Flutter and Dart plugins.
- Android SDK and an Android emulator or physical Android device.

Flutter's official Android Studio workflow supports opening an existing Flutter project directly and running it from the IDE.

## Open the correct folder

Open **this directory** in Android Studio:

`apps/mobile`

Do **not** open only `apps/mobile/android` unless you specifically need to edit native Android/Gradle code.

## First run

From the `apps/mobile` directory:

```bash
flutter pub get
flutter devices
flutter run
```

On Windows, double-click:

`run-karta.bat`

That launcher runs dependency installation, lists available devices, and starts Flutter.

## Android emulator

Create/start an emulator in Android Studio Device Manager. Then run `flutter devices` and confirm it appears.

## API connection

The mobile app uses the API service configuration already present in the project. For an Android emulator, the backend host is normally reached through `10.0.2.2` rather than `localhost`.

The API itself must be running for login, identity, and document operations to work.

## Recommended development order

1. Start PostgreSQL.
2. Start the KARTA API.
3. Start an Android emulator.
4. Open `apps/mobile` in Android Studio.
5. Run the `KARTA (Debug)` configuration or execute `run-karta.bat`.

## One-command target

For Windows development:

```text
run-karta.bat
```

The long-term goal is to make the complete local stack startable from the repository root with one command (database + API + Flutter). This file currently launches the Flutter client and validates the Flutter environment.
