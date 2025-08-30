# Look Lab - Testing Apple Sign-In

## Authentication Testing Guide

### Prerequisites
1. iOS app built successfully with Firebase integration enabled
2. Firebase project configured with Apple Sign-In provider
3. iOS device or simulator for testing

### Testing Apple Sign-In Flow

#### 1. Run the App
```bash
# Open in Xcode and run in simulator
open looklab/looklab.xcodeproj

# Or build and run from command line
xcodebuild -project looklab/looklab.xcodeproj -scheme looklab -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build
```

#### 2. Test Authentication Steps

1. **Launch App**: App should show onboarding screen with "Continue with Apple" button
2. **Tap Sign-In**: Apple Sign-In dialog should appear
3. **Complete Authentication**: Use test Apple ID or Face ID/Touch ID
4. **User Creation**: Upon successful sign-in:
   - Firebase Auth should create user
   - User document should be created in Firestore
   - App should navigate to MainTabView

#### 3. Verify in Firebase Console

**Firebase Authentication:**
- Go to [Firebase Console](https://console.firebase.google.com/project/looklab-7acba/authentication/users)
- Check Users tab for new authenticated user
- Verify provider is "apple.com"

**Firestore Database:**
- Go to [Firestore Console](https://console.firebase.google.com/project/looklab-7acba/firestore/data)
- Check `users` collection for new document
- Document ID should match Firebase Auth UID
- Fields should include: email, fullName, gender, timestamps

#### 4. Expected Flow

```
1. App Launch → OnboardingView (not signed in)
2. Tap "Continue with Apple" → Apple Sign-In dialog
3. Authentication Success → FirebaseManager.isSignedIn = true
4. User data saved → Firestore users collection
5. Navigate to → MainTabView (signed in state)
```

#### 5. Testing Sign Out

To test sign out functionality, add this to ProfileView:
```swift
Button("Sign Out") {
    FirebaseManager.shared.signOut()
}
```

### Troubleshooting

**Common Issues:**
1. **Apple Sign-In fails**: Check bundle ID matches Firebase configuration
2. **User not created in Firestore**: Check Firestore security rules
3. **App doesn't navigate**: Verify FirebaseManager.isSignedIn state

**Debug Logs:**
- Check Xcode console for Firebase initialization messages
- Look for authentication success/failure logs
- Verify user data save completion

### Production Readiness

✅ **Completed:**
- Firebase Auth with Apple Sign-In configured
- User document creation in Firestore
- Authentication state management
- Custom domain configuration

🔄 **Next Steps:**
- Test on physical device
- Add onboarding flow (gender, photos, body measurements)
- Implement wardrobe management
- Add AI outfit generation UI