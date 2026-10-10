//
//  QuickAddHubSheet.swift
//  Cardabase
//

import SwiftUI
import SwiftData

struct QuickAddHubSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    let folders: [Folder]
    
    @State private var selectedFolder: Folder?
    @State private var activeSheet: ActiveSheet?
    
    enum ActiveSheet: Identifiable {
        case single
        case bulk
        case voice
        case createFolder
        
        var id: String {
            switch self {
            case .single: return "single"
            case .bulk: return "bulk"
            case .voice: return "voice"
            case .createFolder: return "createFolder"
            }
        }
    }
    
    init(folders: [Folder], initialSelectedFolder: Folder? = nil) {
        self.folders = folders
        _selectedFolder = State(initialValue: initialSelectedFolder ?? folders.first)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - 1. Database / Folder Creation Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Folder")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 4)
                        
                        QuickAddOptionCard(
                            title: "Database / Folder",
                            subtitle: "Create a new database structure for records",
                            icon: "folder.badge.plus",
                            color: .orange,
                            isDisabled: false
                        ) {
                            if Limits.isFolderLimitReached(currentCount: folders.count, isPro: appState.isProUser) {
                                appState.isShowingPaywall = true
                            } else {
                                activeSheet = .createFolder
                            }
                        }
                    }
                    
                    Divider()
                    
                    // MARK: - 2. Add Records Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("New Records")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 4)
                        
                        // Target Folder Selector
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Target Database")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                            
                            if folders.isEmpty {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                    Text("No databases available. Please create one above first.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            } else {
                                Menu {
                                    ForEach(folders) { folder in
                                        Button(action: { selectedFolder = folder }) {
                                            HStack {
                                                Text(folder.name)
                                                if selectedFolder?.id == folder.id {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "folder.fill")
                                            .foregroundStyle(Color.accentColor)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(selectedFolder?.name ?? "Select Folder")
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            
                                            if let folder = selectedFolder {
                                                Text("\(folder.knowledges.count) records")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        
                        // Input Method Cards
                        VStack(spacing: 10) {
                            // Single Record
                            QuickAddOptionCard(
                                title: "Single Record",
                                subtitle: "Add a card with title, summary, and custom fields",
                                icon: "doc.badge.plus",
                                color: .blue,
                                isDisabled: folders.isEmpty
                            ) {
                                activeSheet = .single
                            }
                            
                            // Bulk Records
                            QuickAddOptionCard(
                                title: "Bulk Records",
                                subtitle: "Paste text lists, CSV, or spreadsheet rows",
                                icon: "square.and.arrow.down.on.square.fill",
                                color: .green,
                                isDisabled: folders.isEmpty
                            ) {
                                activeSheet = .bulk
                            }
                            
                            // Voice to Card
                            QuickAddOptionCard(
                                title: "Voice to Card",
                                subtitle: "Dictate naturally and parse into fields automatically",
                                icon: "mic.circle.fill",
                                color: .purple,
                                isDisabled: folders.isEmpty
                            ) {
                                activeSheet = .voice
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $activeSheet) { item in
                switch item {
                case .single:
                    if let folder = selectedFolder {
                        KnowledgeFormView(folder: folder)
                    }
                case .bulk:
                    if let folder = selectedFolder {
                        QuickAddView(folder: folder)
                    }
                case .voice:
                    if let folder = selectedFolder {
                        VoiceCardInputSheet(folder: folder)
                    }
                case .createFolder:
                    FolderFormView()
                }
            }
        }
    }
}

// MARK: - Subview: Quick Add Option Card

private struct QuickAddOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isDisabled ? 0.08 : 0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(isDisabled ? .gray : color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(isDisabled ? .secondary : .primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .opacity(isDisabled ? 0.6 : 1.0)
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Light") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Folder.self, Knowledge.self, configurations: config)
    let context = container.mainContext
    
    let folder1 = Folder(name: "SAKE DIPLOMA Exam")
    let folder2 = Folder(name: "Financial Indicators")
    context.insert(folder1)
    context.insert(folder2)
    
    return QuickAddHubSheet(folders: [folder1, folder2])
        .environmentObject(AppState())
        .modelContainer(container)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Folder.self, Knowledge.self, configurations: config)
    let context = container.mainContext
    
    let folder1 = Folder(name: "SAKE DIPLOMA Exam")
    let folder2 = Folder(name: "Financial Indicators")
    context.insert(folder1)
    context.insert(folder2)
    
    return QuickAddHubSheet(folders: [folder1, folder2])
        .environmentObject(AppState())
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
