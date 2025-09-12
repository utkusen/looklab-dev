# Repository Guidelines

## App Purpose & UX Principles
- Generates outfit images by sending selected clothes to Google Gemini API (`gemini-2.5-flash-image-preview`).
- Design: dark, modern, premium; keep flows simple and uncluttered.

## Project Structure
- `looklab/`: iOS SwiftUI app
  - `looklab/Models`, `Views`, `Services`, `Theme`, `Utilities`
  - Tests: `looklab/looklabTests`, `looklab/looklabUITests`
- `looklab-backend/`: Firebase Cloud Functions (TypeScript)
  - Source: `src/index.ts` → built to `lib/`; config in `firebase.json`, `firestore.rules`, `storage.rules`.

## Build & Run
- iOS build: `xcodebuild -project looklab/looklab.xcodeproj -scheme looklab build`
- iOS tests: `xcodebuild -project looklab/looklab.xcodeproj -scheme looklab -destination 'platform=iOS Simulator,name=iPhone 16' test`
- Backend (if needed): `cd looklab-backend && npm ci && npm run build && npm run serve`

## Coding Style & Conventions (iOS)
- 4‑space indent; types `PascalCase`, vars/methods `camelCase`.
- Views: `Views/<Feature>/<Name>View.swift`; keep views stateless; move IO/business logic to `Services`.
- Assets: `img_*` for images, `ic_*` for symbols; prefer SF Symbols.
- Navigation/state: SwiftUI + SwiftData; avoid singletons except Firebase managers.

## Feature Sections (iOS)
- Wardrobe: capture/upload clothes or pick from gallery (tops, bottoms, layers, shoes, dresses).
- Build a Look: pick items + background (elevator, street, restaurant, cafe, plain, beach) → “Build”.
- My Looks: custom categories; “Re-create” opens Build with selected items.
- Calendar: 7‑day planner; attach looks; show weather/feels‑like by location.
- Profile: manage face/body photos and sizes; multiple body photos; delete account.

## Testing Guidelines
- Prioritize UI tests for onboarding, wardrobe upload, look build, and re-create flows.
- Name: `FeatureNameTests.swift`; run with the iOS tests command above.

## Security
- Never commit real `GoogleService-Info.plist` or secrets.
- Validate Firestore/Storage rules with emulators before deploy.

## Writing Style

- After a task done, don't write very long text. Summarize what you did and give directions to user if you need.

## Backend Integration
- Callable: `buildLook` (Firebase Functions v2). iOS sends base64 inline images grouped by category and text fields `FACE_DESC`, `BODY_DESC`, `ENV_INFO`, `NOTES`.
- Model: `gemini-2.5-flash-image-preview`. The system prompt lives in `looklab-backend/src/index.ts` and mirrors `sample-gemini-project/prompt.txt`. Keep them in sync when editing.
- Response: `{ image: { data: <base64>, mimeType: <string> } }`. iOS decodes with `UIImage(data:)`.
- Secrets: set `GEMINI_API_KEY` using Firebase Secrets. Example (do not paste real keys):
  - `cd looklab-backend`
  - `npm ci && npm run build`
  - `firebase functions:secrets:set GEMINI_API_KEY` (for local emulator and deploy)
  - Run emulators: `npm run serve`

## iOS ↔︎ Backend Contract
- Function name must stay `buildLook` (see `looklab/Services/FirebaseManager.swift`). If renamed, update the iOS call sites.
- Category mapping in iOS must match backend expectations:
  - iOS categories: `tops`, `bottoms`, `fullbody`, `outerwear`, `shoes`, `accessories`, `head`.
  - Payload keys: `TOPS`, `BOTTOMS`, `SHOES`, `ACCESSORIES`, `FULL_OUTFIT` (mapped in `FirebaseManager`). Keep this mapping updated if categories change.
- Backgrounds: `BackgroundType` options map to `envInfoText` in `looklab/Utilities/EnvironmentMapping.swift`. If adding a background, update both the enum and `envInfoText`, plus the icon mapping in `BackgroundPicker`.

## Assets & Storage
- Bundle gallery images live under `ClothingImages/<gender>/<category>/<file>.webp` and are surfaced by `ClothingGallery`.
- Firebase Storage path convention (used by tooling): `gallery/<gender>/<category>/<file>.webp`.

## Local Development
- Emulators: `cd looklab-backend && npm ci && npm run build && npm run serve` to run Functions locally. Use `functions:secrets:set` so emulators can access `GEMINI_API_KEY`.
- iOS app: can point to callable functions directly (default) or via Hosting rewrites if configured. Current code uses `Functions.functions()` without region override; adjust if you deploy to non‑default region.
- Do not commit real `GoogleService-Info.plist`. Use a placeholder for local runs and keep credentials out of VCS.

## Deployment Policy
- If you change backend code under `looklab-backend/`, also deploy those changes to Firebase Functions.
- Commands:
  - `cd looklab-backend`
  - `npm ci && npm run build`
  - Ensure secret exists: `firebase functions:secrets:set GEMINI_API_KEY`
  - Deploy: `npm run deploy` (or `firebase deploy --only functions`)
  - Make sure you are authenticated and targeting the correct project: `firebase login` and `firebase use <project>`.

## Testing Notes
- UI flows to prioritize: onboarding, wardrobe upload, build look, re‑create from My Looks. Place tests under `looklab/looklabUITests` and name them `FeatureNameTests.swift`.
- Simulator example: `xcodebuild -project looklab/looklab.xcodeproj -scheme looklab -destination 'platform=iOS Simulator,name=iPhone 16' test`.
- Backend: verify callable locally with the emulator using sample inputs from `sample-gemini-project` before deploying.
