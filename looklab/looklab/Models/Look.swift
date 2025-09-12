import Foundation
import SwiftData

@Model
final class Look {
    var id: String
    var userID: String
    var name: String
    var clothingItemIDs: [String]
    var backgroundType: BackgroundType
    var generatedImageURLs: [String]
    var selectedImageURL: String?
    @Attribute(.externalStorage) var selectedImageData: Data?
    var category: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString, userID: String, name: String, clothingItemIDs: [String], backgroundType: BackgroundType) {
        self.id = id
        self.userID = userID
        self.name = name
        self.clothingItemIDs = clothingItemIDs
        self.backgroundType = backgroundType
        self.generatedImageURLs = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class LookCategory {
    var id: String
    var userID: String
    var name: String
    var lookIDs: [String]
    var createdAt: Date
    
    init(id: String = UUID().uuidString, userID: String, name: String) {
        self.id = id
        self.userID = userID
        self.name = name
        self.lookIDs = []
        self.createdAt = Date()
    }
}

@Model
final class CalendarLook {
    var id: String
    var userID: String
    var date: Date
    var lookID: String
    var createdAt: Date
    
    init(id: String = UUID().uuidString, userID: String, date: Date, lookID: String) {
        self.id = id
        self.userID = userID
        self.date = date
        self.lookID = lookID
        self.createdAt = Date()
    }
}

enum BackgroundType: String, CaseIterable, Codable {
    case elevatorMirror = "elevator_mirror"
    case street = "street"
    case restaurant = "restaurant"
    case cafe = "cafe"
    case plainBackground = "plain_background"
    case beach = "beach"
    case originalBackground = "original_background"
    
    var displayName: String {
        switch self {
        case .elevatorMirror: return "Elevator Mirror"
        case .street: return "City"
        case .restaurant: return "Restaurant"
        case .cafe: return "Cafe"
        case .plainBackground: return "Plain Background"
        case .beach: return "Beach"
        case .originalBackground: return "Original Background"
        }
    }
}
