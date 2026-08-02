//
//  AdBannerView.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import SwiftUI
import GoogleMobileAds

// MARK: - AdMob View Wrapper (UIViewRepresentable)
struct BannerAdRepresentable: UIViewRepresentable {
    let adUnitID: String
    
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootVC
        }
        
        bannerView.load(Request())
        return bannerView
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) { }
}

// MARK: - SwiftUI AdBannerView Component
struct AdBannerView: View {
    @StateObject private var adManager = AdMobManager.shared
    
    var body: some View {
        if adManager.isProUser {
            EmptyView()
        } else {
            HStack {
                Spacer()
                BannerAdRepresentable(adUnitID: adManager.bannerAdUnitID)
                    .frame(width: 320, height: 50)
                Spacer()
            }
            .frame(height: 50)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    AdBannerView()
}
