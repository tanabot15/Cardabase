//
//  AdMobManager.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import Foundation
import Combine
import StoreKit

@MainActor
final class AdMobManager: ObservableObject {
    static let shared = AdMobManager()
    
    @Published var isProUser: Bool = false
    
    // AdMob Unit ID
    #if DEBUG
    let bannerAdUnitID: String = "ca-app-pub-3940256099942544/2934735716"
    #else
    // Replace with production ID
    let bannerAdUnitID: String = "ca-app-pub-3940256099942544/2934735716"
    #endif
    
    private init() {
        Task {
            await checkProStatus()
        }
    }
    
    // StoreKit 2
    func checkProStatus() async {
        var hasActivePro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == "com.cardabase.pro" && transaction.revocationDate == nil {
                    hasActivePro = true
                    break
                }
            }
        }
        self.isProUser = hasActivePro
    }
    
    // restore purchases
    func restorePurchases() async throws {
        try await AppStore.sync()
        await checkProStatus()
    }
}
