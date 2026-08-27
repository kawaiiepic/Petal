<div align="center">

<img src="assets/images/logo.png" alt="Petal Logo" width="120" height="120" />

# 🌸 Petal

**A cross-platform anime streaming client built with Flutter**

[![Flutter](https://img.shields.io/badge/Flutter-3.27+-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-pink?style=flat-square)](LICENSE)
[![Build](https://img.shields.io/github/actions/workflow/status/kawaiiepic/Petal/flutter.yml?style=flat-square&label=build)](https://github.com/kawaiiepic/Petal/actions)
[![Release](https://img.shields.io/github/v/release/kawaiiepic/Petal?include_prereleases&style=flat-square&color=%23FFC0CB)](https://github.com/kawaiiepic/Petal/releases)

[**Download**](#-download) · [**Features**](#-features) · [**Screenshots**](#-screenshots) · [**Building**](#-building-from-source)

</div>

---

## ✨ Features

- 🎬 **Smooth video playback** via media_kit with hardware acceleration
- 🖼️ **Picture-in-picture** support on desktop and mobile
- 🔍 **Fuzzy search** — find titles even with typos
- 💾 **Session & cookie management** for seamless auth
- 🌐 **Cross-platform** — Linux, Windows, Android, and iOS from one codebase
- 🎨 **Clean UI** built with shadcn_flutter

---

## 📦 Download

Grab the latest build from [**Releases**](https://github.com/kawaiiepic/Petal/releases).

| Platform | Download |
|----------|----------|
| 🤖 Android | `app-release.apk` |
| 🍎 iOS | `bookadapt_unsigned.ipa` *(unsigned — sideload required)* |
| 🐧 Linux | `release-linux.zip` |
| 🪟 Windows | `release-windows.zip` |

> **Linux / Windows:** Extract the zip and run the executable from within the extracted folder — do not move the executable out on its own.

---

## 🖼️ Screenshots

*Coming soon*

---

## 🔨 Building from Source

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) 3.27+
- For Linux: `ninja-build`, `libgtk-3-dev`, `libmpv-dev`

### Steps

```bash
git clone https://github.com/kawaiiepic/Petal.git
cd Petal
flutter pub get
```

```bash
# Android
flutter build apk

# iOS (no codesign)
flutter build ios --release --no-codesign

# Linux
flutter build linux

# Windows
flutter build windows
```

> **Linux users:** After building, run the app from inside `build/linux/x64/release/bundle/` or set `LD_LIBRARY_PATH` to point at its `lib/` folder.

---

## 🤝 Contributing

PRs and issues are welcome! If something is broken or you want a feature, open an issue.

---

<div align="center">

Made with 🌸 and Flutter

</div>