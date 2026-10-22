# AGENTS.md

This file provides guidance to coding agents working in this repository.

At the start of each session, read `.codex/local-notes.md` if it exists. Keep local reminders there, not in this file; the notes file is Git-ignored.

## Project Overview

Dunno is an iOS app (SwiftUI + SwiftData) that helps users avoid decision paralysis by randomly selecting a task for them. Users add up to 8 incomplete tasks, tap "Pick for me," and the app locks them into one task until they complete or cancel it.

The current minimum supported version is iOS 26.4. Keep app and test deployment targets aligned.

## Build & Test

All building and testing is done through Xcode or `xcodebuild`:

```bash
# Build
xcodebuild -scheme Dunno -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' build

# Run unit tests (Swift Testing framework)
xcodebuild test -scheme Dunno -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' -only-testing:DunnoTests

# Run UI tests
xcodebuild test -scheme Dunno -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' -only-testing:DunnoUITests
```

Use an installed simulator runtime. If `xcode-select` points to CommandLineTools, prefix commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

Unit tests inject isolated `UserDefaults` suites and use an in-memory SwiftData store. UI tests set `DUNNO_UI_TEST_ID` to a fresh UUID per test; Debug builds use that ID for separate defaults and a separate disk store, preserving state across relaunches within the test. Release builds ignore this environment variable.

## Architecture

**State management:** Two layers — `AppState` (transient UI state, persisted to `UserDefaults`) and SwiftData (task persistence via `@Model`).

- `AppState` (`@Observable`) tracks `hasSeenTutorial`, `activeTaskId`, and `activeTaskStartDate` (drives the elapsed timer on `ActiveTaskView`; set by `setActiveTask(_:)`, cleared by `clearActiveTask()`). All are written to `UserDefaults` on `didSet` so they survive app restarts. It also holds a transient `isRandomizing` flag that drives the randomizer cover — this one is deliberately *not* persisted.
- `TaskItem` is the sole SwiftData model. It is a typealias for `SchemaV1.TaskItem`; models live inside `VersionedSchema` enums, and `DunnoMigrationPlan` lists every version. To change the model, add a `SchemaV2` with its own copy of the class, repoint the typealias, and add a migration stage. Never edit `SchemaV1`'s fields: existing stores must keep matching it.
- `PersistentStore` opens the container without crashing. On failure, `DunnoApp` shows `StoreErrorView` with Retry (temporary problems such as a full disk) and Reset (moves the store files aside as `*.corrupt-<timestamp>`, never deletes them, and opens an empty store). Views access the container via `@Environment(\.modelContext)`.

**Navigation is state-driven, not route-driven.** `RootContentView` is the single gatekeeper that reads `AppState` and `@Query` to decide which top-level view to show:
1. `WelcomeView` — first launch only (`!hasSeenTutorial`)
2. `ActiveTaskView` — when an `activeTaskId` is set and resolves to an unfinished task
3. `MainTabView` — default (Tasks list + Settings tabs)

`RootContentView` queries unfinished tasks and validates `activeTaskId` on appear, on query membership changes, and on active ID changes. `AppState` resolves only unfinished tasks and clears IDs for missing or completed tasks.

**Task limit:** The app enforces a hard cap of 8 incomplete tasks. `TaskListView` hides the add-task input when `tasks.count >= 8`, and `addTask()` guards against this too. The `@Query` in `TaskListView` filters to `!isCompleted` and sorts by `sortOrder` — completed tasks remain in the store but are never shown.

**Task list editing:** Rows keep titles in local drafts until submitted or focus is lost, then explicitly save through `TaskStore`. Clearing and committing a title deletes the task. Rows are reorderable via `onMove`, which renumbers and explicitly saves every task's `sortOrder`.

**Saving mutations:** Editing, completion, deletion, and reordering use `TaskStore` to save explicitly and restore only the affected fields or deleted tasks on failure. Views display save errors. Completion clears the active ID only after saving successfully.

**Adding tasks:** `TaskStore.insert` explicitly saves the shared context. On failure it removes only the new task, preserving other pending changes. The view retains the typed title and displays the save error. Do not use a context-wide rollback for a failed addition.

**Randomizer flow:** The randomizer is presented from `RootContentView` as a `.fullScreenCover` bound to `appState.isRandomizing`, so it sits above the `MainTabView`/`ActiveTaskView` swap and dismisses cleanly onto the picked `ActiveTaskView`. `RandomizerView` receives a snapshot of the incomplete tasks and animates a decelerating slot-machine wheel: it builds a 16-cycle reel, picks a random winner, and scrolls to it with a single `timingCurve` animation (~2.8s). On completion it holds ~1s, then calls `appState.setActiveTask(_:)` and clears `isRandomizing`. `TaskListView.pickRandomTask()` short-circuits the wheel when there is only one task — it calls `setActiveTask(_:)` directly, and the button reads "Start task" instead of "Pick for me."

## Design System

Defined in `Dunno/Views/Theme.swift`, with colors as light/dark color sets in `Assets.xcassets`. The app follows the system light/dark setting.

- **60/30/10 palette:** `Color.dunnoBase` (60% — screen backgrounds), `Color.dunnoSurface` (30% — cards, rows, fields), `Color.dunnoAccent` (10% — primary actions, highlights). `dunnoAccent` is the `AccentColor` asset: black in light mode, warm white in dark mode (black would vanish on the dark base). Put text/icons on the accent with `Color.dunnoOnAccent`.
- **Mascot:** the brand mascot is black in both modes and always sits on the light `dunnoMascotStage` disc via `MascotView`. It renders the `Mascot` image asset when present, otherwise a drawn placeholder.
- **Components:** one `PrimaryButtonStyle` (accent capsule) per screen; `SecondaryButtonStyle` for the alternative choice. Headlines and task titles use `Font.dunnoDisplay(_:)` (SF Rounded, bold). Lists hide their default background (`.scrollContentBackground(.hidden)`) and use `dunnoSurface` row backgrounds.

## Key Conventions

- Views inject `AppState` via `@Environment(AppState.self)` — it must be passed with `.environment(appState)` from the root.
- The app creates one `ModelContainer` through `PersistentStore` and attaches it to `RootContentView`; views must use that container.
- Unit tests use Swift Testing (`@Test`, `#expect`); UI tests use XCTest.
