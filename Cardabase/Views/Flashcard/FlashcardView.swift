//
//  FlashcardView.swift
//  Cardabase
//

import SwiftUI
import SwiftData

struct StudyResultData: Identifiable {
    let id = UUID()
    let totalStudied: Int
    let correctCount: Int
    let incorrectCount: Int
}

struct FlashcardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    let folder: Folder
    let knowledges: [Knowledge]
    let frontKey: String
    let backKey: String
    
    var onDone: (() -> Void)? = nil
    
    // MARK: - State Management
    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    @State private var correctCount: Int = 0
    @State private var incorrectCount: Int = 0
    
    @State private var resultData: StudyResultData? = nil
    
    private var currentKnowledge: Knowledge? {
        guard currentIndex < knowledges.count else { return nil }
        return knowledges[currentIndex]
    }
    
    private func getValue(for key: String, from knowledge: Knowledge) -> String {
        if key == "Title" {
            return knowledge.title.isEmpty ? "(Empty)" : knowledge.title
        } else if key == "Summary" {
            return knowledge.summary.isEmpty ? "(Empty)" : knowledge.summary
        } else if let customVal = knowledge.value(forKey: key), !customVal.isEmpty {
            return customVal
        }
        return "(Empty)"
    }
    
    // MARK: - Main Body
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Button("Exit") { dismiss() }
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text(folder.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text("Exit").opacity(0)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            if !appState.isProUser {
                AdBannerView()
            }
            
            // Progress Bar & Counter
            ProgressView(value: Double(currentIndex), total: Double(knowledges.count))
                .padding(.horizontal)
            
            HStack {
                Text("Card \(currentIndex + 1) of \(knowledges.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Card Flip View
            if let knowledge = currentKnowledge {
                let frontText = getValue(for: frontKey, from: knowledge)
                let backText = getValue(for: backKey, from: knowledge)
                
                ZStack {
                    if isFlipped {
                        CardBackFaceView(
                            frontTitle: frontKey,
                            frontContent: frontText,
                            backTitle: backKey,
                            backContent: backText
                        )
                        .rotation3DEffect(.degrees(0), axis: (x: 0.0, y: 1.0, z: 0.0))
                    } else {
                        CardFrontFaceView(
                            title: frontKey,
                            content: frontText
                        )
                        .rotation3DEffect(.degrees(0), axis: (x: 0.0, y: 1.0, z: 0.0))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 380)
                .padding(.horizontal)
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        isFlipped.toggle()
                    }
                }
            }
            
            Spacer()
            
            // Action Buttons
            if isFlipped {
                HStack(spacing: 20) {
                    Button(action: { recordAnswer(isCorrect: false) }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Incorrect")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                    
                    Button(action: { recordAnswer(isCorrect: true) }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Correct")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Text("Tap card to reveal answer")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 10)
            }
        }
        .fullScreenCover(item: $resultData) { result in
            StudyResultView(
                folder: folder,
                totalStudied: result.totalStudied,
                correctCount: result.correctCount,
                incorrectCount: result.incorrectCount,
                onRestart: {
                    currentIndex = 0
                    correctCount = 0
                    incorrectCount = 0
                    isFlipped = false
                },
                onDone: {
                    dismiss()
                    onDone?()
                }
            )
        }
    }
    
    // MARK: - Logic
    
    private func recordAnswer(isCorrect: Bool) {
        guard let knowledge = currentKnowledge else { return }
        
        let updatedCorrect = correctCount + (isCorrect ? 1 : 0)
        let updatedIncorrect = incorrectCount + (isCorrect ? 0 : 1)
        
        knowledge.reviewCount += 1
        if isCorrect {
            knowledge.correctCount += 1
            knowledge.masterStatus = .mastered
        } else {
            knowledge.masterStatus = .incorrect
        }
        knowledge.lastReviewedAt = Date()
        
        self.correctCount = updatedCorrect
        self.incorrectCount = updatedIncorrect
        
        if currentIndex + 1 < knowledges.count {
            withAnimation {
                isFlipped = false
                currentIndex += 1
            }
        } else {
            let finalData = StudyResultData(
                totalStudied: knowledges.count,
                correctCount: updatedCorrect,
                incorrectCount: updatedIncorrect
            )
            
            DispatchQueue.main.async {
                self.resultData = finalData
            }
        }
    }
}

// MARK: - Subviews: Card Faces

private struct CardFrontFaceView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Question")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(6)
            
            Spacer()
            
            ScrollView(.vertical, showsIndicators: false) {
                Text(content)
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

private struct CardBackFaceView: View {
    let frontTitle: String
    let frontContent: String
    let backTitle: String
    let backContent: String
    
    var body: some View {
        VStack(spacing: 12) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    VStack(spacing: 6) {
                        Text("Question")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        
                        Text(frontContent)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 4)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    VStack(spacing: 8) {
                        Text("Answer")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(6)
                        
                        Text(backContent)
                            .font(.title3)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.primary)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    let folder = Folder(name: "Sample Database")
    let k1 = Knowledge(title: "SwiftUI", summary: "Declarative UI framework for iOS development.")
    return FlashcardView(folder: folder, knowledges: [k1], frontKey: "Title", backKey: "Summary")
        .environmentObject(AppState())
        .modelContainer(for: [Folder.self, Knowledge.self], inMemory: true)
}
