# Getting Started

This project is a Flutter app equipped with PowerSync for efficient data synchronization, specifically built to perform load tests. It allows you to measure how long the initial sync takes with a hosted backend.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed
- A PowerSync hosted backend set up (refer to [PowerSync documentation](https://docs.powersync.com/) for setup instructions)
- Dart dependencies installed (run `flutter pub get`)

## Running the App

1. Install dependencies:

```bash
flutter pub get
```

## 2. Configure PowerSync

- Copy the template config file and rename it:

```bash
  cp lib/app_config_template.dart lib/app_config.dart
```

- Open `lib/app_config.dart` and insert your `powerSyncUrl` and `backendUrl`.

## 3. Run the app

```bash
flutter run
```
