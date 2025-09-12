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
    @StateObject private var tabRouter = TabRouter()
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
                                .environmentObject(tabRouter)
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
            if (existingUser.fashionInterest ?? .notSpecified) == .notSpecified {
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
        // Mark onboarding complete by promoting to app state
        firebaseManager.currentUser = user
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
                        // Persist selection immediately
                        Task {
                            try? await FirebaseManager.shared.saveUserData(user)
                        }
                        onComplete()
                    }) {
                        HStack {
                            Text(interest.displayName)
                                .font(.theme.headline)
                                .foregroundColor(.theme.textPrimary)
                            
                            Spacer()
                            
                            if (user.fashionInterest ?? .notSpecified) == interest {
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
                                .stroke((user.fashionInterest ?? .notSpecified) == interest ? Color.theme.primary : Color.clear, lineWidth: 2)
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
    @EnvironmentObject var router: TabRouter
    var body: some View {
        TabView(selection: $router.selection) {
            WardrobeView()
                .tabItem {
                    Image(systemName: "tshirt")
                    Text("Wardrobe")
                }
                .tag(MainTab.wardrobe)
            
            BuildLookView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("Build Look")
                }
                .tag(MainTab.build)
            
            MyLooksView()
                .tabItem {
                    Image(systemName: "heart")
                    Text("My Looks")
                }
                .tag(MainTab.myLooks)
            
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
                .tag(MainTab.calendar)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(MainTab.profile)
        }
        .accentColor(.theme.primary)
    }
}

// MyLooksView now lives under Views/MyLooks

struct CalendarView: View {
    var body: some View {
        Text("Calendar")
            .foregroundColor(.theme.textPrimary)
    }
}

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var user: User = User(id: Auth.auth().currentUser?.uid ?? UUID().uuidString)
    @State private var showSaved = false

    var body: some View {
        ZStack {
            CharacterSetupView(
                user: $user,
                onBack: {},
                onComplete: { saveChanges() },
                showsBackButton: false,
                submitTitle: "Save Changes"
            )
            .id(user.id)

            if showSaved {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.white)
                        Text("Saved").foregroundColor(.white).font(.theme.headline)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                    .padding(.bottom, 24)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: showSaved)
            }
        }
        .onAppear(perform: loadUser)
    }

    private func loadUser() {
        if let persisted = users.sorted(by: { ($0.updatedAt) > ($1.updatedAt) }).first(where: { ($0.appearanceProfileText?.isEmpty == false) }) ?? users.first {
            user = persisted
            return
        }
        // user already initialized with a default id
        modelContext.insert(user)
        try? modelContext.save()
    }

    private func saveChanges() {
        user.updatedAt = Date()
        try? modelContext.save()
        showSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { showSaved = false }
        }
    }
}

// Removed old SampleFaceGalleryView and SampleBodyGalleryView as they are no longer used

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
    var showsBackButton: Bool = true
    var submitTitle: String = "Continue"

    @State private var age: Int = 25
    @State private var unitSystem: UnitSystem = .imperial
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 8
    @State private var weightLbs: Int = 170
    @State private var heightCm: Int = 173
    @State private var weightKg: Int = 77
    @State private var skinTone: SkinTone = .medium
    @State private var hairColor: HairColor = .brown
    @State private var hairType: HairType = .wavy
    @State private var beardType: BeardType = .none

    var body: some View {
        VStack(spacing: 0) {
            if showsBackButton {
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
            } else {
                // Maintain top spacing without a back button
                Spacer().frame(height: 20)
            }

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Text("Create Your Character")
                            .font(.theme.largeTitle)
                            .foregroundColor(.theme.textPrimary)
                        PrivacyInfoBadge(text: "Privacy-first: we never ask for face or body images")
                    }

                    Card {

                        // Age (use Picker list like metrics)
                        HStack(spacing: 12) {
                            Label("Age", systemImage: "calendar")
                                .labelStyle(IconTitleLabelStyle())
                                .foregroundColor(.theme.textSecondary)
                            Spacer()
                            Menu {
                                ForEach(13...90, id: \.self) { value in
                                    Button(action: { age = value }) {
                                        Text("\(value)")
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text("\(age)")
                                        .font(.theme.body)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.9)
                                        .foregroundColor(.theme.textPrimary)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.footnote)
                                        .foregroundColor(.theme.textSecondary)
                                }
                                .frame(width: 120, alignment: .trailing)
                            }
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

            Button(submitTitle) { applyToUser(); onComplete() }
                .buttonStyle(PrimaryButtonStyle(disabled: !isValid))
                .disabled(!isValid)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .background(Color.theme.background)
        .onAppear(perform: loadFromUser)
        .onChange(of: user.id) { _ in
            loadFromUser()
        }
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
        unitSystem = user.unitSystem ?? .imperial
        if let uAge = user.age { age = uAge }
        if let st = user.skinTone { skinTone = st }
        if let hc = user.hairColor { hairColor = hc }
        if let ht = user.hairType { hairType = ht }
        if let bt = user.beardType { beardType = bt }
        if unitSystem == .imperial {
            if let h = user.height, h > 0 {
                let inchesTotal = Int(h.rounded())
                heightFeet = max(3, min(7, inchesTotal / 12))
                heightInches = max(0, min(11, inchesTotal % 12))
            } else {
                // Default to 5'8" if no valid height stored
                heightFeet = 5
                heightInches = 8
            }
            if let w = user.weight, w > 0 { weightLbs = Int(w.rounded()) }
        } else {
            if let h = user.height, h > 0 {
                heightCm = Int(h.rounded())
            } else {
                // Default to ~173 cm if no valid height stored
                heightCm = 173
            }
            if let w = user.weight, w > 0 { weightKg = Int(w.rounded()) }
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
            .lineLimit(1)
            .truncationMode(.tail)
            .fixedSize(horizontal: true, vertical: false)
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

// Compact, visually appealing privacy badge used in onboarding
private struct PrivacyInfoBadge: View {
    let text: String
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "lock.shield")
                .font(.footnote)
                .foregroundColor(.theme.primary)
            Text(text)
                .font(.theme.footnote)
                .foregroundColor(.theme.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.theme.border, lineWidth: 1)
        )
        .cornerRadius(12)
        .frame(maxWidth: 360)
    }
}


#Preview {
    ContentView()
        .modelContainer(for: User.self, inMemory: true)
        .preferredColorScheme(.dark)
}
