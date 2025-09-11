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
            } else if existingUser.appearanceProfileText?.isEmpty ?? true {
                _currentStep = State(initialValue: .characterSetup)
            } else {
                _currentStep = State(initialValue: .characterSetup)
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
                            currentStep = .characterSetup
                        }
                    }
                case .characterSetup:
                    CharacterSetupView(user: $user, onBack: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = .fashionInterest
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
    case welcome = 0, fashionInterest = 1, characterSetup = 2
    
    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .fashionInterest: return "Fashion Interest"
        case .characterSetup: return "Character Setup"
        }
    }
    
    var totalSteps: Int { OnboardingStep.allCases.count }
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

// (Removed) FacePhotoUploadView – replaced by CharacterSetupView

// (Removed) BodyInfoView – replaced by CharacterSetupView

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
    let interest: FashionInterest
    @Environment(\.presentationMode) var presentationMode
    
    @State private var faceURLs: [URL] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Select a Sample Face")
                    .font(.theme.title2)
                    .foregroundColor(.theme.textPrimary)
                    .padding(.top, 20)
                
                Text("Choose from our sample faces below")
                    .font(.theme.body)
                    .foregroundColor(.theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                if faceURLs.isEmpty {
                    VStack(spacing: 8) {
                        Text("No sample faces found")
                            .font(.theme.headline)
                            .foregroundColor(.theme.textSecondary)
                        Text("Ensure 'men-faces' and 'women-faces' are added as folder references (blue) and included in the app target.")
                            .font(.theme.caption1)
                            .foregroundColor(.theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 32)
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                            ForEach(faceURLs, id: \.self) { url in
                                Button(action: {
                                    if let img = UIImage(contentsOfFile: url.path) {
                                        selectedImage = img
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }) {
                                    if let uiImage = UIImage(contentsOfFile: url.path) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 160)
                                    } else {
                                        // Fallback if image fails to load
                                        Image(systemName: "person.crop.circle")
                                            .font(.system(size: 40))
                                            .foregroundColor(.theme.textSecondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                }
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
            .onAppear(perform: loadFaces)
        }
    }
    
    private func loadFaces() {
        var urls: [URL] = []
        let exts = ["png", "jpg", "jpeg", "webp"]
        let fm = FileManager.default
        let resourceRoot = Bundle.main.resourceURL

        func collectFromFolder(_ folder: String) {
            guard let base = resourceRoot?.appendingPathComponent(folder), fm.fileExists(atPath: base.path) else { return }
            if let e = fm.enumerator(at: base, includingPropertiesForKeys: nil) {
                for case let fileURL as URL in e {
                    if exts.contains(fileURL.pathExtension.lowercased()) {
                        urls.append(fileURL)
                    }
                }
            }
        }

        switch interest {
        case .male:
            collectFromFolder("men-faces")
        case .female:
            collectFromFolder("women-faces")
        case .everything, .notSpecified:
            collectFromFolder("men-faces")
            collectFromFolder("women-faces")
        }

        // Fallback: scan bundle for face files using explicit prefixes to avoid collisions
        if urls.isEmpty, let root = resourceRoot, let e = fm.enumerator(at: root, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in e {
                if !exts.contains(fileURL.pathExtension.lowercased()) { continue }
                let pathLower = fileURL.path.lowercased()
                if pathLower.contains("clothingimages/") { continue }
                switch interest {
                case .male:
                    if fileURL.lastPathComponent.lowercased().hasPrefix("face_men_") { urls.append(fileURL) }
                case .female:
                    if fileURL.lastPathComponent.lowercased().hasPrefix("face_women_") { urls.append(fileURL) }
                case .everything, .notSpecified:
                    let name = fileURL.lastPathComponent.lowercased()
                    if name.hasPrefix("face_men_") || name.hasPrefix("face_women_") { urls.append(fileURL) }
                }
            }
        }

        // Sort by filename for stable order
        faceURLs = urls.sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
    }
}

struct SampleBodyGalleryView: View {
    @Binding var selectedImage: UIImage?
    let interest: FashionInterest
    @Environment(\.presentationMode) var presentationMode

    @State private var bodyURLs: [URL] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Select a Sample Body")
                    .font(.theme.title2)
                    .foregroundColor(.theme.textPrimary)
                    .padding(.top, 20)

                Text("Choose from our sample bodies below")
                    .font(.theme.body)
                    .foregroundColor(.theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if bodyURLs.isEmpty {
                    VStack(spacing: 8) {
                        Text("No sample bodies found")
                            .font(.theme.headline)
                            .foregroundColor(.theme.textSecondary)
                        Text("Ensure 'men-bodies' and 'women-bodies' are folder references and included in the app target.")
                            .font(.theme.caption1)
                            .foregroundColor(.theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 32)
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                            ForEach(bodyURLs, id: \.self) { url in
                                Button(action: {
                                    if let img = UIImage(contentsOfFile: url.path) {
                                        selectedImage = img
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }) {
                                    if let uiImage = UIImage(contentsOfFile: url.path) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 260)
                                    } else {
                                        Image(systemName: "person.crop.rectangle")
                                            .font(.system(size: 40))
                                            .foregroundColor(.theme.textSecondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                }
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
            .onAppear(perform: loadBodies)
        }
    }

    private func loadBodies() {
        var urls: [URL] = []
        let exts = ["png", "jpg", "jpeg", "webp"]
        let fm = FileManager.default
        let resourceRoot = Bundle.main.resourceURL

        func collectFromFolder(_ folder: String) {
            guard let base = resourceRoot?.appendingPathComponent(folder), fm.fileExists(atPath: base.path) else { return }
            if let e = fm.enumerator(at: base, includingPropertiesForKeys: nil) {
                for case let fileURL as URL in e {
                    if exts.contains(fileURL.pathExtension.lowercased()) {
                        urls.append(fileURL)
                    }
                }
            }
        }

        switch interest {
        case .male:
            collectFromFolder("men-bodies")
        case .female:
            collectFromFolder("women-bodies")
        case .everything, .notSpecified:
            collectFromFolder("men-bodies")
            collectFromFolder("women-bodies")
        }

        // Fallback: scan bundle for body files using explicit prefixes to avoid collisions
        if urls.isEmpty, let root = resourceRoot, let e = fm.enumerator(at: root, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in e {
                if !exts.contains(fileURL.pathExtension.lowercased()) { continue }
                let pathLower = fileURL.path.lowercased()
                if pathLower.contains("clothingimages/") { continue }
                let name = fileURL.lastPathComponent.lowercased()
                switch interest {
                case .male:
                    if name.hasPrefix("body_men_") { urls.append(fileURL) }
                case .female:
                    if name.hasPrefix("body_women_") { urls.append(fileURL) }
                case .everything, .notSpecified:
                    if name.hasPrefix("body_men_") || name.hasPrefix("body_women_") { urls.append(fileURL) }
                }
            }
        }

        bodyURLs = urls.sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
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


// MARK: - Character Setup

struct CharacterSetupView: View {
    @Binding var user: User
    let onBack: () -> Void
    let onComplete: () -> Void

    @State private var age: Int = 25
    @State private var unitSystem: UnitSystem = .imperial
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 10
    @State private var weightLbs: Int = 170
    @State private var heightCm: Int = 178
    @State private var weightKg: Int = 77
    @State private var skinTone: SkinTone = .medium
    @State private var hairColor: HairColor = .brown
    @State private var hairType: HairType = .wavy
    @State private var beardType: BeardType = .none

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left").font(.system(size: 18, weight: .medium))
                        Text("Back").font(.theme.body)
                    }
                    .foregroundColor(.theme.primary)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Text("Create Your Character")
                            .font(.theme.largeTitle)
                            .foregroundColor(.theme.textPrimary)
                        Text("This helps us tailor looks to you")
                            .font(.theme.body)
                            .foregroundColor(.theme.textSecondary)
                    }

                    Card {
                        HStack { SectionHeader(icon: "person", title: "Basics"); Spacer() }

                        // Age (use Picker list like metrics)
                        HStack(spacing: 12) {
                            Label("Age", systemImage: "calendar")
                                .labelStyle(IconTitleLabelStyle())
                                .foregroundColor(.theme.textSecondary)
                            Spacer()
                            Picker("Age", selection: $age) {
                                ForEach(13...90, id: \.self) { Text("\($0)") }
                            }
                            .frame(width: 120)
                            .clipped()
                        }
                        .padding(.top, 4)

                        Divider().overlay(Color.theme.border)

                        // Units
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Units", systemImage: "ruler")
                                .labelStyle(IconTitleLabelStyle())
                                .foregroundColor(.theme.textSecondary)
                            Picker("Units", selection: $unitSystem) {
                                ForEach(UnitSystem.allCases, id: \.self) { Text($0.displayName) }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Height & Weight
                        VStack(spacing: 12) {
                            if unitSystem == .imperial {
                                HStack(spacing: 12) {
                                    LabeledChip(title: "Height"); Spacer()
                                    Picker("ft", selection: $heightFeet) { ForEach(3...7, id: \.self) { Text("\($0) ft") } }.frame(width: 110)
                                    Picker("in", selection: $heightInches) { ForEach(0...11, id: \.self) { Text("\($0) in") } }.frame(width: 110)
                                }
                                HStack(spacing: 12) {
                                    LabeledChip(title: "Weight"); Spacer()
                                    Picker("lbs", selection: $weightLbs) { ForEach(80...350, id: \.self) { Text("\($0) lbs") } }.frame(width: 160)
                                }
                            } else {
                                HStack(spacing: 12) {
                                    LabeledChip(title: "Height"); Spacer()
                                    Picker("cm", selection: $heightCm) { ForEach(120...210, id: \.self) { Text("\($0) cm") } }.frame(width: 160)
                                }
                                HStack(spacing: 12) {
                                    LabeledChip(title: "Weight"); Spacer()
                                    Picker("kg", selection: $weightKg) { ForEach(40...160, id: \.self) { Text("\($0) kg") } }.frame(width: 160)
                                }
                            }
                        }
                        .padding(.top, 6)
                    }

                    Card {
                        HStack { SectionHeader(icon: "eyedropper.halffull", title: "Skin"); Spacer() }
                        SkinHairColorGrid<SkinTone>(items: SkinTone.allCases, selection: $skinTone) { tone in
                            skinColor(for: tone)
                        }
                    }

                    Card {
                        HStack { SectionHeader(icon: "face.smiling", title: "Face & Hair"); Spacer() }
                        VStack(alignment: .leading, spacing: 16) {
                            // Hair Color by swatches
                            Text("Hair Color").font(.theme.subheadline).foregroundColor(.theme.textSecondary)
                            SkinHairColorGrid<HairColor>(items: HairColor.allCases, selection: $hairColor) { color in
                                hairColorValue(for: color)
                            }

                            // Hair Type (clean grid)
                            Text("Hair Type").font(.theme.subheadline).foregroundColor(.theme.textSecondary)
                            SelectGrid(items: HairType.allCases, selection: $hairType) { type in
                                type.displayName
                            }

                            // Beard Type (clean grid)
                            Text("Beard Type").font(.theme.subheadline).foregroundColor(.theme.textSecondary)
                            SelectGrid(items: BeardType.allCases, selection: $beardType) { type in
                                type.displayName
                            }
                        }
                    }
                    // Preview removed per request
                }
                .padding(24)
            }

            Button("Continue") { applyToUser(); onComplete() }
                .buttonStyle(PrimaryButtonStyle(disabled: !isValid))
                .disabled(!isValid)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .background(Color.theme.background)
        .onAppear(perform: loadFromUser)
    }

    private var isValid: Bool { age >= 13 && age <= 90 }

    private var previewText: String {
        var parts: [String] = []
        parts.append("Age: \(age)")
        if unitSystem == .imperial {
            parts.append("Height: \(heightFeet)'\(heightInches)\"")
            parts.append("Weight: \(weightLbs) lbs")
        } else {
            parts.append("Height: \(heightCm) cm")
            parts.append("Weight: \(weightKg) kg")
        }
        parts.append("Skin: \(skinTone.displayName)")
        parts.append("Hair: \(hairColor.displayName), \(hairType.displayName)")
        if beardType != .none { parts.append("Beard: \(beardType.displayName)") } else { parts.append("Beard: None") }
        return parts.joined(separator: "; ")
    }

    private func loadFromUser() {
        unitSystem = user.unitSystem
        if let uAge = user.age { age = uAge }
        if let st = user.skinTone { skinTone = st }
        if let hc = user.hairColor { hairColor = hc }
        if let ht = user.hairType { hairType = ht }
        if let bt = user.beardType { beardType = bt }
        if unitSystem == .imperial {
            if let h = user.height {
                let inchesTotal = Int(h.rounded())
                heightFeet = max(3, min(7, inchesTotal / 12))
                heightInches = max(0, min(11, inchesTotal % 12))
            }
            if let w = user.weight { weightLbs = Int(w.rounded()) }
        } else {
            if let h = user.height { heightCm = Int(h.rounded()) }
            if let w = user.weight { weightKg = Int(w.rounded()) }
        }
    }

    private func applyToUser() {
        user.age = age
        user.unitSystem = unitSystem
        user.skinTone = skinTone
        user.hairColor = hairColor
        user.hairType = hairType
        user.beardType = beardType
        if unitSystem == .imperial {
            let inches = Double(heightFeet * 12 + heightInches)
            user.height = inches
            user.weight = Double(weightLbs)
        } else {
            user.height = Double(heightCm)
            user.weight = Double(weightKg)
        }
        user.appearanceProfileText = previewText
        user.updatedAt = Date()
    }
    // MARK: - Helpers for color display
    private func skinColor(for tone: SkinTone) -> Color {
        switch tone {
        case .veryLight: return Color(red: 1.0, green: 0.88, blue: 0.80)
        case .light: return Color(red: 0.98, green: 0.80, blue: 0.68)
        case .medium: return Color(red: 0.86, green: 0.64, blue: 0.47)
        case .tan: return Color(red: 0.71, green: 0.50, blue: 0.36)
        case .dark: return Color(red: 0.45, green: 0.31, blue: 0.23)
        case .veryDark: return Color(red: 0.30, green: 0.20, blue: 0.15)
        }
    }

    private func hairColorValue(for color: HairColor) -> Color {
        switch color {
        case .black: return .black
        case .darkBrown: return Color(red: 0.22, green: 0.13, blue: 0.08)
        case .brown: return Color(red: 0.36, green: 0.22, blue: 0.13)
        case .lightBrown: return Color(red: 0.55, green: 0.40, blue: 0.26)
        case .blonde: return Color(red: 0.95, green: 0.86, blue: 0.55)
        case .platinum: return Color(red: 0.93, green: 0.93, blue: 0.90)
        case .red: return Color(red: 0.76, green: 0.24, blue: 0.19)
        case .auburn: return Color(red: 0.54, green: 0.21, blue: 0.17)
        case .gray: return Color(red: 0.65, green: 0.65, blue: 0.66)
        case .white: return .white
        case .dyed: return Color.purple
        }
    }
}

private struct SectionHeader: View {
    let icon: String
    let title: String
    var body: some View {
        Label(title, systemImage: icon)
            .labelStyle(IconTitleLabelStyle())
            .font(.theme.title3)
            .foregroundColor(.theme.textPrimary)
    }
}

private struct IconTitleLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon.foregroundColor(.theme.primary)
            configuration.title
        }
    }
}

private struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 14) { content }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color.theme.surface)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.theme.border, lineWidth: 1))
    }
}

// Color swatch grid for Skin/Hair colors
private struct SkinHairColorGrid<Item: Hashable>: View {
    let items: [Item]
    @Binding var selection: Item
    let colorFor: (Item) -> Color
    private let columns = [GridItem(.adaptive(minimum: 36), spacing: 12)]
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(items, id: \.self) { item in
                Button(action: { selection = item }) {
                    ZStack {
                        Circle()
                            .fill(colorFor(item))
                            .frame(width: 32, height: 32)
                            .overlay(Circle().stroke(Color.theme.border, lineWidth: 1))
                        if item == selection {
                            Circle()
                                .stroke(Color.theme.primary, lineWidth: 3)
                                .frame(width: 36, height: 36)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct LabeledChip: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.theme.subheadline)
            .foregroundColor(.theme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.theme.surface.opacity(0.6))
            .cornerRadius(8)
    }
}

// Text selection grid with clean layout (no overlapping containers)
private struct SelectGrid<Item: Hashable>: View {
    let items: [Item]
    @Binding var selection: Item
    let titleProvider: (Item) -> String
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(items, id: \.self) { item in
                Button(action: { selection = item }) {
                    Text(titleProvider(item))
                        .font(.theme.caption1)
                        .foregroundColor(item == selection ? .theme.background : .theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(item == selection ? Color.theme.primary : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(item == selection ? Color.theme.primary : Color.theme.border, lineWidth: 1)
                        )
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
    }
}


#Preview {
    ContentView()
        .modelContainer(for: User.self, inMemory: true)
        .preferredColorScheme(.dark)
}
