//
//  CardabaseApp.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import SwiftUI
import SwiftData
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport

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
    
    /// Request App Tracking Transparency (ATT) authorization
    private func requestAppTrackingAuthorization() {
        print("[ATT Check] Current Status: \(ATTrackingManager.trackingAuthorizationStatus.rawValue)")

        // Request only if the status is not determined yet
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            // Delay for 1.0 second to ensure the app window is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    switch status {
                    case .authorized:
                        print("[ATT] Tracking authorized (IDFA: \(ASIdentifierManager.shared().advertisingIdentifier))")
                    case .denied:
                        print("[ATT] Tracking denied")
                    case .notDetermined:
                        print("[ATT] Tracking not determined")
                    case .restricted:
                        print("[ATT] Tracking restricted")
                    @unknown default:
                        break
                    }
                }
            }
        }
    }
}
