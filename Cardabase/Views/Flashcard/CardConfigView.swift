//
//  CardConfigView.swift
//  Cardabase
//

import SwiftUI
import SwiftData

struct StudySessionConfig: Identifiable {
    let id = UUID()
    let knowledges: [Knowledge]
    let frontKey: String
    let backKey: String
}

struct CardConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var folder: Folder
    
    // MARK: - State Management
    @State private var selectedFrontKey: String = ""
    @State private var selectedBackKey: String = ""
    @State private var onlyUnmastered: Bool = false
    @State private var shuffleCards: Bool = true
    @State private var activeSession: StudySessionConfig? = nil
    
    private var currentTargetKnowledges: [Knowledge] {
        var list = folder.knowledges
        if onlyUnmastered {
            list = list.filter { $0.masterStatus != .mastered }
        }
        return list
    }
    
    // MARK: - Main Body
    var body: some View {
        Form {
            // Field Mapping Section
            Section(header: Text("Card Mapping"), footer: Text("Select which field to display on the front and back of the flashcard.")) {
                Picker("Front (Question)", selection: $selectedFrontKey) {
                    ForEach(folder.availableFieldKeys, id: \.self) { key in
                        Text(key).tag(key)
                    }
                }
                
                Picker("Back (Answer)", selection: $selectedBackKey) {
                    ForEach(folder.availableFieldKeys, id: \.self) { key in
                        Text(key).tag(key)
                    }
                }
            }
            
            // Study Options Section
            Section(header: Text("Study Options")) {
                Toggle("Only Unmastered Cards", isOn: $onlyUnmastered)
                Toggle("Shuffle Cards", isOn: $shuffleCards)
            }
            
            // Start Study Button Section
            Section {
                Button(action: startStudy) {
                    HStack {
                        Spacer()
                        Image(systemName: "play.fill")
                        Text("Start Study (\(currentTargetKnowledges.count) Cards)")
                            .bold()
                        Spacer()
                    }
                }
                .disabled(currentTargetKnowledges.isEmpty)
            }
        }
        .navigationTitle("Study Setup")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedFrontKey.isEmpty {
                selectedFrontKey = folder.defaultFrontKey
            }
            if selectedBackKey.isEmpty {
                selectedBackKey = folder.defaultBackKey
            }
        }
        .fullScreenCover(item: $activeSession) { session in
            FlashcardView(
                folder: folder,
                knowledges: session.knowledges,
                frontKey: session.frontKey,
                backKey: session.backKey,
                onDone: { dismiss() }
            )
        }
    }
    
    // MARK: - Actions
    
    private func startStudy() {
        folder.defaultFrontKey = selectedFrontKey
        folder.defaultBackKey = selectedBackKey
        
        var list = folder.knowledges
        if onlyUnmastered {
            list = list.filter { $0.masterStatus != .mastered }
        }
        
        let preparedList: [Knowledge]
        if shuffleCards {
            preparedList = list.shuffled()
        } else {
            preparedList = list.sorted { $0.createdAt > $1.createdAt }
        }
        
        self.activeSession = StudySessionConfig(
            knowledges: preparedList,
            frontKey: selectedFrontKey,
            backKey: selectedBackKey
        )
    }
}

// MARK: - Preview

#Preview {
    let folder = Folder(name: "SAKE DIPLOMA Prep")
    folder.knowledges.append(Knowledge(title: "Yamada Nishiki", summary: "King of Sake Rice produced mainly in Hyogo Pref."))
    return NavigationStack {
        CardConfigView(folder: folder)
    }
    .modelContainer(for: [Folder.self, Knowledge.self], inMemory: true)
}
