# Kawa

Kawa is a macOS menu bar app for switching input sources with user-defined global keyboard shortcuts.

## Project source

Kawa is based on the original open-source project by [@hatashiro](https://github.com/hatashiro/kawa), a macOS input source switcher with user-defined shortcuts. This repository is a work in progress to rebuild the app for modern Apple silicon Macs while preserving its core input switching and shortcut behavior. Thank you to @hatashiro and the original Kawa contributors for their work.

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

## Install with Homebrew

```sh
brew tap alexson/kawa
brew install --cask kawa
```

## Build

Open `kawa.xcodeproj` in Xcode and build the `kawa` scheme. Swift Package Manager resolves the keyboard shortcut dependency automatically.

Kawa runs as a menu bar app. Click its menu bar icon to open settings.

## License

Kawa is released under the [MIT License](LICENSE).
