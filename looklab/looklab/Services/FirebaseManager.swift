import Foundation
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
    private let functions = Functions.functions()
    private let storage = Storage.storage()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private init() {
        // Firebase should already be configured by the app before this singleton is accessed
        setupAuthListener()
        configureCustomDomain()
    }
    
    private func configureCustomDomain() {
        // Configure Firebase Functions to use custom domain
        // This will route function calls through your custom domain via Firebase Hosting rewrites
        // Note: The custom domain routing is handled by Firebase Hosting rewrites in firebase.json
        // Functions will be automatically called through https://looklab.utkusen.com/api/*
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
            "fashionInterest": user.fashionInterest.rawValue,
            "facePhotoURL": user.facePhotoURL ?? "",
            "bodyPhotoURL": user.bodyPhotoURL ?? "",
            "height": user.height ?? 0,
            "weight": user.weight ?? 0,
            "skinTone": user.skinTone?.rawValue ?? "",
            "age": user.age ?? 0,
            "unitSystem": user.unitSystem.rawValue,
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
}
