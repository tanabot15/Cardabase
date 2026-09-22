//
//  FlashcardView.swift
//  Cardabase
//

import SwiftUI
import SwiftData

struct StudyResultData: Identifiable {
    let id = UUID()
    let mode: StudyMode
    let totalCards: Int
    let firstTryCorrectCount: Int
    let totalAttempts: Int
    let correctCount: Int
    let incorrectCount: Int
}

struct FlashcardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    let folder: Folder
    let initialKnowledges: [Knowledge]
    let frontKey: String
    let backKey: String
    let mode: StudyMode
    
    var onDone: (() -> Void)? = nil
    
    // MARK: - State Management
    @State private var cardQueue: [Knowledge] = []
    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    
    // Test mode tracking
    @State private var testCorrectCount: Int = 0
    @State private var testIncorrectCount: Int = 0
    
    // Memorization mode tracking
    @State private var failedCardIDs: Set<UUID> = []
    @State private var totalAttempts: Int = 0
    
    @State private var resultData: StudyResultData? = nil
    
    init(folder: Folder, knowledges: [Knowledge], frontKey: String, backKey: String, mode: StudyMode, onDone: (() -> Void)? = nil) {
        self.folder = folder
        self.initialKnowledges = knowledges
        self.frontKey = frontKey
        self.backKey = backKey
        self.mode = mode
        self.onDone = onDone
        _cardQueue = State(initialValue: knowledges)
    }
    
    private var currentKnowledge: Knowledge? {
        guard currentIndex < cardQueue.count else { return nil }
        return cardQueue[currentIndex]
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
                
                VStack(spacing: 2) {
                    Text(folder.name)
                        .font(.headline)
                        .lineLimit(1)
                    Text(mode.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("Exit").opacity(0)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            if !appState.isProUser {
                AdBannerView()
            }
            
            // Progress Bar & Counter
            ProgressView(value: Double(currentIndex), total: Double(cardQueue.count))
                .padding(.horizontal)
            
            HStack {
                if mode == .memorization {
                    Text("Remaining: \(cardQueue.count - currentIndex) Cards")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Card \(currentIndex + 1) of \(cardQueue.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
                    } else {
                        CardFrontFaceView(
                            title: frontKey,
                            content: frontText
                        )
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
                resultData: result,
                onRestart: {
                    cardQueue = initialKnowledges.shuffled()
                    currentIndex = 0
                    testCorrectCount = 0
                    testIncorrectCount = 0
                    failedCardIDs.removeAll()
                    totalAttempts = 0
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
        
        totalAttempts += 1
        knowledge.reviewCount += 1
        knowledge.lastReviewedAt = Date()
        
        if mode == .memorization {
            if isCorrect {
                knowledge.correctCount += 1
                knowledge.masterStatus = .mastered
            } else {
                knowledge.masterStatus = .incorrect
                failedCardIDs.insert(knowledge.id)
                // Append failed card back to the queue end
                cardQueue.append(knowledge)
            }
        } else { // Test Mode
            if isCorrect {
                knowledge.correctCount += 1
                knowledge.masterStatus = .mastered
                testCorrectCount += 1
            } else {
                knowledge.masterStatus = .incorrect
                testIncorrectCount += 1
            }
        }
        
        if currentIndex + 1 < cardQueue.count {
            withAnimation {
                isFlipped = false
                currentIndex += 1
            }
        } else {
            let finalData: StudyResultData
            if mode == .memorization {
                let firstTryCorrect = initialKnowledges.count - failedCardIDs.count
                finalData = StudyResultData(
                    mode: .memorization,
                    totalCards: initialKnowledges.count,
                    firstTryCorrectCount: max(0, firstTryCorrect),
                    totalAttempts: totalAttempts,
                    correctCount: initialKnowledges.count,
                    incorrectCount: failedCardIDs.count
                )
            } else {
                finalData = StudyResultData(
                    mode: .test,
                    totalCards: initialKnowledges.count,
                    firstTryCorrectCount: testCorrectCount,
                    totalAttempts: initialKnowledges.count,
                    correctCount: testCorrectCount,
                    incorrectCount: testIncorrectCount
                )
            }
            
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
            Text("Question : (\(title.uppercased()))")
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
                        Text("Question : (\(frontTitle.uppercased()))")
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
                        Text("Answer : (\(backTitle.uppercased()))")
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
    return FlashcardView(
        folder: folder,
        knowledges: [k1],
        frontKey: "Title",
        backKey: "Summary",
        mode: .memorization
    )
    .environmentObject(AppState())
    .modelContainer(for: [Folder.self, Knowledge.self], inMemory: true)
}
