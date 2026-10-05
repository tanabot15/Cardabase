//
//  SettingsView.swift
//  Cardabase
//

import SwiftUI
import SwiftData
import UserNotifications

/// Application Settings view displaying user subscription, study options, appearance, data utilities, and support.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @StateObject private var adManager = AdMobManager.shared
    @Query private var folders: [Folder]
    @Query private var knowledges: [Knowledge]
    
    // MARK: - AppStorage Settings
    @AppStorage("userColorScheme") private var userColorScheme: Int = 0
    @AppStorage("flashcardFontSize") private var flashcardFontSize: Double = 18.0
    @AppStorage("defaultStudyMode") private var defaultStudyMode: String = StudyMode.memorization.rawValue
    
    // Notification Settings
    @AppStorage("isNotificationEnabled") private var isNotificationEnabled: Bool = false
    @AppStorage("notificationTime") private var notificationTimeInterval: Double = 72000 // Default 20:00 (seconds from midnight)
    
    // MARK: - State Management
    @State private var selectedNotificationDate: Date = {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    }()
    
    @State private var isShowingDeleteConfirm: Bool = false
    @State private var alertMessage: String = ""
    @State private var isShowingAlert: Bool = false
    
    var body: some View {
        List {
            // MARK: 1. Account & Subscription
            Section(header: Text("Account Status")) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(adManager.isProUser ? "Pro Plan" : "Free Plan")
                            .font(.headline)
                        
                        Text(adManager.isProUser ? "All premium features are unlocked." : "Limited database and record capacity.")
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
                        HStack(spacing: 12) {
                            // Star Icon with Soft Glow Background
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.25))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "star.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            
                            // Title & Subtitle
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Upgrade to Cardabase Pro")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                
                                Text("Unlock unlimited cards & ad-free experience")
                                    .font(.caption2)
                                    .foregroundStyle(Color.white.opacity(0.9))
                            }
                            
                            Spacer()
                            
                            // Chevron Indicator
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.8))
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: Color.orange.opacity(0.35), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
                
                Button("Restore Purchases") {
                    restorePurchases()
                }
                .buttonStyle(.plain)
            }
            
            // MARK: 2. Study & Review
            Section(header: Text("Study & Review")) {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Notifications / Reminders", isOn: $isNotificationEnabled)
                        .onChange(of: isNotificationEnabled) { _, newValue in
                            if newValue {
                                requestAndScheduleNotification()
                            }
                        }
                    
                    if isNotificationEnabled {
                        DatePicker("Reminder Time", selection: $selectedNotificationDate, displayedComponents: .hourAndMinute)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 12)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .onChange(of: selectedNotificationDate) { _, newDate in
                                scheduleNotification(at: newDate)
                            }
                    }
                }
                .animation(.default, value: isNotificationEnabled)
                
                Picker("Default Study Mode", selection: $defaultStudyMode) {
                    ForEach(StudyMode.allCases) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
            }
            
            // MARK: 3. Appearance
            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $userColorScheme) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Font Size  (Flashcard)")
                        Spacer()
                        Text("\(Int(flashcardFontSize)) pt")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $flashcardFontSize, in: 12...32, step: 1)
                    
                    Text("Sample Flashcard Text")
                        .font(.system(size: CGFloat(flashcardFontSize)))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 6)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(6)
                }
                .padding(.vertical, 4)
            }
            
            // MARK: 4. Data & Backup
            Section(header: Text("Data & Backup")) {
                NavigationLink(destination: DataManagementView()) {
                    Text("Data Backup / Restore")
                }
                
                Button(role: .destructive, action: { isShowingDeleteConfirm = true }) {
                    Text("Reset All Data")
                }
            }
            
            // MARK: 5. About & Support
            Section(header: Text("About & Support")) {
                HStack {
                    Text("App Version")
                    Spacer()
                    Text("3.9")
                        .foregroundStyle(.secondary)
                }
                
                Button(action: openAppStoreReview) {
                    Text("Write a Review / Rate App")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Reset All Data", isPresented: $isShowingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete All Data", role: .destructive) {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("All databases and study histories will be permanently deleted. This action cannot be undone.")
        }
        .alert("Settings", isPresented: $isShowingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            initNotificationDate()
        }
    }
    
    // MARK: - Actions & Helpers
    
    private func restorePurchases() {
        Task {
            try? await adManager.restorePurchases()
            await appState.refreshProStatus()
            alertMessage = appState.isProUser ? "Purchases successfully restored." : "No active purchases found."
            isShowingAlert = true
        }
    }
    
    private func initNotificationDate() {
        let calendar = Calendar.current
        let hour = Int(notificationTimeInterval) / 3600
        let minute = (Int(notificationTimeInterval) % 3600) / 60
        if let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) {
            selectedNotificationDate = date
        }
    }
    
    private func requestAndScheduleNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    scheduleNotification(at: selectedNotificationDate)
                } else {
                    isNotificationEnabled = false
                    alertMessage = "Notification permission was denied. Please enable it in iOS Settings."
                    isShowingAlert = true
                }
            }
        }
    }
    
    private func scheduleNotification(at date: Date) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        
        // Save time interval
        if let hour = components.hour, let minute = components.minute {
            notificationTimeInterval = Double(hour * 3600 + minute * 60)
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Cardabase"
        content.body = "Time for your daily review! Keep your streak going."
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_study_reminder", content: content, trigger: trigger)
        
        center.add(request)
    }
    
    private func deleteAllData() {
        do {
            try modelContext.delete(model: Knowledge.self)
            try modelContext.delete(model: Folder.self)
            alertMessage = "All data has been successfully reset."
            isShowingAlert = true
        } catch {
            alertMessage = "Failed to delete data: \(error.localizedDescription)"
            isShowingAlert = true
        }
    }
    
    private func openAppStoreReview() {
        if let url = URL(string: "https://apps.apple.com/app/id123456789?action=write-review") {
            UIApplication.shared.open(url)
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
