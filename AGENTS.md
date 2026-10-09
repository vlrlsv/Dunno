# AGENTS.md

This file provides guidance to coding agents working in this repository.

At the start of each session, read `.codex/local-notes.md` if it exists. Keep local reminders there, not in this file; the notes file is Git-ignored.

## Project Overview

Dunno is an iOS app (SwiftUI + SwiftData) that helps users avoid decision paralysis by randomly selecting a task for them. Users add up to 8 incomplete tasks, tap "Pick a Random Task," and the app locks them into one task until they complete or cancel it.

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

- `AppState` (`@Observable`) tracks `hasSeenTutorial` and `activeTaskId`. Both are written to `UserDefaults` on `didSet` so they survive app restarts. It also holds a transient `isRandomizing` flag that drives the randomizer cover — this one is deliberately *not* persisted.
- `TaskItem` is the sole SwiftData model. The `modelContainer` is attached at the app root and accessed via `@Environment(\.modelContext)` in views.

**Navigation is state-driven, not route-driven.** `RootContentView` is the single gatekeeper that reads `AppState` and `@Query` to decide which top-level view to show:
1. `WelcomeView` — first launch only (`!hasSeenTutorial`)
2. `ActiveTaskView` — when an `activeTaskId` is set and resolves to an unfinished task
3. `MainTabView` — default (Tasks list + Settings tabs)

`RootContentView` queries unfinished tasks and validates `activeTaskId` on appear, on query membership changes, and on active ID changes. `AppState` resolves only unfinished tasks and clears IDs for missing or completed tasks.

**Task limit:** The app enforces a hard cap of 8 incomplete tasks. `TaskListView` hides the add-task input when `tasks.count >= 8`, and `addTask()` guards against this too. The `@Query` in `TaskListView` filters to `!isCompleted` and sorts by `sortOrder` — completed tasks remain in the store but are never shown.

**Task list editing:** Rows keep titles in local drafts until submitted or focus is lost, then explicitly save through `TaskStore`. Clearing and committing a title deletes the task. Rows are reorderable via `onMove`, which renumbers and explicitly saves every task's `sortOrder`.

**Saving mutations:** Editing, completion, deletion, and reordering use `TaskStore` to save explicitly and restore only the affected fields or deleted tasks on failure. Views display save errors. Completion clears the active ID only after saving successfully.

**Adding tasks:** `TaskStore.insert` explicitly saves the shared context. On failure it removes only the new task, preserving other pending changes. The view retains the typed title and displays the save error. Do not use a context-wide rollback for a failed addition.

**Randomizer flow:** The randomizer is presented from `RootContentView` as a `.fullScreenCover` bound to `appState.isRandomizing`, so it sits above the `MainTabView`/`ActiveTaskView` swap and dismisses cleanly onto the picked `ActiveTaskView`. `RandomizerView` receives a snapshot of the incomplete tasks and animates a decelerating slot-machine wheel: it builds a 16-cycle reel, picks a random winner, and scrolls to it with a single `timingCurve` animation (~2.8s). On completion it holds ~1s, then calls `appState.setActiveTask(_:)` and clears `isRandomizing`. `TaskListView.pickRandomTask()` short-circuits the wheel when there is only one task — it calls `setActiveTask(_:)` directly, and the button reads "Start Task" instead of "Pick a Random Task."

## Key Conventions

- Views inject `AppState` via `@Environment(AppState.self)` — it must be passed with `.environment(appState)` from the root.
- The app creates one `ModelContainer` for `TaskItem` and attaches it at the `WindowGroup` level; views must use that container.
- Unit tests use Swift Testing (`@Test`, `#expect`); UI tests use XCTest.
