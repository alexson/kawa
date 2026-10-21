# Kawa

Kawa is a macOS menu bar app for switching input sources with user-defined global keyboard shortcuts.

## Project source

This project is based on [alexson/kawa](https://github.com/alexson/kawa), an open-source macOS input source switcher. This repository is a work in progress to rebuild the app for modern Apple silicon Macs while preserving its core input switching and shortcut behavior.

## Purpose

The goal is to provide Kawa's existing input source switching features in a macOS-native app that is maintained for Apple silicon and macOS 26 and later.

## Improvements in this project

- Rebuilt the app interface with SwiftUI and native macOS settings.
- Updated the project for Apple silicon and macOS 26 or later.
- Retained per-input-source global keyboard shortcuts.
- Added menu bar display choices: text, icon, or text and icon.
- Added options to hide the Dock icon when windows are closed and launch Kawa at login.
- Added an option to show a notification when the input source changes.

## Requirements

- macOS 26.0 or later
- Apple silicon
- Xcode 27 or later

## Build

Open `kawa.xcodeproj` in Xcode and build the `kawa` scheme. Swift Package Manager resolves the keyboard shortcut dependency automatically.

Kawa runs as a menu bar app. Click its menu bar icon to open settings.

## License

Kawa is released under the [MIT License](LICENSE).
