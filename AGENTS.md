# TrackMyCursor

MacOS cursor highlighter.

## Build

- `swift build --build-path bin` — debug build
- `./build-app.sh` — release .app bundle
- `open TrackMyCursor.app` — run

## Structure

- `Sources/TrackMyCursor/` — Swift sources
- `Package.swift` — SPM manifest (macOS 13+)
- `build-app.sh` — assembles `FindMyCursor.app` bundle with Info.plist

## Conventions

- Swift 5.9+, MacOS 13 minimum.
- Menu-bar accessory app (`LSUIElement`); no dock icon.
- Keep changes minimal and buildable; run `swift build` before finishing.
