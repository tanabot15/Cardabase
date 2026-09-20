//
//  FlashcardView.swift
//  Cardabase
//

import SwiftUI
import SwiftData

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
    @State private var isCompleted: Bool = false
    
    private var currentKnowledge: Knowledge? {
        guard currentIndex < knowledges.count else { return nil }
        return knowledges[currentIndex]
    }
    
    // MARK: - Main Body
    var body: some View {
        VStack(spacing: 16) {
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
                ZStack {
                    // Front Card (Question)
                    CardFrontFaceView(
                        title: frontKey,
                        content: knowledge.value(forKey: frontKey) ?? "(Empty)"
                    )
                    .opacity(isFlipped ? 0.0 : 1.0)
                    .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0.0, y: 1.0, z: 0.0))
                    
                    // Back Card (Answer)
                    CardBackFaceView(
                        frontTitle: frontKey,
                        frontContent: knowledge.value(forKey: frontKey) ?? "(Empty)",
                        backTitle: backKey,
                        backContent: knowledge.value(forKey: backKey) ?? "(Empty)"
                    )
                    .opacity(isFlipped ? 1.0 : 0.0)
                    .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0.0, y: 1.0, z: 0.0))
                }
                .frame(maxWidth: .infinity, maxHeight: 380)
                .padding(.horizontal)
                .onTapGesture {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
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
        .fullScreenCover(isPresented: $isCompleted) {
            StudyResultView(
                folder: folder,
                totalStudied: knowledges.count,
                correctCount: correctCount,
                incorrectCount: incorrectCount,
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
        
        let nextCorrect = correctCount + (isCorrect ? 1 : 0)
        let nextIncorrect = incorrectCount + (isCorrect ? 0 : 1)
        
        knowledge.reviewCount += 1
        if isCorrect {
            knowledge.correctCount += 1
            knowledge.masterStatus = .mastered
        } else {
            knowledge.masterStatus = .incorrect
        }
        knowledge.lastReviewedAt = Date()
        
        self.correctCount = nextCorrect
        self.incorrectCount = nextIncorrect
        
        if currentIndex + 1 < knowledges.count {
            withAnimation {
                isFlipped = false
                currentIndex += 1
            }
        } else {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 50_000_000)
                isCompleted = true
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
            Text(title.uppercased())
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
                        Text(frontTitle.uppercased())
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
                        .padding(.vertical, 4)
                    
                    VStack(spacing: 8) {
                        Text(backTitle.uppercased())
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
