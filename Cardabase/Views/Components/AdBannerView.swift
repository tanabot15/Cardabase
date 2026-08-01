//
//  AdBannerView.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import SwiftUI

struct AdBannerView: View {
    @StateObject private var adManager = AdMobManager.shared
    
    var body: some View {
        if adManager.isProUser {
            EmptyView()
        } else {
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Text("AdBanner Area")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    Text("ID: \(adManager.bannerAdUnitID)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
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
