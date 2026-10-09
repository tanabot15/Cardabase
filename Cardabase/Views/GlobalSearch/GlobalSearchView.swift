//
//  GlobalSearchView.swift
//  Cardabase
//

import SwiftUI
import SwiftData

struct GlobalSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    
    @Query(sort: \Knowledge.createdAt, order: .reverse) private var allKnowledges: [Knowledge]
    @Query private var allFolders: [Folder]
    
    // MARK: - State Management
    @State private var searchText: String = ""
    @State private var selectedFieldTypeFilter: FieldTypeFilter = .all
    @State private var selectedStatusFilter: MasterStatusFilter = .all
    @State private var selectedKnowledgeToEdit: Knowledge? = nil
    
    // Random discovery card state
    @State private var randomDiscoveryKnowledge: Knowledge? = nil
    
    // MARK: - Filter Enums
    enum FieldTypeFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case text = "Text"
        case number = "Number"
        case url = "URL"
        case tag = "Tag"
        
        var id: String { rawValue }
    }
    
    enum MasterStatusFilter: String, CaseIterable, Identifiable {
        case all = "All Status"
        case unreviewed = "Unreviewed"
        case mastered = "Mastered"
        case incorrect = "Needs Review"
        
        var id: String { rawValue }
    }
    
    // MARK: - Filtered Results Logic
    private var searchResults: [Knowledge] {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return allKnowledges.filter { knowledge in
            // 1. Text Search Matching (Title, Summary, Custom Fields, Folder Name)
            let matchesText: Bool
            if trimmedQuery.isEmpty {
                matchesText = true
            } else {
                let matchesTitle = knowledge.title.localizedCaseInsensitiveContains(trimmedQuery)
                let matchesSummary = knowledge.summary.localizedCaseInsensitiveContains(trimmedQuery)
                let matchesFolder = knowledge.folder?.name.localizedCaseInsensitiveContains(trimmedQuery) ?? false
                let matchesCustom = knowledge.customFields.contains { field in
                    field.value.localizedCaseInsensitiveContains(trimmedQuery) ||
                    field.key.localizedCaseInsensitiveContains(trimmedQuery)
                }
                matchesText = matchesTitle || matchesSummary || matchesFolder || matchesCustom
            }
            
            // 2. Field Type Filter
            let matchesType: Bool
            switch selectedFieldTypeFilter {
            case .all:
                matchesType = true
            case .text:
                matchesType = knowledge.customFields.contains { $0.type == .text }
            case .number:
                matchesType = knowledge.customFields.contains { $0.type == .number }
            case .url:
                matchesType = knowledge.customFields.contains { $0.type == .url }
            case .tag:
                matchesType = knowledge.customFields.contains { $0.type == .tag }
            }
            
            // 3. Status Filter
            let matchesStatus: Bool
            switch selectedStatusFilter {
            case .all:
                matchesStatus = true
            case .unreviewed:
                matchesStatus = knowledge.masterStatus == .unreviewed
            case .mastered:
                matchesStatus = knowledge.masterStatus == .mastered
            case .incorrect:
                matchesStatus = knowledge.masterStatus == .incorrect
            }
            
            return matchesText && matchesType && matchesStatus
        }
    }
    
    // MARK: - Main Body
    var body: some View {
        VStack(spacing: 0) {
            if !appState.isProUser {
                AdBannerView()
            }
            
            // Search Input Header
            VStack(spacing: 12) {
                // Search TextField
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search titles, summaries, fields, folders...", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Filter Chips ScrollView
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Field Type Filter Picker
                        Menu {
                            ForEach(FieldTypeFilter.allCases) { filter in
                                Button(action: { selectedFieldTypeFilter = filter }) {
                                    HStack {
                                        Text(filter.rawValue)
                                        if selectedFieldTypeFilter == filter {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                Text("Type: \(selectedFieldTypeFilter.rawValue)")
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedFieldTypeFilter == .all ? Color(.tertiarySystemBackground) : Color.accentColor.opacity(0.15))
                            .foregroundStyle(selectedFieldTypeFilter == .all ? Color.primary : Color.accentColor)
                            .clipShape(Capsule())
                        }
                        
                        // Status Filter Picker
                        Menu {
                            ForEach(MasterStatusFilter.allCases) { filter in
                                Button(action: { selectedStatusFilter = filter }) {
                                    HStack {
                                        Text(filter.rawValue)
                                        if selectedStatusFilter == filter {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal")
                                Text(selectedStatusFilter.rawValue)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedStatusFilter == .all ? Color(.tertiarySystemBackground) : Color.green.opacity(0.15))
                            .foregroundStyle(selectedStatusFilter == .all ? Color.primary : Color.green)
                            .clipShape(Capsule())
                        }
                        
                        if selectedFieldTypeFilter != .all || selectedStatusFilter != .all {
                            Button("Reset Filters") {
                                selectedFieldTypeFilter = .all
                                selectedStatusFilter = .all
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
            
            Divider()
            
            // Search Results or Random Discovery
            List {
                if searchText.isEmpty && selectedFieldTypeFilter == .all && selectedStatusFilter == .all {
                    // Random Discovery Section
                    if let discoveryCard = randomDiscoveryKnowledge {
                        Section(header: Label("Random Discovery", systemImage: "sparkles")) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Knowledge Spotlight")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.accentColor)
                                    Spacer()
                                    Button(action: refreshRandomCard) {
                                        HStack(spacing: 2) {
                                            Image(systemName: "arrow.clockwise")
                                            Text("Shuffle")
                                        }
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                GlobalKnowledgeRowView(knowledge: discoveryCard)
                                    .onTapGesture {
                                        selectedKnowledgeToEdit = discoveryCard
                                    }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Section(header: Text("Recent Records (\(allKnowledges.prefix(20).count))")) {
                        ForEach(allKnowledges.prefix(20)) { knowledge in
                            Button(action: { selectedKnowledgeToEdit = knowledge }) {
                                GlobalKnowledgeRowView(knowledge: knowledge)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    Section(header: Text("Search Results (\(searchResults.count))")) {
                        if searchResults.isEmpty {
                            ContentUnavailableView(
                                "No Records Found",
                                systemImage: "doc.text.magnifyingglass",
                                description: Text("Try searching with different keywords or reset your filters.")
                            )
                        } else {
                            ForEach(searchResults) { knowledge in
                                Button(action: { selectedKnowledgeToEdit = knowledge }) {
                                    GlobalKnowledgeRowView(knowledge: knowledge)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Global Search")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if randomDiscoveryKnowledge == nil {
                refreshRandomCard()
            }
        }
        .sheet(item: $selectedKnowledgeToEdit) { knowledge in
            if let folder = knowledge.folder {
                KnowledgeFormView(folder: folder, knowledgeToEdit: knowledge)
            }
        }
    }
    
    private func refreshRandomCard() {
        guard !allKnowledges.isEmpty else { return }
        randomDiscoveryKnowledge = allKnowledges.randomElement()
    }
}

// MARK: - Subview: Global Knowledge Row Component

private struct GlobalKnowledgeRowView: View {
    let knowledge: Knowledge
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if let folderName = knowledge.folder?.name {
                        Text(folderName.uppercased())
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.accentColor)
                    }
                    Text(knowledge.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                switch knowledge.masterStatus {
                case .mastered:
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                case .incorrect:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                case .unreviewed:
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                }
            }
            
            if !knowledge.summary.isEmpty {
                Text(knowledge.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            if !knowledge.customFields.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(knowledge.customFields) { field in
                            if !field.value.isEmpty {
                                HStack(spacing: 3) {
                                    Text("\(field.key):")
                                        .fontWeight(.semibold)
                                    Text(field.value)
                                }
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(.tertiarySystemBackground))
                                .clipShape(Capsule())
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview("Global Search Preview") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Folder.self, Knowledge.self, configurations: config)
    let context = container.mainContext
    
    let folder = Folder(name: "Financial Indicators")
    let k1 = Knowledge(
        title: "ROIC",
        summary: "Return on Invested Capital. Measures company efficiency at allocating capital.",
        customFields: [
            FieldValue(key: "Formula", value: "NOPAT / Invested Capital"),
            FieldValue(key: "Category", value: "Profitability", type: .tag)
        ],
        masterStatus: .mastered
    )
    let k2 = Knowledge(
        title: "PER",
        summary: "Price to Earnings Ratio.",
        customFields: [
            FieldValue(key: "Formula", value: "Share Price / EPS")
        ]
    )
    folder.knowledges.append(contentsOf: [k1, k2])
    context.insert(folder)
    
    return NavigationStack {
        GlobalSearchView()
    }
    .modelContainer(container)
    .environmentObject(AppState())
}
