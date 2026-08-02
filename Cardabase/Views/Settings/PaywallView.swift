//
//  PaywallView.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

// for Pro
//import SwiftUI
//import StoreKit
//
//struct PaywallView: View {
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var adManager = AdMobManager.shared
//    
//    @State private var isPurchasing: Bool = false
//    @State private var errorMessage: String?
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 24) {
//                Spacer()
//                
//                // icon
//                Image(systemName: "star.circle.fill")
//                    .font(.system(size: 80))
//                    .foregroundStyle(.yellow)
//                
//                VStack(spacing: 8) {
//                    Text("Upgrade to Cardabase Pro")
//                        .font(.title)
//                        .bold()
//                        .foregroundStyle(.primary)
//                    
//                    Text("Unlock unlimited databases, records, and enjoy an ad-free experience.")
//                        .font(.subheadline)
//                        .multilineTextAlignment(.center)
//                        .foregroundStyle(.secondary)
//                        .padding(.horizontal)
//                }
//                
//                // compare list
//                VStack(alignment: .leading, spacing: 14) {
//                    FeatureRow(icon: "folder.fill", title: "Unlimited Databases", description: "Free version is limited to 3 databases.")
//                    FeatureRow(icon: "doc.text.fill", title: "Unlimited Records", description: "Free version is limited to 50 records per database.")
//                    FeatureRow(icon: "nosign", title: "Remove All Ads", description: "Enjoy a clean, distraction-free study environment.")
//                }
//                .padding()
//                .background(Color(.secondarySystemBackground))
//                .cornerRadius(16)
//                .padding(.horizontal)
//                
//                Spacer()
//                
//                if let errorMessage = errorMessage {
//                    Text(errorMessage)
//                        .font(.caption)
//                        .foregroundStyle(.red)
//                }
//                
//                // buy action
//                VStack(spacing: 12) {
//                    Button(action: purchasePro) {
//                        HStack {
//                            if isPurchasing {
//                                ProgressView()
//                                    .tint(.white)
//                            } else {
//                                Text("Upgrade for $4.99 (One-Time)")
//                                    .bold()
//                            }
//                        }
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.accentColor)
//                        .foregroundStyle(.white)
//                        .cornerRadius(12)
//                    }
//                    .disabled(isPurchasing || adManager.isProUser)
//                    
//                    Button("Restore Purchases") {
//                        restorePurchases()
//                    }
//                    .font(.subheadline)
//                    .foregroundStyle(.secondary)
//                }
//                .padding(.horizontal, 24)
//                .padding(.bottom, 16)
//            }
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Close") { dismiss() }
//                }
//            }
//        }
//    }
//    
//    // MARK: - StoreKit Actions
//    private func purchasePro() {
//        Task {
//            isPurchasing = true
//            errorMessage = nil
//            do {
//                // purchase request
//                let products = try await Product.products(for: ["com.cardabase.pro"])
//                if let product = products.first {
//                    let result = try await product.purchase()
//                    switch result {
//                    case .success(let verification):
//                        if case .verified = verification {
//                            await adManager.checkProStatus()
//                            dismiss()
//                        }
//                    case .userCancelled:
//                        break
//                    case .pending:
//                        errorMessage = "Purchase is pending approval."
//                    @unknown default:
//                        break
//                    }
//                } else {
//                    adManager.isProUser = true
//                    dismiss()
//                }
//            } catch {
//                errorMessage = error.localizedDescription
//            }
//            isPurchasing = false
//        }
//    }
//    
//    private func restorePurchases() {
//        Task {
//            isPurchasing = true
//            errorMessage = nil
//            do {
//                try await adManager.restorePurchases()
//                if adManager.isProUser {
//                    dismiss()
//                } else {
//                    errorMessage = "No active Pro purchase found."
//                }
//            } catch {
//                errorMessage = error.localizedDescription
//            }
//            isPurchasing = false
//        }
//    }
//}
//
//private struct FeatureRow: View {
//    let icon: String
//    let title: String
//    let description: String
//    
//    var body: some View {
//        HStack(spacing: 14) {
//            Image(systemName: icon)
//                .font(.title2)
//                .foregroundStyle(Color.accentColor)
//                .frame(width: 32)
//            
//            VStack(alignment: .leading, spacing: 2) {
//                Text(title)
//                    .font(.headline)
//                    .foregroundStyle(.primary)
//                Text(description)
//                    .font(.caption)
//                    .foregroundStyle(.secondary)
//            }
//        }
//    }
//}
//
//#Preview {
//    PaywallView()
//}
