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
    @Bindable var folder: Folder
    
    // state management
    @State private var searchText: String = ""
    @State private var isShowingAddSheet: Bool = false
    @State private var selectedKnowledgeToEdit: Knowledge?
    @State private var isShowingStudyConfig: Bool = false
    @State private var isShowingPaywall: Bool = false
    
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
            VStack {
                AdBannerView()
                
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
        .searchable(text: $searchText, prompt: "Search records & fields...")
        .sheet(isPresented: $isShowingAddSheet) {
            KnowledgeFormView(folder: folder)
        }
        .sheet(item: $selectedKnowledgeToEdit) { knowledge in
            KnowledgeFormView(folder: folder, knowledgeToEdit: knowledge)
        }
        // for Pro
//        .sheet(isPresented: $isShowingPaywall) {
//            PaywallView()
//        }
    }
    
    // MARK: - Actions
    private func handleAddKnowledgeTapped() {
        // for Pro
//        if Limits.isKnowledgeLimitReached(currentCountInFolder: folder.knowledges.count) {
//            isShowingPaywall = true
//        } else {
//            isShowingAddSheet = true
//        }
        
        // delete when Pro
        isShowingAddSheet = true
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

// MARK: - Temporary Placeholders
//private struct CardConfigPlaceholderView: View {
//    let folder: Folder
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 20) {
//                Image(systemName: "gearshape.2.fill")
//                    .font(.system(size: 60))
//                    .foregroundStyle(Color.accentColor)
//                Text("Card Config for '\(folder.name)'")
//                    .font(.title2)
//                    .bold()
//                Text("Front/Back column selector will be implemented here.")
//                    .foregroundStyle(.secondary)
//            }
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Close") { dismiss() }
//                }
//            }
//        }
//    }
//}
//
//private struct PaywallPlaceholderView: View {
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        VStack(spacing: 20) {
//            Image(systemName: "star.circle.fill")
//                .font(.system(size: 60))
//                .foregroundStyle(.yellow)
//            Text("Upgrade to Cardabase Pro")
//                .font(.title2)
//                .bold()
//            Text("Free version is limited to 50 records per database.\nUpgrade to Pro for unlimited records.")
//                .multilineTextAlignment(.center)
//                .foregroundStyle(.secondary)
//                .padding(.horizontal)
//            
//            Button(action: { dismiss() }) {
//                Text("Close")
//                    .bold()
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(Color.accentColor)
//                    .foregroundStyle(.white)
//                    .cornerRadius(12)
//            }
//            .padding(.horizontal, 32)
//        }
//        .padding()
//    }
//}

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
