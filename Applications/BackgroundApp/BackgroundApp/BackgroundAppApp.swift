//
//  BackgroundAppApp.swift
//  BackgroundApp
//
//  Created by Mateo Olaya on 1/30/26.
//

import SwiftUI
import SwiftData
import TaskScheduler
import BackgroundTasks

@main
struct BackgroundAppApp: App {
    @Environment(\.scenePhase) private var phase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    let executor = TaskExecutor(
        taskScheduler: .shared
    )
    
    init() {
        let sheduler = executor.taskScheduler
        let sharedModelContainer = sharedModelContainer
        Task {
            await sheduler.schedule(
                task: ExampleTask(
                    sharedModelContainer: sharedModelContainer
                ),
                mode: .periodic(5)
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Configure the background scheduler backend
        .registerBackgroundSchedulerBackend(
            identifier: "SCHEDULER_BG_TRIGGER",
            executor: executor,
            phase: phase
        )
        .modelContainer(sharedModelContainer)
    }
}

struct ExampleTask: ExecutableTask {
    var sharedModelContainer: ModelContainer
    
    func execute() async throws {
        let item = Item(timestamp: Date())
        await MainActor.run {
            let context = sharedModelContainer.mainContext
            context.insert(item)
            try? context.save()
        }
    }
}
