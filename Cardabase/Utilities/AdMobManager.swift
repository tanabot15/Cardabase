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
    let bannerAdUnitID: String
    
    private init() {
        #if DEBUG
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
        
        // for Pro
//        Task {
//            await checkProStatus()
//        }
    }
    
    // StoreKit 2
    func checkProStatus() async {
        // for Pro
//        var hasActivePro = false
//        for await result in Transaction.currentEntitlements {
//            if case .verified(let transaction) = result {
//                if transaction.productID == "com.cardabase.pro" && transaction.revocationDate == nil {
//                    hasActivePro = true
//                    break
//                }
//            }
//        }
//        self.isProUser = hasActivePro
        
        // delete for Pro
        self.isProUser = false
    }
    
    // restore purchases
    func restorePurchases() async throws {
        // for Pro
//        try await AppStore.sync()
//        await checkProStatus()
    }
}
