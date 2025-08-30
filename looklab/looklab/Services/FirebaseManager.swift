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
    
    private init() {
        setupAuthListener()
    }
    
    func configure() {
        FirebaseApp.configure()
    }
    
    private func setupAuthListener() {
        auth.addStateDidChangeListener { [weak self] _, firebaseUser in
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
        let genderString = data["gender"] as? String ?? "not_specified"
        let gender = Gender(rawValue: genderString) ?? .notSpecified
        
        let user = User(id: uid, email: email, fullName: fullName, gender: gender)
        user.facePhotoURL = data["facePhotoURL"] as? String
        user.bodyPhotoURL = data["bodyPhotoURL"] as? String
        user.height = data["height"] as? Double
        user.weight = data["weight"] as? Double
        
        if let skinToneString = data["skinTone"] as? String {
            user.skinTone = SkinTone(rawValue: skinToneString)
        }
        
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
            "gender": user.gender.rawValue,
            "facePhotoURL": user.facePhotoURL ?? "",
            "bodyPhotoURL": user.bodyPhotoURL ?? "",
            "height": user.height ?? 0,
            "weight": user.weight ?? 0,
            "skinTone": user.skinTone?.rawValue ?? "",
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