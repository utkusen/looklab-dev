import Foundation
import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import FirebaseStorage

final class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    @Published var isSignedIn = false
    @Published var currentUser: User?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var functions = Functions.functions()
    private let storage = Storage.storage()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private init() {
        // Firebase should already be configured by the app before this singleton is accessed
        setupAuthListener()
        configureCustomDomain()
    }
    
    private func configureCustomDomain() {
        // Optional: read a custom Functions domain from Info.plist
        // Add key "FunctionsCustomDomain" (e.g., https://api.example.com)
        if let raw = Bundle.main.object(forInfoDictionaryKey: "FunctionsCustomDomain") as? String {
            let domain = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !domain.isEmpty {
                // FirebaseFunctions expects String for customDomain (e.g., https://api.example.com)
                functions = Functions.functions(customDomain: domain)
            }
        }
    }
    
    private func setupAuthListener() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            DispatchQueue.main.async {
                if let firebaseUser = firebaseUser {
                    self?.isSignedIn = true
                    self?.loadUserData(uid: firebaseUser.uid)
                } else {
                    self?.isSignedIn = false
                    self?.currentUser = nil
                }
            }
        }
    }
    
    private func loadUserData(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            if let document = document, document.exists,
               let data = document.data() {
                DispatchQueue.main.async {
                    self?.currentUser = self?.parseUserData(uid: uid, data: data)
                }
            }
        }
    }
    
    private func parseUserData(uid: String, data: [String: Any]) -> User? {
        let email = data["email"] as? String
        let fullName = data["fullName"] as? String
        let fashionInterestString = data["fashionInterest"] as? String ?? "not_specified"
        let fashionInterest = FashionInterest(rawValue: fashionInterestString) ?? .notSpecified
        
        let user = User(id: uid, email: email, fullName: fullName, fashionInterest: fashionInterest)
        user.facePhotoURL = data["facePhotoURL"] as? String
        user.bodyPhotoURL = data["bodyPhotoURL"] as? String
        user.height = data["height"] as? Double
        user.weight = data["weight"] as? Double
        
        if let skinToneString = data["skinTone"] as? String {
            user.skinTone = SkinTone(rawValue: skinToneString)
        }
        if let unitSystemString = data["unitSystem"] as? String, let unit = UnitSystem(rawValue: unitSystemString) {
            user.unitSystem = unit
        }
        if let age = data["age"] as? Int { user.age = age }
        if let hairColorString = data["hairColor"] as? String { user.hairColor = HairColor(rawValue: hairColorString) }
        if let hairTypeString = data["hairType"] as? String { user.hairType = HairType(rawValue: hairTypeString) }
        if let beardTypeString = data["beardType"] as? String { user.beardType = BeardType(rawValue: beardTypeString) }
        if let profileText = data["appearanceProfileText"] as? String { user.appearanceProfileText = profileText }
        
        return user
    }
    
    func signOut() {
        do {
            try auth.signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    func deleteAccount() async throws {
        guard let firebaseUser = auth.currentUser else {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user signed in"])
        }
        
        try await db.collection("users").document(firebaseUser.uid).delete()
        try await firebaseUser.delete()
    }
    
    func saveUserData(_ user: User) async throws {
        let userData: [String: Any] = [
            "email": user.email ?? "",
            "fullName": user.fullName ?? "",
            "fashionInterest": (user.fashionInterest ?? .notSpecified).rawValue,
            "facePhotoURL": user.facePhotoURL ?? "",
            "bodyPhotoURL": user.bodyPhotoURL ?? "",
            "height": user.height ?? 0,
            "weight": user.weight ?? 0,
            "skinTone": user.skinTone?.rawValue ?? "",
            "age": user.age ?? 0,
            "unitSystem": (user.unitSystem ?? .imperial).rawValue,
            "hairColor": user.hairColor?.rawValue ?? "",
            "hairType": user.hairType?.rawValue ?? "",
            "beardType": user.beardType?.rawValue ?? BeardType.none.rawValue,
            "appearanceProfileText": user.appearanceProfileText ?? "",
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("users").document(user.id).setData(userData, merge: true)
    }
    
    func generateOutfit(clothingItems: [ClothingItem], background: BackgroundType, userBodyPhoto: String?) async throws -> [String] {
        let data: [String: Any] = [
            "clothingItems": clothingItems.map { item in
                [
                    "id": item.id,
                    "name": item.name,
                    "category": item.category.rawValue,
                    "imageURL": item.imageURL ?? "",
                    "color": item.color ?? ""
                ]
            },
            "background": background.rawValue,
            "userBodyPhoto": userBodyPhoto ?? ""
        ]
        
        let result = try await functions.httpsCallable("generateOutfit").call(data)
        
        if let resultData = result.data as? [String: Any],
           let imageURLs = resultData["imageURLs"] as? [String] {
            return imageURLs
        }
        
        throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from outfit generation"])
    }

    // MARK: - Build Look with Gemini (returns single generated image)
    // Legacy signature kept for compatibility
    func buildLook(selectedItems: [ClothingItem], background: BackgroundType, user: User?) async throws -> UIImage {
        return try await buildLook(selectedItems: selectedItems, envInfo: envDescription(for: background), user: user)
    }

    // New signature: pass envInfo explicitly from UI
    func buildLook(selectedItems: [ClothingItem], envInfo: String, user: User?) async throws -> UIImage {
        return try await buildLook(selectedItems: selectedItems, envInfo: envInfo, user: user, notes: nil)
    }

    // Newest signature: explicit notes from UI (sent as NOTES)
    func buildLook(selectedItems: [ClothingItem], envInfo: String, user: User?, notes: String?) async throws -> UIImage {
        // Map items to categories expected by backend
        var tops: [[String: Any]] = []
        var bottoms: [[String: Any]] = []
        var shoes: [[String: Any]] = []
        var accessories: [[String: Any]] = []
        var fullOutfit: [[String: Any]] = []

        for item in selectedItems {
            guard let path = item.imageURL, !path.isEmpty else { continue }
            if let (b64, mime) = try await encodeImageBase64(from: path) {
                let payload: [String: Any] = ["data": b64, "mimeType": mime]
                switch item.category {
                case .tops, .outerwear:
                    tops.append(payload)
                case .bottoms:
                    bottoms.append(payload)
                case .shoes:
                    shoes.append(payload)
                case .accessories, .head, .other:
                    accessories.append(payload)
                case .fullbody:
                    fullOutfit.append(payload)
                }
            }
        }

        // Face/body descriptions from profile (text only)
        let faceDesc = faceDescription(from: user)
        let bodyDesc = bodyDescription(from: user)

        // Prefer user-provided notes; fallback to profile text for continuity
        let effectiveNotes: String = {
            let trimmed = (notes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
            return user?.appearanceProfileText ?? ""
        }()

        // Map user fashion interest to backend GENDER field
        let genderString: String = {
            switch (user?.fashionInterest ?? .notSpecified) {
            case .male: return "men"
            case .female: return "women"
            case .everything, .notSpecified: return "not specified"
            }
        }()

        let data: [String: Any] = [
            "FACE_DESC": faceDesc,
            "BODY_DESC": bodyDesc,
            "ENV_INFO": envInfo,
            "NOTES": effectiveNotes,
            "GENDER": genderString,
            "TOPS": tops,
            "BOTTOMS": bottoms,
            "SHOES": shoes,
            "ACCESSORIES": accessories,
            "FULL_OUTFIT": fullOutfit
        ]

        // Debug (no base64): confirm values being sent
        print("buildLook ENV_INFO=\(envInfo)")
        print("buildLook counts TOPS=\(tops.count) BOTTOMS=\(bottoms.count) SHOES=\(shoes.count) ACCESSORIES=\(accessories.count) FULL_OUTFIT=\(fullOutfit.count) GENDER=\(genderString)")

        let result = try await functions.httpsCallable("buildLook").call(data)
        guard let dict = result.data as? [String: Any],
              let image = dict["image"] as? [String: Any],
              let b64 = image["data"] as? String,
              let mime = image["mimeType"] as? String,
              let imgData = Data(base64Encoded: b64) else {
            throw NSError(domain: "FirebaseManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid buildLook response"])
        }

        // Some responses might be jpeg even if mime says png; UIImage handles it.
        guard let uiImage = UIImage(data: imgData) else {
            throw NSError(domain: "FirebaseManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to decode image (\(mime))"])
        }
        return uiImage
    }

    // MARK: - Helpers
    private func faceDescription(from user: User?) -> String {
        guard let user = user else { return "" }
        var parts: [String] = []
        if let hair = user.hairColor?.rawValue { parts.append(hair) }
        if let type = user.hairType?.rawValue { parts.append(type.replacingOccurrences(of: "_", with: " ")) }
        if let beard = user.beardType?.rawValue, beard != BeardType.none.rawValue { parts.append(beard.replacingOccurrences(of: "_", with: " ")) }
        return parts.isEmpty ? (user.appearanceProfileText ?? "") : parts.joined(separator: " ")
    }

    private func bodyDescription(from user: User?) -> String {
        guard let user = user else { return "" }
        var parts: [String] = []
        if let h = user.height, h > 0 { parts.append(String(format: "%.2f height", h)) }
        if let w = user.weight, w > 0 { parts.append(String(format: "%.0fkg", w)) }
        if let tone = user.skinTone?.rawValue { parts.append(tone.replacingOccurrences(of: "_", with: " ")) }
        return parts.joined(separator: ", ")
    }

    private func encodeImageBase64(from path: String) async throws -> (String, String)? {
        if path.lowercased().hasPrefix("http") {
            // Remote URL (e.g., Firebase Storage download URL)
            guard let url = URL(string: path) else { return nil }
            let (data, _) = try await URLSession.shared.data(from: url)
            let mime = mimeType(forPath: url.path)
            return (data.base64EncodedString(), mime)
        } else {
            // Bundle path
            guard let data = loadDataFromBundle(path: path) else { return nil }
            let mime = mimeType(forPath: path)
            return (data.base64EncodedString(), mime)
        }
    }

    private func mimeType(forPath path: String) -> String {
        let ext = (path as NSString).pathExtension.lowercased()
        switch ext {
        case "webp": return "image/webp"
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        default: return "image/png"
        }
    }

    private func loadDataFromBundle(path: String) -> Data? {
        guard let resourcePath = Bundle.main.resourcePath else { return nil }
        let fullPath = "\(resourcePath)/\(path)"
        if let data = NSData(contentsOfFile: fullPath) as Data? { return data }
        // Fallback by filename search
        let filename = (path as NSString).lastPathComponent
        if let urls = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: nil) {
            if let url = urls.first(where: { $0.lastPathComponent == filename }) {
                return try? Data(contentsOf: url)
            }
        }
        return nil
    }

    private func envDescription(for bg: BackgroundType) -> String {
        switch bg {
        case .elevatorMirror: return "elevator mirror selfie"
        case .street: return "busy city street outdoors"
        case .restaurant: return "restaurant interior"
        case .cafe: return "cozy cafe setting"
        case .plainBackground: return "plain studio background"
        case .beach: return "sandy beach in daylight"
        case .originalBackground: return "original photo background"
        }
    }
}
