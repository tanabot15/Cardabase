//
//  SettingsView.swift
//  Cardabase
//

import SwiftUI
import SwiftData

/// Application Settings view displaying user subscription, options, and data utilities.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @StateObject private var adManager = AdMobManager.shared
    @Query private var folders: [Folder]
    
    @AppStorage("userColorScheme") private var userColorScheme: Int = 0
    @AppStorage(SampleDataGenerator.hasInsertedSampleKey) private var hasInsertedSampleData: Bool = false
    
    var body: some View {
        List {
            // MARK: Plan Status Section
            Section(header: Text("Plan Status")) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(adManager.isProUser ? "Cardabase Pro" : "Free Plan")
                            .font(.headline)
                        
                        Text(adManager.isProUser ? "Unlimited databases and ad-free experience." : "Limited to \(Limits.maxFoldersForFree) databases & \(Limits.maxKnowledgesPerFolderForFree) records per database.")
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
                        Label("Upgrade to Pro", systemImage: "star.fill")
                            .bold()
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            
            // MARK: Usage Statistics
            Section(header: Text("Usage Statistics")) {
                HStack {
                    Text("Total Databases")
                    Spacer()
                    Text("\(folders.count) / \(adManager.isProUser ? "∞" : "\(Limits.maxFoldersForFree)")")
                        .foregroundStyle(.secondary)
                }
            }
            
            // MARK: Appearance Section
            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $userColorScheme) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .pickerStyle(.menu)
            }
            
            // MARK: Data Management Section
            Section(header: Text("Data Management")) {
                Button(action: {
                    SampleDataGenerator.insertSampleDataIfNeeded(modelContext: modelContext)
                }) {
                    Text(hasInsertedSampleData ? "Sample Databases Loaded" : "Load Sample Databases")
                }
                .disabled(hasInsertedSampleData)
                
                NavigationLink(destination: DataManagementView()) {
                    Text("Data Import / Export")
                }
            }
            
            // MARK: App Information
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("3.2.0")
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

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Folder.self, Knowledge.self, configurations: config)
    
    return NavigationStack {
        SettingsView()
            .environmentObject(AppState())
            .modelContainer(container)
    }
}
