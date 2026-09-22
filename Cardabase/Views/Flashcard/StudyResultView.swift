//
//  StudyResultView.swift
//  Cardabase
//

import SwiftUI
import SwiftData

struct StudyResultView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    let folder: Folder
    let resultData: StudyResultData
    
    var onRestart: (() -> Void)? = nil
    var onDone: (() -> Void)? = nil
    
    private var testAccuracyRate: Int {
        guard resultData.totalCards > 0 else { return 0 }
        return Int(round(Double(resultData.correctCount) / Double(resultData.totalCards) * 100))
    }
    
    private var memorizationFirstTryRate: Int {
        guard resultData.totalCards > 0 else { return 0 }
        return Int(round(Double(resultData.firstTryCorrectCount) / Double(resultData.totalCards) * 100))
    }
    
    // MARK: - Main Body
    var body: some View {
        VStack(spacing: 24) {
            if !appState.isProUser {
                AdBannerView()
            }
            
            Spacer()
            
            // Result Icon & Main Title
            if resultData.mode == .memorization {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(.green)
                
                VStack(spacing: 8) {
                    Text("All Cards Mastered!")
                        .font(.title)
                        .bold()
                        .foregroundStyle(.primary)
                    
                    Text("You completed all cards in '\(folder.name)'")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Image(systemName: testAccuracyRate >= 80 ? "trophy.fill" : "checkmark.seal.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(testAccuracyRate >= 80 ? .yellow : Color.accentColor)
                
                VStack(spacing: 8) {
                    Text("Test Completed!")
                        .font(.title)
                        .bold()
                        .foregroundStyle(.primary)
                    
                    Text("Great job testing '\(folder.name)'")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Score Cards Grid
            HStack(spacing: 16) {
                if resultData.mode == .memorization {
                    ResultStatBox(
                        title: "First Try Rate",
                        value: "\(memorizationFirstTryRate)%",
                        color: .blue
                    )
                    ResultStatBox(
                        title: "Total Reviews",
                        value: "\(resultData.totalAttempts)",
                        color: .purple
                    )
                    ResultStatBox(
                        title: "Cards Cleared",
                        value: "\(resultData.totalCards)",
                        color: .green
                    )
                } else {
                    ResultStatBox(
                        title: "Accuracy",
                        value: "\(testAccuracyRate)%",
                        color: .blue
                    )
                    ResultStatBox(
                        title: "Correct",
                        value: "\(resultData.correctCount)",
                        color: .green
                    )
                    ResultStatBox(
                        title: "Incorrect",
                        value: "\(resultData.incorrectCount)",
                        color: .red
                    )
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 24) {
                Button(action: resetAndRestart) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Restart")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.red)
                    .cornerRadius(12)
                }
                
                Button(action: handleDone) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                        Text("Done")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Actions
    
    private func resetAndRestart() {
        for knowledge in folder.knowledges {
            knowledge.masterStatus = .unreviewed
        }
        
        dismiss()
        onRestart?()
    }
    
    private func handleDone() {
        dismiss()
        onDone?()
    }
}

// MARK: - Subview: Stat Box

private struct ResultStatBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.title2)
                .bold()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview("Memorization Result") {
    let folder = Folder(name: "SAKE DIPLOMA Prep")
    let data = StudyResultData(
        mode: .memorization,
        totalCards: 10,
        firstTryCorrectCount: 7,
        totalAttempts: 14,
        correctCount: 10,
        incorrectCount: 3
    )
    return StudyResultView(folder: folder, resultData: data)
        .environmentObject(AppState())
}

#Preview("Test Result") {
    let folder = Folder(name: "SAKE DIPLOMA Prep")
    let data = StudyResultData(
        mode: .test,
        totalCards: 10,
        firstTryCorrectCount: 8,
        totalAttempts: 10,
        correctCount: 8,
        incorrectCount: 2
    )
    return StudyResultView(folder: folder, resultData: data)
        .environmentObject(AppState())
}
