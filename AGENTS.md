# Agents

This document will outline the agents in the Petal project.

## Project Overview

Petal is a cross-platform anime streaming client built with Flutter, supporting Linux, Windows, Android, and iOS. It features:

- Smooth video playback via media_kit with hardware acceleration
- Picture-in-picture support
- Fuzzy search functionality
- Session & cookie management
- Clean UI built with shadcn_flutter

## Key Components

- **lib/**: Main application code
  - `main.dart`: Entry point, initializes the app and sets up navigation
  - `router/`: Navigation configuration using GoRouter
  - `pages/`: UI pages (e.g., dashboard, settings)
  - `widgets/`: Reusable UI components
  - `api/`: API clients and utilities for data fetching
  - `models/`: Data models for the application
  - `navigation/`: Navigation-related components

- **assets/**: Static assets like images

- **pubspec.yaml**: Dependencies and project configuration

## Building and Running

Prerequisites:
- Flutter 3.27+
- For Linux: ninja-build, libgtk-3-dev, libmpv-dev

Steps:
```bash
flutter pub get
flutter build linux  # or windows, android, ios
```

## Contributing

To add features or modify the project:
1. Identify the relevant component (page, widget, API)
2. Make changes in the appropriate file
3. Test locally
4. Submit a PR

For new features, consider:
- Adding new pages in `lib/pages/`
- Creating new widgets in `lib/widgets/`
- Extending API clients in `lib/api/`
- Updating navigation in `lib/router/`

## Key Libraries Used

- `media_kit`: Video playback
- `go_router`: Navigation
- `shadcn_flutter`: UI components
- `dio`: HTTP client
- `cookie_jar`: Session management
- `fuzzywuzzy`: Fuzzy search

## Development Tips

- Use `flutter run` to test changes locally
- For Linux builds: run from the bundle directory or set LD_LIBRARY_PATH
- Follow the existing code style and patterns
- Add documentation and comments for complex features

## Common Tasks

- Adding a new page: Create a new Dart file in `lib/pages/` and register it in the router
- Adding a new widget: Create a new Dart file in `lib/widgets/`
- Adding API endpoints: Extend the API classes in `lib/api/`
- Modifying UI: Edit the relevant widget or page files

This guide should help you quickly understand and modify the Petal project.