//
//  AdMobManager.swift
//  Cardabase
//

import Foundation
import Combine
import StoreKit

/// Manager singleton responsible for AdMob configuration and entitlement checking.
@MainActor
final class AdMobManager: ObservableObject {
    static let shared = AdMobManager()
    
    @Published var isProUser: Bool = false
    
    let bannerAdUnitID: String
    
    private init() {
        #if DEBUG
        // Default Google AdMob Test Banner ID
        self.bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
        #else
        if let path = Bundle.main.path(forResource: "AdMobConfig", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
           let adUnitID = dict["BannerAdUnitID"] as? String, !adUnitID.isEmpty {
            self.bannerAdUnitID = adUnitID
        } else {
            self.bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
        }
        #endif
        
        Task {
            await checkProStatus()
        }
    }
    
    /// Verifies current StoreKit 2 entitlement status.
    func checkProStatus() async {
        var hasActivePro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Limits.proProductID && transaction.revocationDate == nil {
                    hasActivePro = true
                    break
                }
            }
        }
        self.isProUser = hasActivePro
    }
    
    /// Syncs transactions with App Store.
    func restorePurchases() async throws {
        try await AppStore.sync()
        await checkProStatus()
    }
}
