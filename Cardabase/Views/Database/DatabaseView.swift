//
//  DatabaseView.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import SwiftUI
import SwiftData

struct DatabaseView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Bindable var folder: Folder
    
    // state management
    @State private var searchText: String = ""
    @State private var isShowingAddSheet: Bool = false
    @State private var selectedKnowledgeToEdit: Knowledge?
    @State private var isShowingStudyConfig: Bool = false
    
    // search filtering record list
    private var filteredKnowledges: [Knowledge] {
        if searchText.isEmpty {
            return folder.knowledges.sorted { $0.createdAt > $1.createdAt }
        } else {
            return folder.knowledges.filter { knowledge in
                knowledge.title.localizedCaseInsensitiveContains(searchText) ||
                knowledge.summary.localizedCaseInsensitiveContains(searchText) ||
                knowledge.customFields.contains { $0.value.localizedCaseInsensitiveContains(searchText) }
            }.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    // MARK: - Main view
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                if !appState.isProUser {
                    AdBannerView()
                }
                
                // 2. 広告の直下に配置するカスタム検索バー
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search records & fields...", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // 3. レコードリスト
                List {
                    Section(header: Text("Records (\(filteredKnowledges.count))")) {
                        if filteredKnowledges.isEmpty {
                            ContentUnavailableView(
                                searchText.isEmpty ? "No Records" : "No Matching Records",
                                systemImage: searchText.isEmpty ? "doc.badge.plus" : "magnifyingglass",
                                description: Text(searchText.isEmpty ? "Tap '+' to add your first knowledge record." : "Try a different search term.")
                            )
                        } else {
                            ForEach(filteredKnowledges) { knowledge in
                                Button(action: { selectedKnowledgeToEdit = knowledge }) {
                                    KnowledgeRowView(knowledge: knowledge)
                                }
                                .buttonStyle(.plain)
                            }
                            .onDelete(perform: deleteKnowledges)
                        }
                    }
                }
            }
            
            Button(action: handleAddKnowledgeTapped) {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 3)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingAddSheet) {
            KnowledgeFormView(folder: folder)
        }
        .sheet(item: $selectedKnowledgeToEdit) { knowledge in
            KnowledgeFormView(folder: folder, knowledgeToEdit: knowledge)
        }
        .sheet(isPresented: $appState.isShowingPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Actions
    private func handleAddKnowledgeTapped() {
        if Limits.isKnowledgeLimitReached(currentCountInFolder: folder.knowledges.count, isPro: appState.isProUser) {
            appState.isShowingPaywall = true
        } else {
            isShowingAddSheet = true
        }
    }
    
    private func deleteKnowledges(at offsets: IndexSet) {
        for index in offsets {
            let knowledge = filteredKnowledges[index]
            modelContext.delete(knowledge)
        }
    }
}

// MARK: - Knowledge Row Component
private struct KnowledgeRowView: View {
    let knowledge: Knowledge
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(knowledge.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
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
                            HStack(spacing: 3) {
                                Text("\(field.key)")
                                    .fontWeight(.semibold)
                                Text(field.value)
                            }
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Capsule())
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Folder.self, Knowledge.self, configurations: config)
    let context = container.mainContext
    
    let folder = Folder(name: "SAKE DIPLOMA")
    
    // 1. マスター済み ＋ カスタムフィールドあり
    let k1 = Knowledge(
        title: "山田錦",
        summary: "兵庫県特A地区などで生産される代表的な酒造好適米。心白が大きく心白率が高い。",
        customFields: [
            FieldValue(key: "原産地", value: "兵庫県"),
            FieldValue(key: "特性", value: "心白大")
        ],
        masterStatus: .mastered
    )
    
    // 2. 不正解 ＋ サマリーのみ
    let k2 = Knowledge(
        title: "生酛造り",
        summary: "自然の乳酸菌を活用して醸造する伝統的な酒母造りの手法。重厚で複雑な味わいになる。",
        masterStatus: .incorrect
    )
    
    // 3. 未レビュー ＋ サマリーなし ＋ カスタムフィールドのみ
    let k3 = Knowledge(
        title: "醸造アルコール",
        summary: "",
        customFields: [
            FieldValue(key: "目的", value: "香りの引き出し・スッキリ感")
        ],
        masterStatus: .unreviewed
    )
    
    folder.knowledges.append(contentsOf: [k1, k2, k3])
    context.insert(folder)
    
    return NavigationStack {
        DatabaseView(folder: folder)
    }
    .modelContainer(container)
}
