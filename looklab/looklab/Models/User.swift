import Foundation
import SwiftData

@Model
final class User {
    var id: String
    var email: String?
    var fullName: String?
    var gender: Gender
    var facePhotoURL: String?
    var bodyPhotoURL: String?
    var facePhotoData: Data?
    var bodyPhotoData: Data?
    var height: Double?
    var weight: Double?
    var skinTone: SkinTone?
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String, email: String? = nil, fullName: String? = nil, gender: Gender = .notSpecified) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.gender = gender
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var isOnboardingComplete: Bool {
        return gender != .notSpecified && 
               facePhotoData != nil && 
               height != nil && 
               weight != nil && 
               skinTone != nil
    }
}

enum Gender: String, CaseIterable, Codable {
    case male = "male"
    case female = "female"
    case nonBinary = "non_binary"
    case notSpecified = "not_specified"
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .nonBinary: return "Non-binary"
        case .notSpecified: return "Prefer not to say"
        }
    }
}

enum SkinTone: String, CaseIterable, Codable {
    case veryLight = "very_light"
    case light = "light"
    case medium = "medium"
    case tan = "tan"
    case dark = "dark"
    case veryDark = "very_dark"
    
    var displayName: String {
        switch self {
        case .veryLight: return "Very Light"
        case .light: return "Light"
        case .medium: return "Medium"
        case .tan: return "Tan"
        case .dark: return "Dark"
        case .veryDark: return "Very Dark"
        }
    }
}