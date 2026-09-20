//
//  CardabaseApp.swift
//  Cardabase
//

import SwiftUI
import SwiftData
import GoogleMobileAds
import AppTrackingTransparency

@main
struct CardabaseApp: App {
    @StateObject private var appState = AppState()
    
    @AppStorage("userColorScheme") private var userColorScheme: Int = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    init() {
        // Initialize Google Mobile Ads SDK on app launch
        MobileAds.shared.start(completionHandler: nil)
    }
    
    private var selectedColorScheme: ColorScheme? {
        switch userColorScheme {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }
    
    // Shared SwiftData Model Container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Folder.self,
            Knowledge.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error.localizedDescription)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .preferredColorScheme(selectedColorScheme)
                .fullScreenCover(isPresented: Binding(
                    get: { !hasSeenOnboarding },
                    set: { hasSeenOnboarding = !$0 }
                )) {
                    OnboardingView(isFirstLaunch: Binding(
                        get: { !hasSeenOnboarding },
                        set: { hasSeenOnboarding = !$0 }
                    ))
                }
                .task {
                    await appState.refreshProStatus()
                    requestTrackingAuthorization()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    /// Requests App Tracking Transparency (ATT) authorization after a brief delay.
    private func requestTrackingAuthorization() {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}
