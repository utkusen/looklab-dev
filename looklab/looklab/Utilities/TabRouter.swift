import Foundation
import SwiftUI

enum MainTab: Hashable {
    case wardrobe
    case build
    case myLooks
    case calendar
    case profile
}

final class TabRouter: ObservableObject {
    @Published var selection: MainTab = .build
}

