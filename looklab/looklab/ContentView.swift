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
            if existingUser.fashionInterest == .notSpecified {
                _currentStep = State(initialValue: .welcome)
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
            _currentStep = State(initialValue: .welcome)
        }
    }
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content
                switch currentStep {
                case .welcome:
                    OnboardingWelcomeView {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = .fashionInterest
                        }
                    }
                case .fashionInterest:
                    FashionInterestSelectionView(user: $user, onBack: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = .welcome
                        }
                    }) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = .facePhoto
                        }
                    }
                case .facePhoto:
                    FacePhotoUploadView(user: $user, onBack: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = .fashionInterest
                        }
                    }) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = .bodyInfo
                        }
                    }
                case .bodyInfo:
                    BodyInfoView(user: $user, onBack: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = .facePhoto
                        }
                    }) {
                        saveUser()
                    }
                }
            }
        }
    }
    
    private func saveUser() {
        modelContext.insert(user)
        try? modelContext.save()
    }
}

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0, fashionInterest = 1, facePhoto = 2, bodyInfo = 3
    
    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .fashionInterest: return "Fashion Interest"
        case .facePhoto: return "Face Photo"  
        case .bodyInfo: return "Body Photo"
        }
    }
    
    var totalSteps: Int {
        return OnboardingStep.allCases.count
    }
}

struct FashionInterestSelectionView: View {
    @Binding var user: User
    let onBack: () -> Void
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            // Back button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                        Text("Back")
                            .font(.theme.body)
                    }
                    .foregroundColor(.theme.primary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            VStack(spacing: 16) {
                Text("What interests you?")
                    .font(.theme.largeTitle)
                    .foregroundColor(.theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Choose the fashion style you'd like to explore")
                    .font(.theme.title2)
                    .foregroundColor(.theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                ForEach([FashionInterest.male, FashionInterest.female, FashionInterest.everything], id: \.self) { interest in
                    Button(action: {
                        user.fashionInterest = interest
                        user.updatedAt = Date()
                        onComplete()
                    }) {
                        HStack {
                            Text(interest.displayName)
                                .font(.theme.headline)
                                .foregroundColor(.theme.textPrimary)
                            
                            Spacer()
                            
                            if user.fashionInterest == interest {
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
                                .stroke(user.fashionInterest == interest ? Color.theme.primary : Color.clear, lineWidth: 2)
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
    let onBack: () -> Void
    let onComplete: () -> Void
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingSampleGallery = false
    @State private var showingActionSheet = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        VStack(spacing: 32) {
            // Back button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                        Text("Back")
                            .font(.theme.body)
                    }
                    .foregroundColor(.theme.primary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            VStack(spacing: 16) {
                Text("Add your photo")
                    .font(.theme.largeTitle)
                    .foregroundColor(.theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Tap the circle to add a photo")
                    .font(.theme.body)
                    .foregroundColor(.theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            VStack(spacing: 24) {
                // Clickable photo area
                Button(action: {
                    showingActionSheet = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.theme.surface)
                            .frame(width: 200, height: 200)
                            .overlay(
                                Circle()
                                    .stroke(selectedImage != nil ? Color.theme.primary : Color.theme.border, lineWidth: 2)
                            )
                        
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 196, height: 196)
                                .clipShape(Circle())
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.system(size: 60))
                                    .foregroundColor(.theme.textSecondary)
                                
                                Text("Tap to add photo")
                                    .font(.theme.caption1)
                                    .foregroundColor(.theme.textSecondary)
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Sample gallery option
                Button("Select Sample Face From the Gallery") {
                    showingSampleGallery = true
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            Button("Continue") {
                if let selectedImage = selectedImage {
                    // Convert UIImage to Data and save to user model
                    if let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
                        user.facePhotoData = imageData
                    }
                }
                user.updatedAt = Date()
                onComplete()
            }
            .buttonStyle(PrimaryButtonStyle(disabled: selectedImage == nil))
            .padding(.horizontal, 24)
            .disabled(selectedImage == nil)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.background)
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Select Photo"),
                buttons: [
                    .default(Text("Camera")) {
                        showingCamera = true
                    },
                    .default(Text("Photo Library")) {
                        showingImagePicker = true
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
        }
        .sheet(isPresented: $showingSampleGallery) {
            SampleFaceGalleryView(selectedImage: $selectedImage)
        }
    }
}

struct BodyInfoView: View {
    @Binding var user: User
    let onBack: () -> Void
    let onComplete: () -> Void
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingSampleGallery = false
    @State private var showingActionSheet = false
    @State private var selectedBodyImage: UIImage?
    
    var body: some View {
        VStack(spacing: 32) {
            // Back button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                        Text("Back")
                            .font(.theme.body)
                    }
                    .foregroundColor(.theme.primary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            VStack(spacing: 16) {
                Text("Add body photo")
                    .font(.theme.largeTitle)
                    .foregroundColor(.theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Tap the area to add a body photo")
                    .font(.theme.body)
                    .foregroundColor(.theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            VStack(spacing: 24) {
                // Clickable body photo area
                Button(action: {
                    showingActionSheet = true
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.theme.surface)
                            .frame(width: 200, height: 300)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(selectedBodyImage != nil ? Color.theme.primary : Color.theme.border, lineWidth: 2)
                            )
                        
                        if let selectedBodyImage = selectedBodyImage {
                            Image(uiImage: selectedBodyImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 196, height: 296)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "person.crop.rectangle.badge.plus")
                                    .font(.system(size: 60))
                                    .foregroundColor(.theme.textSecondary)
                                
                                Text("Tap to add body photo")
                                    .font(.theme.body)
                                    .foregroundColor(.theme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Sample gallery option
                Button("Select Sample Body From the Gallery") {
                    showingSampleGallery = true
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            Button("Get Started") {
                if let selectedBodyImage = selectedBodyImage {
                    if let imageData = selectedBodyImage.jpegData(compressionQuality: 0.8) {
                        user.bodyPhotoData = imageData
                    }
                }
                
                user.updatedAt = Date()
                onComplete()
            }
            .buttonStyle(PrimaryButtonStyle(disabled: selectedBodyImage == nil))
            .padding(.horizontal, 24)
            .disabled(selectedBodyImage == nil)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.background)
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Select Photo"),
                buttons: [
                    .default(Text("Camera")) {
                        showingCamera = true
                    },
                    .default(Text("Photo Library")) {
                        showingImagePicker = true
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedBodyImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(selectedImage: $selectedBodyImage, sourceType: .camera)
        }
        .sheet(isPresented: $showingSampleGallery) {
            SampleBodyGalleryView(selectedImage: $selectedBodyImage)
        }
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
    let disabled: Bool
    
    init(disabled: Bool = false) {
        self.disabled = disabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.theme.headline)
            .foregroundColor(disabled ? .theme.textSecondary : .theme.background)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(disabled ? Color.theme.surface : Color.theme.primary)
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed && !disabled ? 0.95 : 1.0)
            .opacity(disabled ? 0.6 : (configuration.isPressed ? 0.8 : 1.0))
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
        MyWardrobeView()
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

struct SampleFaceGalleryView: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Select a Sample Face")
                    .font(.theme.title2)
                    .foregroundColor(.theme.textPrimary)
                    .padding(.top, 20)
                
                Text("Choose from our sample faces below")
                    .font(.theme.body)
                    .foregroundColor(.theme.textSecondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                // Sample faces grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    // Sample face 1 - using system person icon for now
                    Button(action: {
                        // Create a sample face image from system icon
                        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200))
                        let sampleImage = renderer.image { context in
                            UIColor.systemGray3.setFill()
                            context.fill(CGRect(x: 0, y: 0, width: 200, height: 200))
                            
                            let config = UIImage.SymbolConfiguration(pointSize: 80, weight: .regular)
                            let personIcon = UIImage(systemName: "person.crop.circle.fill", withConfiguration: config)
                            personIcon?.draw(in: CGRect(x: 60, y: 60, width: 80, height: 80))
                        }
                        
                        selectedImage = sampleImage
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.theme.surface)
                                .frame(height: 120)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.theme.textSecondary)
                                
                                Text("Sample Face 1")
                                    .font(.theme.caption1)
                                    .foregroundColor(.theme.textSecondary)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Sample face 2 - different icon
                    Button(action: {
                        // Create a different sample face image
                        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200))
                        let sampleImage = renderer.image { context in
                            UIColor.systemBlue.withAlphaComponent(0.2).setFill()
                            context.fill(CGRect(x: 0, y: 0, width: 200, height: 200))
                            
                            let config = UIImage.SymbolConfiguration(pointSize: 80, weight: .regular)
                            let personIcon = UIImage(systemName: "person.crop.circle", withConfiguration: config)
                            personIcon?.draw(in: CGRect(x: 60, y: 60, width: 80, height: 80))
                        }
                        
                        selectedImage = sampleImage
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.theme.surface)
                                .frame(height: 120)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "person.crop.circle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.theme.primary)
                                
                                Text("Sample Face 2")
                                    .font(.theme.caption1)
                                    .foregroundColor(.theme.textSecondary)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.theme.primary)
                }
            }
        }
    }
}

struct SampleBodyGalleryView: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Select a Sample Body")
                    .font(.theme.title2)
                    .foregroundColor(.theme.textPrimary)
                    .padding(.top, 20)
                
                Text("Choose from our sample body types below")
                    .font(.theme.body)
                    .foregroundColor(.theme.textSecondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                // Sample body grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    // Sample body 1
                    Button(action: {
                        // Create a sample body image
                        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 300))
                        let sampleImage = renderer.image { context in
                            UIColor.systemGray3.setFill()
                            context.fill(CGRect(x: 0, y: 0, width: 200, height: 300))
                            
                            let config = UIImage.SymbolConfiguration(pointSize: 80, weight: .regular)
                            let personIcon = UIImage(systemName: "person.crop.rectangle.fill", withConfiguration: config)
                            personIcon?.draw(in: CGRect(x: 60, y: 110, width: 80, height: 80))
                        }
                        
                        selectedImage = sampleImage
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.theme.surface)
                                .frame(height: 160)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "person.crop.rectangle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.theme.textSecondary)
                                
                                Text("Sample Body 1")
                                    .font(.theme.caption1)
                                    .foregroundColor(.theme.textSecondary)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Sample body 2
                    Button(action: {
                        // Create a different sample body image
                        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 300))
                        let sampleImage = renderer.image { context in
                            UIColor.systemBlue.withAlphaComponent(0.2).setFill()
                            context.fill(CGRect(x: 0, y: 0, width: 200, height: 300))
                            
                            let config = UIImage.SymbolConfiguration(pointSize: 80, weight: .regular)
                            let personIcon = UIImage(systemName: "person.crop.rectangle", withConfiguration: config)
                            personIcon?.draw(in: CGRect(x: 60, y: 110, width: 80, height: 80))
                        }
                        
                        selectedImage = sampleImage
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.theme.surface)
                                .frame(height: 160)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "person.crop.rectangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.theme.primary)
                                
                                Text("Sample Body 2")
                                    .font(.theme.caption1)
                                    .foregroundColor(.theme.textSecondary)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.theme.primary)
                }
            }
        }
    }
}

struct OnboardingWelcomeView: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 32) {
                // App icon or illustration placeholder
                ZStack {
                    Circle()
                        .fill(Color.theme.primary.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(.theme.primary)
                }
                
                VStack(spacing: 16) {
                    Text("Let's create your first look!")
                        .font(.theme.largeTitle)
                        .foregroundColor(.theme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("We need just a bit of information from you to make it accurate and personalized")
                        .font(.theme.body)
                        .foregroundColor(.theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .padding(.horizontal, 32)
                }
            }
            
            Spacer()
            
            Button("Get Started") {
                onContinue()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.background)
    }
}


#Preview {
    ContentView()
        .modelContainer(for: User.self, inMemory: true)
        .preferredColorScheme(.dark)
}
