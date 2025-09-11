import Foundation

extension BackgroundType {
    var envInfoText: String {
        switch self {
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

