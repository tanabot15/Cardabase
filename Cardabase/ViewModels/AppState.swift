//
//  AppState.swift
//  Cardabase
//

import SwiftUI
import Combine

/// Global application state handling subscription status and paywall presentations.
@MainActor
final class AppState: ObservableObject {
    @Published var isProUser: Bool = false
    @Published var isShowingPaywall: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Observe Pro subscription updates from AdMobManager
        AdMobManager.shared.$isProUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPro in
                self?.isProUser = isPro
            }
            .store(in: &cancellables)
    }
    
    /// Refreshes the active subscription status via StoreKit.
    func refreshProStatus() async {
        await AdMobManager.shared.checkProStatus()
        self.isProUser = AdMobManager.shared.isProUser
    }
}
