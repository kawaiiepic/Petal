<div align="center">

<img src="assets/images/logo.png" alt="Petal Logo" width="120" height="120" />

# 🌸 Petal

**A cross-platform anime streaming client built with Flutter**

[![Flutter](https://img.shields.io/badge/Flutter-3.27+-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-pink?style=flat-square)](LICENSE)
[![Build](https://img.shields.io/github/actions/workflow/status/kawaiiepic/Petal/flutter.yml?style=flat-square&label=build)](https://github.com/kawaiiepic/Petal/actions)
[![Release](https://img.shields.io/github/v/release/kawaiiepic/Petal?include_prereleases&style=flat-square&color=%23FFC0CB)](https://github.com/kawaiiepic/Petal/releases)

[**Discord**](https://discord.gg/D6a4p2G7Yn) · [**Join iOS TestFlight**](https://testflight.apple.com/join/fPpArZG7) · [**Download**](#-download) · [**Features**](#-features) · [**Screenshots**](#-screenshots) · [**Building**](#-building-from-source)

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

Grab the latest desktop and Android builds from [**Releases**](https://github.com/kawaiiepic/Petal/releases).

[![Join TestFlight](https://img.shields.io/badge/iOS-Join%20TestFlight-007AFF?style=for-the-badge&logo=apple&logoColor=white)](https://testflight.apple.com/join/fPpArZG7)

Install Apple's [TestFlight app](https://apps.apple.com/app/testflight/id899247664), then open the invitation link to join the Petal beta. Availability depends on beta approval and tester capacity.

| Platform | Download |
|----------|----------|
| 🤖 Android | `app-release.apk` |
| 🍎 iOS | [Join the TestFlight beta](https://testflight.apple.com/join/fPpArZG7) |
| 🐧 Linux | `release-linux.zip` |
| 🪟 Windows | `release-windows.zip` |

> **Linux / Windows:** Extract the zip and run the executable from within the extracted folder — do not move the executable out on its own.

---

## 🖼️ Screenshots

### Desktop

<div align="center">

<img src="assets/screenshots/desktop-home.webp" alt="Petal desktop home with featured titles, sidebar and On Deck shelf" width="100%" />

</div>

| Show overview | Video player |
|:---:|:---:|
| <img src="assets/screenshots/show-overview.webp" alt="TV show details, episode dates and trailers" width="440" /> | <img src="assets/screenshots/video-player.webp" alt="Full-screen video player with Liquid Glass controls" width="440" /> |
| **Collection** | **Search** |
| <img src="assets/screenshots/collection.webp" alt="Collection with watchlist, liked titles and watch progress" width="440" /> | <img src="assets/screenshots/search.webp" alt="Search results and category filters" width="440" /> |
| **Actor overview** | **User profile** |
| <img src="assets/screenshots/actor.webp" alt="Actor biography and filmography" width="440" /> | <img src="assets/screenshots/profile.webp" alt="User profile and watch history" width="440" /> |

### Compact layout

<div align="center">

<img src="assets/screenshots/compact-home.webp" alt="Petal compact home layout with bottom navigation" width="320" />

</div>

<details>
<summary>Source selection preview</summary>

<img src="assets/screenshots/source-picker.webp" alt="Petal source selection sheet" width="900" />

</details>

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

See [Code structure](docs/code_structure.md) for the source layout and verification commands.

## 💬 Community

[![Join Discord](https://img.shields.io/badge/Discord-Join%20the%20community-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/D6a4p2G7Yn)

Join the Petal Discord to share feedback, report bugs, get help, and discuss new features.

---

## 🤝 Contributing

PRs and issues are welcome! If something is broken or you want a feature, open an issue.

---

<div align="center">

Made with 🌸 and Flutter

</div>