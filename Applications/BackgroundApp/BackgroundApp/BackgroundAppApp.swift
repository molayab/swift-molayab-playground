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

struct LaunchView: View {
    private let backgroundTaskExecutor = TaskExecutor(taskScheduler: .shared)
    
    @Environment(\.modelContext) private var modelContainer
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.example.backgroundapp.refresh",
            using: DispatchQueue.global()
        ) { [backgroundTaskExecutor] task in
            // This task is cast with processing task
            print("Background task handler invoked")
            let request = BGProcessingTaskRequest(
                identifier: "com.example.backgroundapp.refresh"
            )
            request.earliestBeginDate = Date()
            request.requiresNetworkConnectivity = false
            
            task.expirationHandler = {
                Task(operation: {
                    print("Background task expired")
                    await backgroundTaskExecutor.pause()
                    try? BGTaskScheduler
                        .shared
                        .submit(request)
                    task.setTaskCompleted(success: true)
                })
            }
            
            Task(operation: {
                print("Background task started")
                await backgroundTaskExecutor
                    .runContinuously()
                    .value
                print("Background task completed")
                
                try? BGTaskScheduler
                    .shared
                    .submit(request)
                task.setTaskCompleted(success: true)
            })
        }
    }
    
    @State private var isRunningAuto = false
    
    var body: some View {
        ContentView()
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    print("App is active")
                case .inactive:
                    print("App is inactive")
                case .background:
                    print("App is in background")
                    let request = BGProcessingTaskRequest(
                        identifier: "com.example.backgroundapp.refresh"
                    )

                    request.earliestBeginDate = Date()
                    request.requiresNetworkConnectivity = false
                    do {
                        try BGTaskScheduler
                            .shared
                            .submit(request)
                    } catch {
                        print("Could not schedule background task: \(error)")
                    }
                @unknown default:
                    print("Unknown scene phase")
                }
            }
            .overlay(alignment: .bottomTrailing, content: {
                Button(action: {
                    Task(priority: .background) {
                        if !isRunningAuto {
                            isRunningAuto = true
                            await backgroundTaskExecutor.runContinuously().value
                        } else {
                            await backgroundTaskExecutor.pause()
                            isRunningAuto = false
                        }
                    }
                }) {
                    Text(isRunningAuto ? "Pause Background Tasks" : "Start Background Tasks")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding()
                }
            })
            .task(id: "background.register", {
                await backgroundTaskExecutor
                    .taskScheduler
                    .schedule(
                        task: ExampleTask(
                            sharedModelContainer: modelContainer.container
                        ),
                        mode: .periodic(0.1))
                
                await backgroundTaskExecutor
                    .taskScheduler
                    .schedule(
                        task: ExampleTaskTwo(
                            sharedModelContainer: modelContainer.container),
                        mode: .periodic(5))
            })
    }
}

@main
struct BackgroundAppApp: App {
    
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
    
    //

    var body: some Scene {
        WindowGroup {
            LaunchView()
        }
        // Configure the background scheduler backend
//        .registerBackgroundSchedulerBackend(
//            identifier: "SCHEDULER_BG_TRIGGER",
//            executor: executor,
//            phase: phase
//        )
        .modelContainer(sharedModelContainer)
    }
}

@MainActor
struct ExampleTask: ExecutableTask {
    var sharedModelContainer: ModelContainer
    
    func execute() async throws {
        let newItem = Item(name: "Task #1 (delayed) executed at \(Date())")
        
        // Await random tiem for testing propouses
        let randomDelay = UInt64(Int.random(in: 500_000...2_000_000_000))
        try? await Task.sleep(nanoseconds: randomDelay)
        
        sharedModelContainer.mainContext.insert(newItem)
        try? sharedModelContainer.mainContext.save()
    }
}

@MainActor
struct ExampleTaskTwo: ExecutableTask {
    var sharedModelContainer: ModelContainer
    
    func execute() async throws {
        let newItem = Item(name: "Task #2 executed at \(Date())")
        
        sharedModelContainer.mainContext.insert(newItem)
        try? sharedModelContainer.mainContext.save()
    }
}
