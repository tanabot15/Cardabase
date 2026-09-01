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
    
    @AppStorage("userColorScheme") private var userColorScheme: Int = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    private var selectedColorScheme: ColorScheme? {
        switch userColorScheme {
        case 1: return .light
        case 2: return .dark
        default: return nil // システム設定に従う
        }
    }
    
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
        }
        .modelContainer(sharedModelContainer)
    }
    
    /// Request App Tracking Transparency (ATT) authorization
    private func requestAppTrackingAuthorization() {
        print("[ATT Check] Current Status: \(ATTrackingManager.trackingAuthorizationStatus.rawValue)")

        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
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
