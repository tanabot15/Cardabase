//
//  AppState.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isProUser: Bool = false
    @Published var isShowingPaywall: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        AdMobManager.shared.$isProUser
            .receive(on: DispatchQueue.main)
            .assign(to: &$isProUser)
    }
    
    func refreshProStatus() async {
        await AdMobManager.shared.checkProStatus()
    }
}
