import Foundation
import SwiftData
import UIKit

final class LookLibraryService {
    static let shared = LookLibraryService()
    private init() {}

    // MARK: - Categories
    @discardableResult
    func ensureDefaultCategory(userID: String, in context: ModelContext) -> LookCategory {
        let fetch = FetchDescriptor<LookCategory>()
        let categories = (try? context.fetch(fetch)) ?? []
        if let existing = categories.first(where: { $0.userID == userID && $0.name.lowercased() == "default" }) {
            return existing
        }
        let cat = LookCategory(userID: userID, name: "Default")
        context.insert(cat)
        try? context.save()
        return cat
    }

    func createCategory(userID: String, name: String, in context: ModelContext) -> LookCategory {
        let cat = LookCategory(userID: userID, name: name)
        context.insert(cat)
        try? context.save()
        return cat
    }

    func allCategories(userID: String, in context: ModelContext) -> [LookCategory] {
        let fetch = FetchDescriptor<LookCategory>()
        let categories = (try? context.fetch(fetch)) ?? []
        return categories.filter { $0.userID == userID }
    }

    // MARK: - Looks
    func assign(_ look: Look, to category: LookCategory, in context: ModelContext) {
        // Remove from previous category if present
        if let prevID = look.category {
            let fetch = FetchDescriptor<LookCategory>()
            if let prev = try? context.fetch(fetch).first(where: { $0.id == prevID }) {
                prev.lookIDs.removeAll { $0 == look.id }
            }
        }
        look.category = category.id
        if !category.lookIDs.contains(look.id) {
            category.lookIDs.append(look.id)
        }
        look.updatedAt = Date()
        try? context.save()
    }

    func moveLook(_ lookID: String, toCategoryID targetID: String, in context: ModelContext) {
        let looks = (try? context.fetch(FetchDescriptor<Look>())) ?? []
        let cats = (try? context.fetch(FetchDescriptor<LookCategory>())) ?? []
        guard let look = looks.first(where: { $0.id == lookID }),
              let target = cats.first(where: { $0.id == targetID }) else { return }
        assign(look, to: target, in: context)
    }
}

