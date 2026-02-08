# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Build the library via SPM (from Modules/swift-background-scheduler/)
swift build

# Run all library tests (from Modules/swift-background-scheduler/)
swift test

# Build via Xcode workspace
xcodebuild -workspace Workspace.xcworkspace -scheme TaskScheduler build

# Run tests via Xcode workspace
xcodebuild -workspace Workspace.xcworkspace -scheme TaskScheduler test
```

The demo app (`BackgroundApp`) is built through the Xcode workspace and targets iOS 17+.

## Architecture

This is a Swift workspace containing a reusable task scheduler library and a demo app.

### Workspace Layout

- **Modules/swift-background-scheduler/** — Core library (git submodule from `molayab/swift-background-scheduler`, branch `master`). This is an SPM package named `TaskScheduler` (Swift 6.2, iOS 17+, macOS 10.15+).
- **Applications/BackgroundApp/** — SwiftUI + SwiftData demo app showing library integration with iOS background tasks.
- **Workspace.xcworkspace** — Ties both together for unified development.

### Library Architecture (TaskScheduler)

The library uses **actor-based concurrency** with a global actor pattern:

- **`TaskScheduler`** (global actor) — Central scheduler managing three queues: execution, delayed, and periodic tasks. Singleton via `TaskScheduler.shared`.
- **`ExecutableTask`** (protocol) — Defines async tasks that can be scheduled. Must be `Sendable`.
- **`TaskScheduleMode`** — Enum: `.immediate`, `.delayed(TimeInterval)`, `.periodic(TimeInterval)`.
- **`TaskExecutor`** — Pulls and executes tasks from the scheduler. Supports `justNext()`, `runContinuously()`, `resume()`, `pause()`.
- **`TaskExecutorSignal`** — Non-blocking trigger system using `AsyncStream`. Supports `.manualTrigger()`, `.timerTrigger(every:)`, `.customDrivenTrigger(usingBackend:)`.
- **`Backend`** (protocol) — Platform-specific background execution backends:
  - `iOSBackend` — Uses Apple `BackgroundTasks` framework, integrates via `WindowGroup.registerBackgroundSchedulerBackend()`.
  - `MacOSBackend` — Uses `NSBackgroundActivityScheduler` (15-min interval).
- **`SharedResource<T>`** — Generic actor for thread-safe mutable state access.

### Key Design Patterns

- **Global actor** for centralized, thread-safe task queue management
- **Signal-driven execution** via `AsyncStream` instead of polling
- **Protocol-oriented** with `Sendable` conformance throughout
- All concurrency uses Swift structured concurrency (async/await, actors)

## Testing

Tests use Apple's modern **Swift Testing** framework (`@Suite`, `@Test` macros), not XCTest. Test files are in `Modules/swift-background-scheduler/Tests/TaskSchedulerTests/`. The test plan is at `Modules/swift-background-scheduler/TestPlan.xctestplan`.

## Background Task Configuration

The demo app's `Info.plist` declares:
- `BGTaskSchedulerPermittedIdentifiers`: `com.example.backgroundapp.refresh`
- `UIBackgroundModes`: `processing`
