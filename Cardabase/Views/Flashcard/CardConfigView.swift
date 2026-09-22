//
//  CardConfigView.swift
//  Cardabase
//

import SwiftUI
import SwiftData

enum StudyMode: String, Codable, CaseIterable, Identifiable {
    case memorization
    case test
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .memorization: return "Memorization"
        case .test: return "Test"
        }
    }
    
    var description: String {
        switch self {
        case .memorization: return "Repeat incorrect cards until every card is answered correctly."
        case .test: return "Go through all cards once and test your knowledge."
        }
    }
}

struct StudySessionConfig: Identifiable {
    let id = UUID()
    let knowledges: [Knowledge]
    let frontKey: String
    let backKey: String
    let mode: StudyMode
}

struct CardConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var folder: Folder
    
    // MARK: - State Management
    @State private var selectedFrontKey: String = ""
    @State private var selectedBackKey: String = ""
    @State private var selectedMode: StudyMode = .memorization
    @State private var activeSession: StudySessionConfig? = nil
    
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
            
            // Study Mode Section
            Section(header: Text("Study Mode"), footer: Text(selectedMode.description)) {
                Picker("Mode", selection: $selectedMode) {
                    ForEach(StudyMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Start Study Button Section
            Section {
                Button(action: startStudy) {
                    HStack {
                        Spacer()
                        Image(systemName: "play.fill")
                        Text("Start Study (\(folder.knowledges.count) Cards)")
                            .bold()
                        Spacer()
                    }
                }
                .disabled(folder.knowledges.isEmpty)
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
                mode: session.mode,
                onDone: { dismiss() }
            )
        }
    }
    
    // MARK: - Actions
    
    private func startStudy() {
        folder.defaultFrontKey = selectedFrontKey
        folder.defaultBackKey = selectedBackKey
        
        // Always shuffle cards at start
        let preparedList = folder.knowledges.shuffled()
        
        self.activeSession = StudySessionConfig(
            knowledges: preparedList,
            frontKey: selectedFrontKey,
            backKey: selectedBackKey,
            mode: selectedMode
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
