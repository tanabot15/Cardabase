//
//  CardabaseApp.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import SwiftUI
import SwiftData

@main
struct CardabaseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var appState = AppState()
    
    // SwiftData model container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Folder.self,
            Knowledge.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .onAppear {
                    SampleDataGenerator.insertSampleDataIfNeeded(modelContext: sharedModelContainer.mainContext)
                }
            // for Pro
//                .task {
//                    await appState.refreshProStatus()
//                }
        }
        .modelContainer(sharedModelContainer)
    }
}
