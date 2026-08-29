# DeskEyeRest

DeskEyeRest is a local-first macOS menu-bar app for structured screen breaks and focus routines. It is built with SwiftUI for macOS 14 and later.

## Features

- Configurable short and long break cycles.
- Full-screen break, clock-out, and flash reminders.
- Working-hours schedules, notifications, launch-at-login support, and global hotkeys.
- Local break history and editable exercise prompts.
- Optional pause signals based on idle time, active audio input, and macOS Focus status when authorization is already available.

## Privacy

DeskEyeRest keeps settings in UserDefaults and stores break history and custom exercises under the current user's Application Support directory. The app source contains no network client or telemetry.

Meeting detection checks whether an audio-input device is in use; it does not capture or record audio. Focus detection reads only the current Focus-state boolean when macOS has already authorized access.

## Current limitation

The video-detection setting is reserved for future work. The current implementation intentionally reports no active video, so it does not pause the timer.

## Requirements

- macOS 14 or later.
- Xcode with Command Line Tools.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen).

## Build from source

From the repository root:

```sh
xcodegen generate
open DeskEyeRest.xcodeproj
```

In Xcode, select the `DeskEyeRest` scheme and the `My Mac` destination, then run the app. The generated `.xcodeproj` is intentionally ignored because `project.yml` is the source of truth.

## Project layout

```text
DeskEyeRest/
├── DeskEyeRest/          App target: state, timers, detectors, persistence, UI, and resources
├── DeskEyeRestTests/     Unit tests
├── project.yml           XcodeGen project configuration
├── build.sh              Optional local command-line build helper
└── THIRD_PARTY_NOTICES.md
```

## Development notes

- Edit source files under `DeskEyeRest/`, then rerun `xcodegen generate` if the project structure changes.
- Run tests with `xcodebuild test -scheme DeskEyeRest` after generating the Xcode project.
- See `THIRD_PARTY_NOTICES.md` for bundled-font notices.
