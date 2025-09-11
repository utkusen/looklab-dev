import Foundation
import SwiftData

@Model
final class User {
    var id: String
    var email: String?
    var fullName: String?
    var fashionInterest: FashionInterest
    // Deprecated image-based fields (kept for backward compatibility)
    var facePhotoURL: String?
    var bodyPhotoURL: String?
    var facePhotoData: Data?
    var bodyPhotoData: Data?
    var height: Double?
    var weight: Double?
    var skinTone: SkinTone?
    // New text-based character setup fields
    var age: Int?
    var unitSystem: UnitSystem = UnitSystem.imperial
    var hairColor: HairColor?
    var hairType: HairType?
    var beardType: BeardType? = BeardType.none
    // Consolidated text that will be sent to AI/API later
    var appearanceProfileText: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String, email: String? = nil, fullName: String? = nil, fashionInterest: FashionInterest = FashionInterest.notSpecified) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.fashionInterest = fashionInterest
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var isOnboardingComplete: Bool {
        return fashionInterest != .notSpecified && appearanceProfileText?.isEmpty == false
    }
}

enum FashionInterest: String, CaseIterable, Codable {
    case male = "male"
    case female = "female"
    case everything = "everything"
    case notSpecified = "not_specified"
    
    var displayName: String {
        switch self {
        case .male: return "Men's Fashion"
        case .female: return "Women's Fashion"
        case .everything: return "Everything"
        case .notSpecified: return "Not Specified"
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

enum UnitSystem: String, CaseIterable, Codable {
    case imperial
    case metric
    
    var displayName: String {
        switch self {
        case .imperial: return "Imperial"
        case .metric: return "Metric"
        }
    }
}

enum HairColor: String, CaseIterable, Codable {
    case black, darkBrown, brown, lightBrown, blonde, platinum, red, auburn, gray, white, dyed
    
    var displayName: String {
        switch self {
        case .black: return "Black"
        case .darkBrown: return "Dark Brown"
        case .brown: return "Brown"
        case .lightBrown: return "Light Brown"
        case .blonde: return "Blonde"
        case .platinum: return "Platinum"
        case .red: return "Red"
        case .auburn: return "Auburn"
        case .gray: return "Gray"
        case .white: return "White"
        case .dyed: return "Dyed"
        }
    }
}

enum HairType: String, CaseIterable, Codable {
    case straight, wavy, curly, coily, short, medium, long, bald
    
    var displayName: String {
        switch self {
        case .straight: return "Straight"
        case .wavy: return "Wavy"
        case .curly: return "Curly"
        case .coily: return "Coily"
        case .short: return "Short"
        case .medium: return "Medium"
        case .long: return "Long"
        case .bald: return "Bald"
        }
    }
}

enum BeardType: String, CaseIterable, Codable {
    case none, stubble, shortBeard, fullBeard, goatee, mustache, trimmed
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .stubble: return "Stubble"
        case .shortBeard: return "Short Beard"
        case .fullBeard: return "Full Beard"
        case .goatee: return "Goatee"
        case .mustache: return "Mustache"
        case .trimmed: return "Trimmed"
        }
    }
}
