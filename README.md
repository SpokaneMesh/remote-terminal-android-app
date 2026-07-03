# MeshTerm — Android App

A native Android client for [Remote Terminal for MeshCore](https://github.com/jkingsman/Remote-Terminal-for-MeshCore) by [@jkingsman](https://github.com/jkingsman).

## What it does

RemoteTerm exposes a web UI for managing MeshCore mesh radio networks. This app wraps that UI in a native Android shell that:

- Stores your server credentials securely in the Android keychain
- Injects HTTP Basic Auth automatically — no browser popup on every launch
- Shows a slim persistent toolbar so the settings gear never overlaps web UI controls
- Handles connection errors with a retry/settings fallback screen

## Requirements

- A running [RemoteTerm](https://github.com/jkingsman/Remote-Terminal-for-MeshCore) instance accessible from your device (e.g. via VPN)
- Android 5.0+

## Building

```bash
flutter pub get
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

## First launch

Enter your RemoteTerm server URL (e.g. `https://your-server/`), username, and password. Credentials are saved to the device keychain and used automatically on every subsequent launch.

## Related

- [Remote Terminal for MeshCore](https://github.com/jkingsman/Remote-Terminal-for-MeshCore) — the server this app connects to
- [MeshCore](https://github.com/ripplebiz/MeshCore) — the mesh radio firmware
