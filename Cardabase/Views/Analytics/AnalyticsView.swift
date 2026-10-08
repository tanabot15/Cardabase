//
//  AnalyticsView.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/08/25.
//

import SwiftUI
import SwiftData

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
    
    private var streakInfo: (currentStreak: Int, weeklyDays: Int) {
        calculateStreak(from: knowledges)
    }
    
    // MARK: - Main Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AdBannerView()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Overview Metrics Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Overview")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                // Streak Card
                                StreakBannerCard(
                                    streak: streakInfo.currentStreak,
                                    weeklyDays: streakInfo.weeklyDays
                                )
                                
                                // Metric Grid
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    MetricCard(title: "Total Records", value: "\(totalCards)", systemImage: "doc.text.fill", color: .blue)
                                    MetricCard(title: "Accuracy", value: "\(overallAccuracy)%", systemImage: "target", color: .green)
                                    MetricCard(title: "Mastered", value: "\(masteredCount)", systemImage: "checkmark.seal.fill", color: .orange)
                                    MetricCard(title: "Total Reviews", value: "\(totalReviewedCount)", systemImage: "arrow.clockwise.circle.fill", color: .purple)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // 2. Activity Heatmap Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Study Activity")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ActivityHeatmapCard(knowledges: knowledges)
                                .padding(.horizontal)
                        }
                        
                        // 3. Accuracy Breakdown List by Database Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Accuracy by Database")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if folders.isEmpty {
                                ContentUnavailableView(
                                    "No Databases",
                                    systemImage: "tray",
                                    description: Text("Create a database to track your learning performance.")
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
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Streak Logic Helper
    private func calculateStreak(from knowledges: [Knowledge]) -> (currentStreak: Int, weeklyDays: Int) {
        let calendar = Calendar.current
        let now = Date()
        
        let reviewDates = Set(knowledges.compactMap { knowledge -> Date? in
            guard let date = knowledge.lastReviewedAt else { return nil }
            return calendar.startOfDay(for: date)
        })
        
        guard !reviewDates.isEmpty else { return (0, 0) }
        
        let weeklyDays = reviewDates.filter { date in
            calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        }.count
        
        var streak = 0
        var checkDate = calendar.startOfDay(for: now)
        
        if !reviewDates.contains(checkDate) {
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate),
               reviewDates.contains(yesterday) {
                checkDate = yesterday
            } else {
                return (0, weeklyDays)
            }
        }
        
        while reviewDates.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }
        
        return (streak, weeklyDays)
    }
}

// MARK: - Subviews: Activity Heatmap Component
private struct ActivityHeatmapCard: View {
    let knowledges: [Knowledge]
    
    // Past 12 weeks (84 days)
    private let weeksCount = 12
    private let daysPerWeek = 7
    private let cellSize: CGFloat = 16.0
    private let cellSpacing: CGFloat = 5.0
    
    private var dailyReviewCounts: [Date: Int] {
        let calendar = Calendar.current
        var counts: [Date: Int] = [:]
        
        for knowledge in knowledges {
            if let lastDate = knowledge.lastReviewedAt {
                let dayStart = calendar.startOfDay(for: lastDate)
                counts[dayStart, default: 0] += max(1, knowledge.reviewCount)
            }
        }
        return counts
    }
    
    private var dateGrid: [[Date]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return []
        }
        
        var grid: [[Date]] = []
        
        for weekIndex in (0..<weeksCount).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekIndex, to: currentWeekStart) else { continue }
            var weekDates: [Date] = []
            
            for dayIndex in 0..<daysPerWeek {
                if let date = calendar.date(byAdding: .day, value: dayIndex, to: weekStart) {
                    weekDates.append(date)
                }
            }
            grid.append(weekDates)
        }
        
        return grid
    }
    
    private var activeDaysCount: Int {
        dailyReviewCounts.filter { $0.value > 0 }.count
    }
    
    private var totalPeriodReviews: Int {
        dailyReviewCounts.values.reduce(0, +)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Stats
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last 12 Weeks")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Text("\(activeDaysCount) Active Days")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total Activity")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Text("\(totalPeriodReviews) Cards")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                }
            }
            
            // Heatmap Grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: cellSpacing) {
                    // Day of week labels (セルと完全に高さを同期)
                    VStack(spacing: cellSpacing) {
                        Group {
                            Text("M")
                            Text("T")
                            Text("W")
                            Text("T")
                            Text("F")
                            Text("S")
                            Text("S")
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 12, height: cellSize) // セルと同じ高さ(16pt)に揃える
                    }
                    .padding(.trailing, 4)
                    
                    // Grid Columns (Weeks)
                    ForEach(Array(dateGrid.enumerated()), id: \.offset) { _, weekDates in
                        VStack(spacing: cellSpacing) {
                            ForEach(weekDates, id: \.self) { date in
                                let count = dailyReviewCounts[date] ?? 0
                                CellView(count: count, isFuture: date > Date(), cellSize: cellSize)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Legend Bar
            HStack {
                Spacer()
                HStack(spacing: 5) {
                    Text("Less")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    CellView(count: 0, isFuture: false, cellSize: 10)
                    CellView(count: 2, isFuture: false, cellSize: 10)
                    CellView(count: 5, isFuture: false, cellSize: 10)
                    CellView(count: 10, isFuture: false, cellSize: 10)
                    
                    Text("More")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Subviews: Heatmap Single Cell Component
private struct CellView: View {
    let count: Int
    let isFuture: Bool
    var cellSize: CGFloat = 16.0 // Increased cell size from 12 to 16
    
    private var color: Color {
        if isFuture {
            return Color.clear
        }
        switch count {
        case 0:
            return Color(.systemGray5)
        case 1...3:
            return Color.green.opacity(0.35)
        case 4...8:
            return Color.green.opacity(0.65)
        default:
            return Color.green
        }
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color)
            .frame(width: cellSize, height: cellSize)
    }
}

// MARK: - Subviews: Streak Banner Component
private struct StreakBannerCard: View {
    let streak: Int
    let weeklyDays: Int
    
    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(streak) \(streak == 1 ? "Day" : "Days")")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.primary)
                    
                    Text("Current Streak")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Divider()
                .frame(height: 36)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(weeklyDays)")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.primary)
                    Text("/ 7 days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text("This Week")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(streak > 0 ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Subviews: Metric Card Component

private struct MetricCard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .bold()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Subviews: Folder Accuracy Row Component
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

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Folder.self, Knowledge.self, configurations: config)
    let context = container.mainContext
    
    let folder1 = Folder(name: "SAKE DIPLOMA")
    let k1 = Knowledge(title: "Yamada Nishiki", summary: "Premier sake rice variety", reviewCount: 5, correctCount: 5, masterStatus: .mastered, lastReviewedAt: Date())
    let k2 = Knowledge(title: "Gohyakumangoku", summary: "Crisp and clean sake rice", reviewCount: 4, correctCount: 3, masterStatus: .mastered, lastReviewedAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()))
    folder1.knowledges.append(contentsOf: [k1, k2])
    
    let folder2 = Folder(name: "Financial Indicators")
    let k3 = Knowledge(title: "ROIC", summary: "Return on Invested Capital", reviewCount: 6, correctCount: 5, masterStatus: .mastered, lastReviewedAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()))
    let k4 = Knowledge(title: "PER", summary: "Price to Earnings Ratio", reviewCount: 3, correctCount: 1, masterStatus: .incorrect, lastReviewedAt: Calendar.current.date(byAdding: .day, value: -12, to: Date()))
    folder2.knowledges.append(contentsOf: [k3, k4])
    
    context.insert(folder1)
    context.insert(folder2)
    
    return AnalyticsView()
        .modelContainer(container)
}
