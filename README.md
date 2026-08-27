# Hey Nigel

A voice-driven golf caddy app for iPhone. Say "Hey Siri, ask Nigel my distance" or press
the AirPods stem, and Nigel tells you your distance to the green and recommends a club,
accounting for wind.

## Prerequisites

- **Xcode 16 or newer**, installed from the Mac App Store (full Xcode, not just the
  Command Line Tools — the app needs the iOS SDK and Simulator).
- **[Homebrew](https://brew.sh)**, if you don't already have it.
- **XcodeGen**: `brew install xcodegen`

## First-time setup

```bash
git clone https://github.com/jorge-v-castillo/hey-nigel.git
cd hey-nigel
xcodegen generate
open HeyNigel.xcodeproj
```

Then in Xcode: pick the **HeyNigel** scheme, pick any iPhone Simulator as the run
destination, and press **Cmd+R**. No Apple ID or code signing is needed to build and run
in the Simulator.

### Why "Unable to resolve module dependency" happens

**This repo does not commit a `.xcodeproj`.** It's generated from [`project.yml`](project.yml)
by XcodeGen so it never drifts out of sync with the actual source layout — `.gitignore`
deliberately excludes it. If you open the repo folder directly in Xcode, or open one of the
`Package.swift` files inside `Packages/`, Xcode has no project wiring the app target to the
three local Swift packages (`HeyNigelCore`, `HeyNigelCourseData`, `HeyNigelWeather`), and
you'll see a cascade of red "Unable to resolve module dependency" errors — one per file that
imports one of those packages, plus one on `Package.swift` itself.

The fix is always the same: run `xcodegen generate` from the repo root, then open the
`HeyNigel.xcodeproj` it produces — **never** open a `Package.swift` or the bare folder.
Re-run `xcodegen generate` any time `project.yml` changes (pull latest, then regenerate).
There is nothing to configure by hand in Xcode's Package Dependencies panel — XcodeGen
does that from `project.yml`.

## Project structure

```
HeyNigel/                    # app target — SwiftUI, App Intents, voice, location
Packages/
  HeyNigelCore/               # pure Swift domain logic — club recommendation engine,
                               # GPS hole detection, voice-query parsing. No Apple
                               # framework imports beyond Foundation; unit tested on its own.
  HeyNigelCourseData/          # CourseDataProvider abstraction + bundled mock fixture courses
  HeyNigelWeather/             # WeatherProvider abstraction (currently mocked — see below)
HeyNigelUITests/              # UI test that walks the full onboarding + round-setup flow,
                               # used to generate screenshots in CI
.github/workflows/ci.yml      # runs package tests, builds the app, and runs the UI
                               # walkthrough on every push
```

## Running tests

Each package can be tested on its own, without opening Xcode at all:

```bash
cd Packages/HeyNigelCore && swift test
cd Packages/HeyNigelCourseData && swift test
cd Packages/HeyNigelWeather && swift test
```

The full UI walkthrough runs in Xcode via the `HeyNigelUITests` target (Cmd+U), or
automatically in CI on every push to `main`.

## Known limitations right now

- **Course data** is two small mock fixture courses (Scottsdale, AZ area) — no real
  course-data vendor is wired in yet. Swapping one in later only means adding a new
  `CourseDataProvider` implementation; nothing else changes.
- **Wind data** is mocked (always calm) — real wind needs Apple's WeatherKit, which
  requires a paid Apple Developer Program membership to enable.
- **Siri / App Intents integration** and **on-device AirPods testing** also need that
  same paid developer account, plus a real iPhone and AirPods — neither works in the
  Simulator.
