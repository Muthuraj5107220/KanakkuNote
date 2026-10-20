# Kanakku Note

A simple, local-first daily expense manager built with Flutter.

## Features

- Add, edit, and delete expenses with a category, optional note, amount, and date.
- Browse daily totals and a weekly spending overview.
- See your monthly total and daily expense list.
- Keep entries on your device using the open-source `shared_preferences` package.
- Format dates and Indian rupee amounts with the open-source `intl` package.

No account or network connection is required. Expenses are stored locally on the device.

## Run

```sh
flutter pub get
flutter run
```

## Test

```sh
flutter test
```

## Android CI

GitHub Actions runs `flutter analyze`, `flutter test`, and a release APK build
when `main` is updated, including after a pull request is merged. The generated
APK is available as a workflow artifact.
