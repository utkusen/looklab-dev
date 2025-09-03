import Foundation
import SwiftData

@Model
final class ClothingItem {
    var id: String
    var userID: String
    var name: String
    var category: ClothingCategory
    var imageURL: String?
    var color: String?
    var brand: String?
    var season: Season?
    var isFromGallery: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString, userID: String, name: String, category: ClothingCategory, imageURL: String? = nil, isFromGallery: Bool = false) {
        self.id = id
        self.userID = userID
        self.name = name
        self.category = category
        self.imageURL = imageURL
        self.isFromGallery = isFromGallery
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum ClothingCategory: String, CaseIterable, Codable {
    case tops = "tops"
    case bottoms = "bottoms"
    case fullbody = "fullbody"
    case outerwear = "outerwear"
    case shoes = "shoes"
    case accessories = "accessories"
    case head = "head"
    
    var displayName: String {
        switch self {
        case .tops: return "Tops"
        case .bottoms: return "Bottoms"
        case .fullbody: return "Full Body"
        case .outerwear: return "Outwear"
        case .shoes: return "Shoes"
        case .accessories: return "Accessories"
        case .head: return "Head"
        }
    }
    
    var iconName: String {
        switch self {
        case .tops: return "tshirt"
        case .bottoms: return "figure.taichi"
        case .fullbody: return "figure"
        case .outerwear: return "coat"
        case .shoes: return "shoe"
        case .accessories: return "eyeglasses"
        case .head: return "hat.cap.fill"
        }
    }
}

enum Season: String, CaseIterable, Codable {
    case spring = "spring"
    case summer = "summer"
    case fall = "fall"
    case winter = "winter"
    case allYear = "all_year"
    
    var displayName: String {
        switch self {
        case .spring: return "Spring"
        case .summer: return "Summer"
        case .fall: return "Fall"
        case .winter: return "Winter"
        case .allYear: return "All Year"
        }
    }
}