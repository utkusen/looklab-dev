//
//  ContentView.swift
//  looklab
//
//  Created by Utku Sen on 30/08/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var firebaseManager = FirebaseManager.shared
    @Query private var users: [User]
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if firebaseManager.isSignedIn {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
        }
    }
}

struct OnboardingView: View {
    @StateObject private var appleAuthManager = AppleAuthManager.shared
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("Welcome to")
                    .font(.theme.title1)
                    .foregroundColor(.theme.textSecondary)
                
                Text("Look Lab")
                    .font(.theme.largeTitle)
                    .foregroundColor(.theme.primary)
                
                Text("Create stunning outfits with AI")
                    .font(.theme.body)
                    .foregroundColor(.theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    appleAuthManager.signInWithApple()
                }) {
                    HStack {
                        if appleAuthManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .theme.background))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "applelogo")
                                .font(.title2)
                        }
                        Text("Continue with Apple")
                            .font(.theme.headline)
                    }
                    .foregroundColor(.theme.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.theme.textPrimary)
                    .cornerRadius(16)
                }
                .disabled(appleAuthManager.isLoading)
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.background)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            WardrobeView()
                .tabItem {
                    Image(systemName: "tshirt")
                    Text("Wardrobe")
                }
            
            BuildLookView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("Build Look")
                }
            
            MyLooksView()
                .tabItem {
                    Image(systemName: "heart")
                    Text("My Looks")
                }
            
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
        .accentColor(.theme.primary)
    }
}

struct WardrobeView: View {
    var body: some View {
        Text("Wardrobe")
            .foregroundColor(.theme.textPrimary)
    }
}

struct BuildLookView: View {
    var body: some View {
        Text("Build Look")
            .foregroundColor(.theme.textPrimary)
    }
}

struct MyLooksView: View {
    var body: some View {
        Text("My Looks")
            .foregroundColor(.theme.textPrimary)
    }
}

struct CalendarView: View {
    var body: some View {
        Text("Calendar")
            .foregroundColor(.theme.textPrimary)
    }
}

struct ProfileView: View {
    var body: some View {
        Text("Profile")
            .foregroundColor(.theme.textPrimary)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: User.self, inMemory: true)
        .preferredColorScheme(.dark)
}
