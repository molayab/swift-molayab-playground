# Swift Background Scheduler

A lightweight, actor-based task scheduler for Swift. Schedule immediate, delayed, or periodic async work and execute it through a signal-driven executor — no busy waiting. Works with iOS `BackgroundTasks`, macOS `NSBackgroundActivityScheduler`, SwiftUI, server-side Swift, or any Swift concurrency context.

[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20|%20macOS%2010.15%20|%20tvOS%20|%20watchOS-blue.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- **Immediate, delayed, and periodic** scheduling modes
- **Global actor** (`TaskScheduler`) for thread-safe task queuing
- **Signal-driven execution** using `AsyncStream` — no polling or busy waiting
- **Platform backends** for iOS (`BackgroundTasks`) and macOS (`NSBackgroundActivityScheduler`)
- **Custom backends** — plug in your own trigger source (push notifications, sockets, file events, etc.)
- **Pure Swift** with full `Sendable` conformance and structured concurrency

## Installation

Add the package via Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/molayab/swift-background-scheduler.git", branch: "master")
]
```

Then add `TaskScheduler` as a dependency to your target:

```swift
.target(
    name: "YourApp",
    dependencies: ["TaskScheduler"]
)
```

## Quick Start

### 1. Define a task

```swift
import TaskScheduler

struct PrintTask: ExecutableTask {
    let message: String

    func execute() async throws {
        print(message)
    }
}
```

### 2. Schedule and run

```swift
let scheduler = TaskScheduler.shared

// Create a signal-driven executor
let signal = TaskExecutorSignal.timerTrigger(every: 1.0)
let executor = TaskExecutor(taskScheduler: scheduler, taskSignal: signal)

// Start the executor
await executor.resume()

// Schedule tasks
await scheduler.schedule(task: PrintTask(message: "Hello now"), mode: .immediate)
await scheduler.schedule(task: PrintTask(message: "Hello in 2s"), mode: .delayed(2))
await scheduler.schedule(task: PrintTask(message: "Hello every 5s"), mode: .periodic(5))
```

## Scheduling Modes

| Mode | Description |
|------|-------------|
| `.immediate` | Runs on the next executor cycle |
| `.delayed(seconds)` | Runs once after the specified delay |
| `.periodic(seconds)` | Runs repeatedly at the given interval |

## Signal-Driven Execution

`TaskExecutor` listens to an `AsyncStream` produced by `TaskExecutorSignal`. The executor only wakes when a signal fires — no CPU time is wasted polling.

### Manual trigger

```swift
let signal = TaskExecutorSignal.manualTrigger()
let executor = TaskExecutor(taskScheduler: .shared, taskSignal: signal)
Task { await executor.resume() }

await TaskScheduler.shared.schedule(task: PrintTask(message: "On demand"), mode: .immediate)
signal.trigger()
```

### Timer trigger

```swift
let signal = TaskExecutorSignal.timerTrigger(every: 0.5)
let executor = TaskExecutor(taskScheduler: .shared, taskSignal: signal)
Task { await executor.resume() }
```

### System-driven trigger

Connects to platform-specific backends for power-efficient background execution:

```swift
let scheduler = TaskScheduler.shared
let executor = TaskExecutor(taskScheduler: scheduler, taskSignal: .manualTrigger())
Task { await executor.resume() }

let signal = TaskExecutorSignal.systemDrivenTrigger(executor: executor)
```

**Built-in backends:**

| Platform | Backend | Mechanism |
|----------|---------|-----------|
| iOS / tvOS / watchOS | `iOSBackend` | System background task scheduling (`BGTaskScheduler`) |
| macOS | `MacOSBackend` | `NSBackgroundActivityScheduler` (15-min intervals) |
| Other | Fallback | `executor.runContinuously()` |

### Custom backend

Implement the `Backend` protocol to trigger execution from any source:

```swift
final class PushBackend: Backend {
    private var executor: TaskExecutorInterface?

    func register(_ executor: TaskExecutorInterface) {
        self.executor = executor
    }

    func onPushReceived() {
        Task { _ = await executor?.runNext() }
    }
}

let backend = PushBackend()
TaskExecutorSignal.customDrivenTrigger(
    usingBackend: backend,
    withExecutor: executor
)
```

## Demo App

The `Applications/BackgroundApp/` directory contains a SwiftUI + SwiftData demo app that demonstrates:

- Registering periodic tasks with the scheduler
- Integrating with iOS `BGTaskScheduler` for real background execution
- Persisting task execution results with SwiftData
- Pausing and resuming the executor at runtime

Open `Workspace.xcworkspace` in Xcode to build and run both the library and the demo app together.

## Project Structure

```
├── Modules/
│   └── swift-background-scheduler/    # Core library (SPM package, git submodule)
│       ├── Sources/TaskScheduler/
│       │   ├── Scheduler/             # TaskScheduler global actor, scheduling modes
│       │   ├── Executable/            # ExecutableTask protocol
│       │   ├── Engine/                # TaskExecutor, TaskExecutorSignal
│       │   │   └── Backends/          # Platform-specific backends (iOS, macOS)
│       │   └── Utils/                 # SharedResource actor
│       └── Tests/TaskSchedulerTests/  # Tests (Swift Testing framework)
├── Applications/
│   └── BackgroundApp/                 # SwiftUI demo app
└── Workspace.xcworkspace              # Unified Xcode workspace
```

## Building & Testing

```bash
# Build the library
cd Modules/swift-background-scheduler
swift build

# Run tests
swift test

# Or use the Xcode workspace
xcodebuild -workspace Workspace.xcworkspace -scheme TaskScheduler build
xcodebuild -workspace Workspace.xcworkspace -scheme TaskScheduler test
```

## Contributing

Contributions are welcome! Please open issues or pull requests on the [GitHub repository](https://github.com/molayab/swift-background-scheduler).

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
