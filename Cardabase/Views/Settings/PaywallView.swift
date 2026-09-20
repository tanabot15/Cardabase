//
//  PaywallView.swift
//  Cardabase
//

import SwiftUI
import StoreKit

/// View representing the Pro upgrade screen and handling StoreKit 2 transactions.
struct PaywallView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var adManager = AdMobManager.shared
    
    @State private var isPurchasing: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Header Icon & Title
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.yellow)
                
                VStack(spacing: 8) {
                    Text("Upgrade to Cardabase Pro")
                        .font(.title)
                        .bold()
                    
                    Text("Unlock unlimited databases, records, data transfer, and enjoy an ad-free study experience.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                
                // Feature Highlights
                VStack(alignment: .leading, spacing: 14) {
                    FeatureRow(icon: "folder.fill", title: "Unlimited Databases", description: "Free tier limited to \(Limits.maxFoldersForFree) databases.")
                    FeatureRow(icon: "doc.text.fill", title: "Unlimited Records", description: "Free tier limited to \(Limits.maxKnowledgesPerFolderForFree) records per database.")
                    FeatureRow(icon: "arrow.triangle.2.circlepath", title: "Data Transfer", description: "Bulk CSV/JSON import & full backup export.")
                    FeatureRow(icon: "nosign", title: "Ad-Free Experience", description: "Remove all banner and interstitial ads.")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Spacer()
                
                // Error Message Display
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: purchasePro) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(appState.isProUser ? "Pro Plan Active" : "Upgrade to Pro")
                                    .bold()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(appState.isProUser ? Color.gray : Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isPurchasing || appState.isProUser)
                    
                    Button("Restore Purchases") {
                        restorePurchases()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .disabled(isPurchasing)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        appState.isShowingPaywall = false
                    }
                    .disabled(isPurchasing)
                }
            }
        }
    }
    
    // MARK: - StoreKit Actions
    private func purchasePro() {
        Task {
            isPurchasing = true
            errorMessage = nil
            defer { isPurchasing = false }
            
            do {
                let products = try await Product.products(for: [Limits.proProductID])
                if let product = products.first {
                    let result = try await product.purchase()
                    switch result {
                    case .success(let verification):
                        if case .verified = verification {
                            await appState.refreshProStatus()
                            appState.isShowingPaywall = false
                        } else {
                            errorMessage = "Transaction verification failed."
                        }
                    case .userCancelled:
                        break
                    case .pending:
                        errorMessage = "Purchase is pending approval."
                    @unknown default:
                        break
                    }
                } else {
                    errorMessage = "Product not found (\(Limits.proProductID)). Please try again later."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            isPurchasing = true
            errorMessage = nil
            defer { isPurchasing = false }
            
            do {
                try await adManager.restorePurchases()
                await appState.refreshProStatus()
                if appState.isProUser {
                    appState.isShowingPaywall = false
                } else {
                    errorMessage = "No active Pro subscription found."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Subview for Feature List Item
private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PaywallView()
        .environmentObject(AppState())
}
