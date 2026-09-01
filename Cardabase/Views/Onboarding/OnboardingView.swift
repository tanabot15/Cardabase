//
//  OnboardingView.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/08/31.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isFirstLaunch: Bool
    
    @State private var currentPage = 0
    @State private var loadSampleData = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Page View
            TabView(selection: $currentPage) {
                // Page 1: Concept
                OnboardingPageView(
                    imageName: "cylinder.split.1x2.fill",
                    title: "Custom Database",
                    description: "Build flexible databases tailored to your unique learning needs with fully customizable fields."
                )
                .tag(0)
                
                // Page 2: Flashcards
                OnboardingPageView(
                    imageName: "rectangle.on.rectangle.angled.fill",
                    title: "Smart Flashcards",
                    description: "Review your knowledge efficiently using dynamic flashcards generated directly from your database."
                )
                .tag(1)
                
                // Page 3: Sample Data Choice & Get Started
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 70))
                        .foregroundStyle(Color.accentColor)
                    
                    VStack(spacing: 8) {
                        Text("Ready to Start")
                            .font(.title)
                            .bold()
                        
                        Text("Would you like to load starter databases (Financial Indicators, Wine Grapes, Scientific Milestones)?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    // Toggle for sample data
                    Toggle(isOn: $loadSampleData) {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.down.fill")
                                .foregroundStyle(Color.accentColor)
                            Text("Load Sample Databases")
                                .font(.headline)
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                    
                    Spacer()
                    
                    Button(action: completeOnboarding) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            // Bottom Action (for Pages 0 and 1)
            if currentPage < 2 {
                HStack {
                    Button("Skip") {
                        currentPage = 2
                    }
                    .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            currentPage += 1
                        }
                    }) {
                        Text("Next")
                            .bold()
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
    }
    
    private func completeOnboarding() {
        if loadSampleData {
            SampleDataGenerator.insertSampleDataIfNeeded(modelContext: modelContext)
        }
        isFirstLaunch = false
    }
}

// Subview for page items
private struct OnboardingPageView: View {
    let imageName: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: imageName)
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.title)
                    .bold()
                
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(isFirstLaunch: .constant(true))
}
