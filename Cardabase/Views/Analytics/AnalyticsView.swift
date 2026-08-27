//
//  AnalyticsView.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/08/25.
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query private var folders: [Folder]
    @Query private var knowledges: [Knowledge]
    
    // MARK: - Calculated Metrics
    private var totalCards: Int {
        knowledges.count
    }
    
    private var totalReviewedCount: Int {
        knowledges.reduce(0) { $0 + $1.reviewCount }
    }
    
    private var overallAccuracy: Int {
        let totalCorrect = knowledges.reduce(0) { $0 + $1.correctCount }
        guard totalReviewedCount > 0 else { return 0 }
        return Int(round(Double(totalCorrect) / Double(totalReviewedCount) * 100))
    }
    
    private var masteredCount: Int {
        knowledges.filter { $0.masterStatus == .mastered }.count
    }
    
    private var incorrectCount: Int {
        knowledges.filter { $0.masterStatus == .incorrect }.count
    }
    
    private var unreviewedCount: Int {
        knowledges.filter { $0.masterStatus == .unreviewed }.count
    }
    
    private let statusColors: [String: Color] = [
        "Mastered": .green,
        "Needs Review": .red,
        "Unreviewed": Color.gray.opacity(0.4)
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                AdBannerView()

                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Overview Cards
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            MetricCard(title: "Total Records", value: "\(totalCards)", systemImage: "doc.text.fill", color: .blue)
                            MetricCard(title: "Overall Accuracy", value: "\(overallAccuracy)%", systemImage: "target", color: .green)
                            MetricCard(title: "Mastered Cards", value: "\(masteredCount)", systemImage: "checkmark.seal.fill", color: .orange)
                            MetricCard(title: "Total Reviews", value: "\(totalReviewedCount)", systemImage: "arrow.clockwise.circle.fill", color: .purple)
                        }
                        .padding(.horizontal)
                        
                        // MARK: - Mastery Status Chart
                        if !knowledges.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Mastery Distribution")
                                    .font(.headline)
                                
                                Chart {
                                    SectorMark(
                                        angle: .value("Count", masteredCount),
                                        innerRadius: .ratio(0.6),
                                        angularInset: 1.5
                                    )
                                    .foregroundStyle(by: .value("Status", "Mastered"))
                                    
                                    SectorMark(
                                        angle: .value("Count", incorrectCount),
                                        innerRadius: .ratio(0.6),
                                        angularInset: 1.5
                                    )
                                    .foregroundStyle(by: .value("Status", "Needs Review"))
                                    
                                    SectorMark(
                                        angle: .value("Count", unreviewedCount),
                                        innerRadius: .ratio(0.6),
                                        angularInset: 1.5
                                    )
                                    .foregroundStyle(by: .value("Status", "Unreviewed"))
                                }
                                .chartForegroundStyleScale(mapping: { (status: String) -> Color in
                                    statusColors[status] ?? .gray
                                })
                                .frame(height: 180)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                        
                        // MARK: - Database Breakdown List
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Accuracy by Database")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if folders.isEmpty {
                                ContentUnavailableView(
                                    "No Databases",
                                    systemImage: "tray",
                                    description: Text("Create a database to track your accuracy.")
                                )
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(folders) { folder in
                                        FolderAccuracyRow(folder: folder)
                                        if folder.id != folders.last?.id {
                                            Divider()
                                                .padding(.leading, 16)
                                        }
                                    }
                                }
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(16)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
    }
}

// MARK: - Metric Card Component
private struct MetricCard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .bold()
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

// MARK: - Folder Accuracy Row Component
private struct FolderAccuracyRow: View {
    let folder: Folder
    
    private var totalFolderReviews: Int {
        folder.knowledges.reduce(0) { $0 + $1.reviewCount }
    }
    
    private var folderAccuracy: Int {
        let totalCorrect = folder.knowledges.reduce(0) { $0 + $1.correctCount }
        guard totalFolderReviews > 0 else { return 0 }
        return Int(round(Double(totalCorrect) / Double(totalFolderReviews) * 100))
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(folder.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("\(folder.knowledges.count) cards")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(totalFolderReviews > 0 ? "\(folderAccuracy)%" : "N/A")
                    .font(.callout)
                    .bold()
                    .foregroundStyle(totalFolderReviews == 0 ? Color.secondary : (folderAccuracy >= 80 ? Color.green : Color.orange))
                
                Text("Accuracy")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Folder.self, Knowledge.self, configurations: config)
    let context = container.mainContext
    
    // 1. AI & Tech Concepts (高正答率フォルダ)
    let folder1 = Folder(name: "AI & Tech Concepts")
    let k1 = Knowledge(title: "Attention Mechanism", summary: "Calculates dynamic weights for input sequence.", reviewCount: 5, correctCount: 5, masterStatus: .mastered)
    let k2 = Knowledge(title: "Transformer", summary: "Architecture based entirely on attention mechanisms.", reviewCount: 4, correctCount: 4, masterStatus: .mastered)
    let k3 = Knowledge(title: "LLM", summary: "Large Language Model.", reviewCount: 3, correctCount: 2, masterStatus: .mastered)
    folder1.knowledges.append(contentsOf: [k1, k2, k3])
    
    // 2. Financial Indicators (要復習カードあり)
    let folder2 = Folder(name: "Financial Indicators")
    let k4 = Knowledge(title: "ROIC", summary: "Return on Invested Capital", reviewCount: 6, correctCount: 5, masterStatus: .mastered)
    let k5 = Knowledge(title: "PER", summary: "Price to Earnings Ratio", reviewCount: 3, correctCount: 1, masterStatus: .incorrect)
    let k6 = Knowledge(title: "ROE", summary: "Return on Equity", reviewCount: 2, correctCount: 1, masterStatus: .incorrect)
    let k7 = Knowledge(title: "PBR", summary: "Price to Book Ratio", reviewCount: 0, correctCount: 0, masterStatus: .unreviewed)
    folder2.knowledges.append(contentsOf: [k4, k5, k6, k7])
    
    // 3. SAKE DIPLOMA (未レビュー多め)
    let folder3 = Folder(name: "SAKE DIPLOMA")
    let k8 = Knowledge(title: "山田錦", summary: "兵庫県原産の代表的な酒造好適米", reviewCount: 2, correctCount: 2, masterStatus: .mastered)
    let k9 = Knowledge(title: "雄町", summary: "オマチ。岡山県特産の酒米", reviewCount: 0, correctCount: 0, masterStatus: .unreviewed)
    let k10 = Knowledge(title: "協会9号酵母", summary: "熊本酵母。香気成分カプロン酸エチルを多く生成", reviewCount: 0, correctCount: 0, masterStatus: .unreviewed)
    folder3.knowledges.append(contentsOf: [k8, k9, k10])
    
    context.insert(folder1)
    context.insert(folder2)
    context.insert(folder3)
    
    return AnalyticsView()
        .modelContainer(container)
}
