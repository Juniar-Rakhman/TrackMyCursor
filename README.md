# Track My Cursor

A macOS cursor tracker/highlighter.

## Build

```sh
swift build --build-path bin
./build-app.sh
open TrackMyCursor.app
```

## Features

- Menu-bar (accessory) app with global cursor overlay
- Colored highlight ring with click states (left/right)
- Border-only mode (no glow/fill)
- Auto-hide border after idle time; reappears on mouse move
- Toggle enable/disable with hotkey (Cmd+Shift+K)
- Settings window (colors, size, behavior)
