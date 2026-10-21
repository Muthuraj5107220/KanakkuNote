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
when `main` is updated, including after a pull request is merged. After a
successful build, CI updates
[`android-release/app-release.apk`](android-release/app-release.apk) on `main`
and attaches it to a testing prerelease in the
[GitHub Releases](https://github.com/Muthuraj5107220/KanakkuNote/releases) page.
It also publishes the APK as a workflow artifact. APK-only commits do not
trigger another build. Each changed APK is stored in Git history, so the
repository will grow over time.
