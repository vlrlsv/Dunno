# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Dunno is an iOS app (SwiftUI + SwiftData) that helps users avoid decision paralysis by randomly selecting a task for them. Users add up to 8 incomplete tasks, tap "Pick a Random Task," and the app locks them into one task until they complete or cancel it.

## Build & Test

All building and testing is done through Xcode or `xcodebuild`:

```bash
# Build
xcodebuild -scheme Dunno -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run unit tests (Swift Testing framework)
xcodebuild test -scheme Dunno -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:DunnoTests

# Run UI tests
xcodebuild test -scheme Dunno -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:DunnoUITests
```

## Architecture

**State management:** Two layers — `AppState` (transient UI state, persisted to `UserDefaults`) and SwiftData (task persistence via `@Model`).

- `AppState` (`@Observable`) tracks `hasSeenTutorial` and `activeTaskId`. Both are written to `UserDefaults` on `didSet` so they survive app restarts.
- `TaskItem` is the sole SwiftData model. The `modelContainer` is attached at the app root and accessed via `@Environment(\.modelContext)` in views.

**Navigation is state-driven, not route-driven.** `RootContentView` is the single gatekeeper that reads `AppState` and `@Query` to decide which top-level view to show:
1. `WelcomeView` — first launch only (`!hasSeenTutorial`)
2. `ActiveTaskView` — when an `activeTaskId` is set and resolves to a live task
3. `MainTabView` — default (Tasks list + Settings tabs)

`RootContentView` also validates `activeTaskId` on appear and on task list changes, clearing stale IDs when a task has been deleted.

**Task limit:** The app enforces a hard cap of 8 incomplete tasks. `TaskListView` hides the add-task input when `tasks.count >= 8`, and `addTask()` guards against this too. The `@Query` in `TaskListView` filters to `!isCompleted` only — completed tasks remain in the store but are never shown.

**Randomizer flow:** `RandomizerView` receives a snapshot of the current incomplete task list. It runs a `Timer`-based spin animation (20–30 cycles at 0.1s intervals), then calls `appState.setActiveTask(_:)` after a 1.5s pause, which triggers `RootContentView` to switch to `ActiveTaskView`.

## Key Conventions

- Views inject `AppState` via `@Environment(AppState.self)` — it must be passed with `.environment(appState)` from the root.
- `modelContainer(for: TaskItem.self)` is set once at the `WindowGroup` level; never create additional containers.
- Unit tests use Swift Testing (`@Test`, `#expect`); UI tests use XCTest.
