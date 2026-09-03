//
//  SettingsView.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @StateObject private var adManager = AdMobManager.shared
    @Query private var folders: [Folder]
    
    @AppStorage("userColorScheme") private var userColorScheme: Int = 0
    @AppStorage(SampleDataGenerator.hasInsertedSampleKey) private var hasInsertedSampleData: Bool = false
    
    var body: some View {
        List {
            // MARK: - Plan Status
            Section(header: Text("Plan Status")) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(adManager.isProUser ? "Cardabase Pro" : "Free Plan")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text(adManager.isProUser ? "Unlimited databases, records, and ad-free experience." : "Limited to \(Limits.maxFoldersForFree) databases & \(Limits.maxKnowledgesPerFolderForFree) records per database.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if adManager.isProUser {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                    }
                }
                .padding(.vertical, 4)
                
                if !adManager.isProUser {
                    Button(action: { appState.isShowingPaywall = true }) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text("Upgrade to Pro")
                                .bold()
                        }
                    }
                }
            }
            
            // Statistics
            Section(header: Text("Statistics")) {
                HStack {
                    Text("Total Databases")
                    Spacer()
                    Text("\(folders.count) / \(adManager.isProUser ? "∞" : "\(Limits.maxFoldersForFree)")")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Appearance
            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $userColorScheme) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .pickerStyle(.menu)
            }
            
            // Data Management Section
            Section(header: Text("Data Management")) {
                Button(action: {
                    SampleDataGenerator.insertSampleDataIfNeeded(modelContext: modelContext)
                }) {
                    HStack {
                        Text(hasInsertedSampleData ? "Sample Data Loaded" : "Load Sample Data")
                    }
                }
                .disabled(hasInsertedSampleData)
                
                NavigationLink(destination: DataManagementView()) {
                    Text("Data Import / Export")
                }
            }
            
            // App Info
            Section(header: Text("About App")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("3.0")
                        .foregroundStyle(.secondary)
                }
                
                Button("Restore Purchases") {
                    Task {
                        try? await adManager.restorePurchases()
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $appState.isShowingPaywall) {
            PaywallView()
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppState())
            .modelContainer(for: [Folder.self, Knowledge.self], inMemory: true)
    }
}
