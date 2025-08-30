# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Look Lab is an iOS app that generates AI-powered outfit images using clothing items from the user's wardrobe. The app combines SwiftUI frontend with Firebase backend and Google Vertex AI for outfit generation.

## Repository Structure

```
looklab-dev/                   # Project root (git repository)
├── looklab/                   # iOS SwiftUI Application
│   ├── looklab.xcodeproj/     # Xcode project files
│   ├── looklab/               # Swift source code
│   │   ├── Models/            # SwiftData models (User, ClothingItem, Look)
│   │   ├── Views/             # SwiftUI views organized by feature
│   │   ├── Services/          # Firebase integration services
│   │   ├── Theme/             # Color and typography system
│   │   └── GoogleService-Info.plist  # Firebase configuration
│   ├── looklabTests/          # Unit tests
│   └── looklabUITests/        # UI tests
├── looklab-backend/           # Firebase Cloud Functions Backend
│   ├── src/                   # TypeScript source code
│   │   └── index.ts           # Cloud Functions implementation
│   ├── firebase.json          # Firebase project configuration
│   ├── firestore.rules        # Database security rules
│   ├── storage.rules          # File storage security rules
│   └── package.json           # Node.js dependencies
├── CLAUDE.md                  # AI assistant documentation (this file)
└── SETUP.md                   # Project setup instructions
```

## Build & Development Commands

### iOS App
```bash
# Build the iOS app (from project root)
xcodebuild -project looklab/looklab.xcodeproj -scheme looklab -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build

# Run in simulator (use Xcode GUI)
# Open looklab/looklab.xcodeproj in Xcode and run
```

### Backend (Firebase Cloud Functions)
```bash
cd looklab-backend
npm install                    # Install dependencies
npm run build                  # Compile TypeScript
npm run serve                  # Local emulator
firebase deploy --only functions  # Deploy to Firebase

# Deploy all Firebase services
firebase deploy                   # Deploy functions, firestore rules, storage rules
```

## Architecture & Current State

### Dual Implementation Mode
The app currently runs in **standalone mode** with Firebase integration disabled:
- **Current**: `looklabApp.swift` uses `StandaloneContentView` for UI-only testing
- **Full version**: `ContentView.swift` contains complete Firebase-integrated version
- **Switch**: Replace `StandaloneContentView()` with `ContentView()` in `looklabApp.swift` after Firebase setup

### Key Architecture Patterns

**SwiftUI + SwiftData Local Storage**:
- Models in `looklab/Models/` use `@Model` for SwiftData persistence
- Local storage syncs with Firebase via `FirebaseManager`
- Theme system in `looklab/Theme/` with dark premium colors

**Firebase Integration**:
- `FirebaseManager.swift`: Singleton managing Auth, Firestore, Functions, Storage
- `AppleAuthManager.swift`: Handles Apple Sign-In flow with Firebase Auth
- Authentication state drives UI flow (onboarding vs. main app)

**Backend Cloud Functions**:
- `generateOutfit`: Vertex AI integration for outfit generation
- `uploadClothingItem`: Image processing and storage
- `deleteUserData`: GDPR compliance for account deletion

### Data Flow
1. **Authentication**: Apple Sign-In → Firebase Auth → User document in Firestore
2. **Wardrobe**: Upload images → Cloud Functions → Cloud Storage → Firestore metadata
3. **Outfit Generation**: Select clothes → Cloud Functions → Vertex AI → Generated images
4. **Local Sync**: SwiftData models sync with Firestore via FirebaseManager

### Feature Implementation Status
- ✅ Dark theme system with premium gold accents
- ✅ Core data models (User, ClothingItem, Look, Calendar)
- ✅ Firebase integration architecture (currently disabled)
- ✅ Apple Sign-In authentication setup
- ✅ Cloud Functions with Vertex AI integration deployed to Firebase
- ✅ Firebase project configured with Auth, Firestore, Storage, Functions
- ✅ Bundle identifier: `com.us.looklab` (Apple approved)
- 🚧 Main feature views are placeholder implementations
- ❌ Onboarding flow (gender, photos, body info)
- ❌ Wardrobe management UI
- ❌ AI outfit generation UI

## Theme System

The app uses a comprehensive dark theme system:
- `Color.theme.background`, `.surface`, `.primary` for consistent theming
- `Font.theme.largeTitle`, `.headline`, `.body` for typography
- All colors defined in Assets.xcassets with dark/light variants
- Premium feel with rounded design system and gold (#BBD7FF) accent

## Firebase Setup Status

✅ **Completed Setup:**
1. ✅ Firebase project created: `looklab-7acba`
2. ✅ Real `GoogleService-Info.plist` configured with bundle ID `com.us.looklab`
3. ✅ Firebase services enabled: Auth (Apple), Firestore, Cloud Storage, Cloud Functions
4. ✅ Cloud Functions deployed with 3 functions: `generateOutfit`, `uploadClothingItem`, `deleteUserData`
5. ✅ Firestore and Storage security rules deployed

**To Enable Full Functionality:**
1. Switch to `ContentView()` in `looklabApp.swift`
2. Uncomment Firebase code in `ContentView.swift` and `OnboardingView`

## Security Architecture

- Firestore rules in `looklab-backend/firestore.rules` enforce user isolation
- Storage rules in `looklab-backend/storage.rules` protect user images  
- All Cloud Functions require authentication (`context.auth`)
- User data strictly partitioned by Firebase UID
- Firebase config included in repository (production-ready setup)

## Development Workflow

When implementing new features:
1. **Models**: Add SwiftData models in `looklab/Models/`
2. **Views**: Organize by feature in `looklab/Views/[Feature]/`
3. **Services**: Add Firebase interactions to `FirebaseManager.swift`
4. **Backend**: Add Cloud Functions to `looklab-backend/src/index.ts`
5. **Theme**: Use `Color.theme.*` and `Font.theme.*` consistently

## Testing

The app includes placeholder views for all main features. To test Firebase integration:
- Use Firebase Local Emulator Suite during development
- Test authentication flow with Apple Sign-In in iOS Simulator
- Verify security rules with Firebase emulator before production deployment

## Current Deployment Status

**Firebase Backend (Production):**
- Project ID: `looklab-7acba`
- Cloud Functions: ✅ Deployed (generateOutfit, uploadClothingItem, deleteUserData)
- Firestore Rules: ✅ Deployed
- Storage Rules: ✅ Deployed
- Authentication: ✅ Apple Sign-In enabled

**iOS App:**
- Bundle ID: `com.us.looklab` (Apple approved)
- Firebase Configuration: ✅ GoogleService-Info.plist included
- Current Mode: Standalone (UI testing without Firebase)
- Ready to switch to full Firebase integration

**Git Repository:**
- GitHub: https://github.com/utkusen/looklab-dev
- Structure: Unified repo containing both iOS app and Firebase backend
- Branch: `main`