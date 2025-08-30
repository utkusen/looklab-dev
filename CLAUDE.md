# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Look Lab is an iOS app that generates AI-powered outfit images using clothing items from the user's wardrobe. The app combines SwiftUI frontend with Firebase backend and Google Vertex AI for outfit generation.

## Build & Development Commands

### iOS App
```bash
# Build the iOS app
xcodebuild -project looklab.xcodeproj -scheme looklab -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build

# Run in simulator (use Xcode GUI)
# Open looklab.xcodeproj in Xcode and run
```

### Backend (Firebase Cloud Functions)
```bash
cd looklab-backend
npm install                    # Install dependencies
npm run build                  # Compile TypeScript
npm run serve                  # Local emulator
firebase deploy --only functions  # Deploy to Firebase
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
- ✅ Cloud Functions with Vertex AI integration
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

## Firebase Setup Requirements

Before enabling full functionality:
1. Replace `looklab/GoogleService-Info.plist` with real Firebase config
2. Enable Firebase Auth (Apple provider), Firestore, Cloud Storage, Cloud Functions
3. Deploy Cloud Functions: `cd looklab-backend && firebase deploy`
4. Switch to `ContentView()` in `looklabApp.swift`
5. Uncomment Firebase code in `ContentView.swift` and `OnboardingView`

## Security Architecture

- Firestore rules in `looklab-backend/firestore.rules` enforce user isolation
- Storage rules in `looklab-backend/storage.rules` protect user images  
- All Cloud Functions require authentication (`context.auth`)
- User data strictly partitioned by Firebase UID
- `.gitignore` excludes Firebase config file

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