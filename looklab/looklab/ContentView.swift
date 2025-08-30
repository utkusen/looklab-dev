//
//  ContentView.swift
//  looklab
//
//  Created by Utku Sen on 30/08/2025.
//

import SwiftUI
import SwiftData
import FirebaseAuth

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
                    if let currentUser = firebaseManager.currentUser {
                        // Check if onboarding is complete
                        if currentUser.isOnboardingComplete {
                            MainTabView()
                        } else {
                            OnboardingFlowView(user: currentUser)
                        }
                    } else {
                        // Create new user and start onboarding
                        OnboardingFlowView()
                    }
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

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var currentStep: OnboardingStep
    @State private var user: User
    
    init(user: User? = nil) {
        if let existingUser = user {
            _user = State(initialValue: existingUser)
            // Determine current step based on what's already completed
            if existingUser.gender == .notSpecified {
                _currentStep = State(initialValue: .gender)
            } else if existingUser.facePhotoData == nil {
                _currentStep = State(initialValue: .facePhoto)
            } else {
                _currentStep = State(initialValue: .bodyInfo)
            }
        } else {
            // Get UID from Firebase Auth directly
            let uid = Auth.auth().currentUser?.uid ?? ""
            let newUser = User(id: uid)
            _user = State(initialValue: newUser)
            _currentStep = State(initialValue: .gender)
        }
    }
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            
            switch currentStep {
            case .gender:
                GenderSelectionView(user: $user) {
                    withAnimation {
                        currentStep = .facePhoto
                    }
                }
            case .facePhoto:
                FacePhotoUploadView(user: $user) {
                    withAnimation {
                        currentStep = .bodyInfo
                    }
                }
            case .bodyInfo:
                BodyInfoView(user: $user) {
                    saveUser()
                }
            }
        }
    }
    
    private func saveUser() {
        modelContext.insert(user)
        try? modelContext.save()
    }
}

enum OnboardingStep {
    case gender, facePhoto, bodyInfo
}

struct GenderSelectionView: View {
    @Binding var user: User
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("Tell us about yourself")
                    .font(.theme.largeTitle)
                    .foregroundColor(.theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("What's your gender?")
                    .font(.theme.title2)
                    .foregroundColor(.theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)
            
            Spacer()
            
            VStack(spacing: 16) {
                ForEach([Gender.male, Gender.female, Gender.nonBinary], id: \.self) { gender in
                    Button(action: {
                        user.gender = gender
                        user.updatedAt = Date()
                        onComplete()
                    }) {
                        HStack {
                            Text(gender.displayName)
                                .font(.theme.headline)
                                .foregroundColor(.theme.textPrimary)
                            
                            Spacer()
                            
                            if user.gender == gender {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.theme.primary)
                            }
                        }
                        .padding(.horizontal, 24)
                        .frame(height: 56)
                        .background(Color.theme.surface)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(user.gender == gender ? Color.theme.primary : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.background)
    }
}

struct FacePhotoUploadView: View {
    @Binding var user: User
    let onComplete: () -> Void
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("Add your photo")
                    .font(.theme.largeTitle)
                    .foregroundColor(.theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("This helps us create more accurate looks for you")
                    .font(.theme.body)
                    .foregroundColor(.theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)
            
            Spacer()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.theme.surface)
                        .frame(width: 200, height: 200)
                    
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 200)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.theme.textSecondary)
                    }
                }
                
                VStack(spacing: 12) {
                    Button("Take Photo") {
                        showingCamera = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button("Select from Gallery") {
                        showingImagePicker = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            Button("Continue") {
                if let selectedImage = selectedImage {
                    // Convert UIImage to Data and save to user model
                    if let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
                        // For now, we'll store as base64 string
                        // TODO: Upload to Firebase Storage and store URL
                        user.facePhotoData = imageData
                    }
                }
                user.updatedAt = Date()
                onComplete()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .disabled(selectedImage == nil)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.background)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
        }
    }
}

struct BodyInfoView: View {
    @Binding var user: User
    let onComplete: () -> Void
    @State private var selectedHeight: Double = 170
    @State private var selectedWeight: Double = 70
    @State private var selectedSkinTone: SkinTone = .medium
    @State private var showingImagePicker = false
    @State private var selectedBodyImage: UIImage?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerView
                bodyInputsView
                continueButton
            }
        }
        .background(Color.theme.background)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedBodyImage, sourceType: .photoLibrary)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            Text("Body information")
                .font(.theme.largeTitle)
                .foregroundColor(.theme.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Help us create the perfect fit")
                .font(.theme.body)
                .foregroundColor(.theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
    
    private var bodyInputsView: some View {
        VStack(spacing: 24) {
            heightSlider
            weightSlider
            skinToneSelection
            bodyPhotoSection
        }
        .padding(.horizontal, 24)
    }
    
    private var heightSlider: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Height: \(Int(selectedHeight)) cm")
                .font(.theme.headline)
                .foregroundColor(.theme.textPrimary)
            
            Slider(value: $selectedHeight, in: 140...210, step: 1)
                .accentColor(.theme.primary)
        }
    }
    
    private var weightSlider: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weight: \(Int(selectedWeight)) kg")
                .font(.theme.headline)
                .foregroundColor(.theme.textPrimary)
            
            Slider(value: $selectedWeight, in: 40...150, step: 1)
                .accentColor(.theme.primary)
        }
    }
    
    private var skinToneSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skin Tone")
                .font(.theme.headline)
                .foregroundColor(.theme.textPrimary)
            
            skinToneGrid
        }
    }
    
    private var skinToneGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
            ForEach(SkinTone.allCases, id: \.self) { tone in
                SkinToneButton(tone: tone, selectedTone: $selectedSkinTone)
            }
        }
    }
    
    private var bodyPhotoSection: some View {
        VStack(spacing: 12) {
            Text("Body Photo (Optional)")
                .font(.theme.headline)
                .foregroundColor(.theme.textPrimary)
            
            Button("Upload Body Photo") {
                showingImagePicker = true
            }
            .buttonStyle(SecondaryButtonStyle())
            
            if selectedBodyImage != nil {
                Text("Photo uploaded ✓")
                    .font(.theme.caption1)
                    .foregroundColor(.theme.primary)
            }
        }
    }
    
    private var continueButton: some View {
        Button("Get Started") {
            user.height = selectedHeight
            user.weight = selectedWeight
            user.skinTone = selectedSkinTone
            
            if let selectedBodyImage = selectedBodyImage {
                // Convert UIImage to Data and save to user model
                if let imageData = selectedBodyImage.jpegData(compressionQuality: 0.8) {
                    // For now, we'll store as base64 string
                    // TODO: Upload to Firebase Storage and store URL
                    user.bodyPhotoData = imageData
                }
            }
            
            user.updatedAt = Date()
            onComplete()
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
}

struct SkinToneButton: View {
    let tone: SkinTone
    @Binding var selectedTone: SkinTone
    
    var body: some View {
        Button(action: {
            selectedTone = tone
        }) {
            Text(tone.displayName)
                .font(.theme.caption1)
                .foregroundColor(selectedTone == tone ? .theme.background : .theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selectedTone == tone ? Color.theme.primary : Color.theme.surface)
                .cornerRadius(8)
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.theme.headline)
            .foregroundColor(.theme.background)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.theme.primary)
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.theme.headline)
            .foregroundColor(.theme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.theme.surface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.theme.primary, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
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
