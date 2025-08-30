# Look Lab Setup Guide

## Project Overview

Look Lab is an iOS app that generates AI-powered outfit images using clothing items from the user's wardrobe. The app uses Firebase for backend services and Google Vertex AI for outfit generation.

## Architecture

- **iOS App**: SwiftUI with SwiftData for local storage
- **Backend**: Firebase Cloud Functions with TypeScript
- **AI**: Google Vertex AI (Gemini 2.5 Flash Image Preview)
- **Authentication**: Apple Sign-In only
- **Storage**: Firebase Cloud Storage
- **Database**: Cloud Firestore

## Current Implementation Status

✅ **Completed:**
- iOS project structure with SwiftUI
- Dark theme implementation with premium feel
- Core data models (User, ClothingItem, Look, etc.)
- Firebase integration setup
- Apple Sign-In authentication
- Cloud Functions backend structure
- Security rules for Firestore and Storage

## Setup Instructions

### 1. Firebase Console Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project named "looklab-project"
3. Enable the following services:
   - Authentication (Enable Apple Sign-In provider)
   - Cloud Firestore
   - Cloud Storage
   - Cloud Functions
4. Add iOS app with bundle ID: `us.looklab`
5. Download `GoogleService-Info.plist`
6. Replace the placeholder file in `looklab/looklab/GoogleService-Info.plist`

### 2. Google Cloud Console Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Enable Vertex AI API for your project
3. Make sure billing is enabled for Cloud Functions and Vertex AI

### 3. Xcode Project Setup

1. Open `looklab.xcodeproj` in Xcode
2. Add Firebase SDK dependencies via Swift Package Manager:
   - Go to File → Add Package Dependencies
   - Add `https://github.com/firebase/firebase-ios-sdk`
   - Select the following products:
     - FirebaseAuth
     - FirebaseFirestore
     - FirebaseFunctions
     - FirebaseStorage
3. Ensure Apple Sign-In capability is enabled in project settings
4. Replace the placeholder `GoogleService-Info.plist` with your real one

### 4. Backend Deployment

```bash
cd looklab-backend
npm install
npm run build
firebase init  # Select your Firebase project
firebase deploy
```

### 5. Running the App

1. Make sure you have the real `GoogleService-Info.plist` file
2. Build and run the iOS project in Xcode
3. The app should show the onboarding screen with Apple Sign-In

## Key Files Structure

```
looklab/
├── looklab/
│   ├── Models/              # SwiftData models
│   ├── Views/              # SwiftUI views (organized by feature)
│   ├── Services/           # Firebase and Apple Auth managers
│   ├── Theme/              # Colors and typography
│   └── Utilities/          # Helper utilities
├── looklab-backend/
│   ├── src/
│   │   └── index.ts        # Cloud Functions
│   ├── firestore.rules     # Database security rules
│   ├── storage.rules       # Storage security rules
│   └── package.json        # Node.js dependencies
```

## Next Steps

After completing the setup, you can:

1. **Test Authentication**: Run the app and try Apple Sign-In
2. **Implement Onboarding Flow**: Gender selection, photo upload, body info
3. **Build Wardrobe Feature**: Upload and categorize clothing items
4. **Develop Look Builder**: Outfit creation and AI generation
5. **Add Calendar Integration**: Weekly look planning
6. **Implement Premium Features**: Trial limits and payments

## Important Security Notes

- Never commit the real `GoogleService-Info.plist` to version control
- Keep your Firebase project private
- Review and test security rules before production
- Enable proper authentication and authorization checks

## Troubleshooting

**Apple Sign-In not working?**
- Ensure you have the correct Team ID and Bundle ID
- Check that Apple Sign-In is enabled in Firebase Console
- Verify the entitlements file has the Apple Sign-In capability

**Firebase connection issues?**
- Make sure `GoogleService-Info.plist` is the real file from Firebase Console
- Check that all Firebase services are enabled in the console
- Verify your iOS bundle ID matches the one in Firebase

**Cloud Functions deployment fails?**
- Ensure billing is enabled in Google Cloud Console
- Check that all required APIs are enabled
- Make sure you're using the correct project ID

## Support

If you encounter any issues, check:
1. Firebase Console for service status
2. Xcode build logs for compilation errors
3. Firebase Functions logs for backend issues
4. Device console logs for runtime issues