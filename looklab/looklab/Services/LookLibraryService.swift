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

    // MARK: - Delete
    func delete(look: Look, in context: ModelContext) {
        // Remove from its category list
        if let catID = look.category {
            let cats = (try? context.fetch(FetchDescriptor<LookCategory>())) ?? []
            if let cat = cats.first(where: { $0.id == catID }) {
                cat.lookIDs.removeAll { $0 == look.id }
            }
        }
        // Attempt to remove stored image file(s) (best-effort)
        if let stored = look.selectedImageURL ?? look.generatedImageURLs.first,
           let url = ImageStorage.resolveURL(from: stored) {
            try? FileManager.default.removeItem(at: url)
        }
        for name in look.generatedImageURLs {
            if let url = ImageStorage.resolveURL(from: name) {
                try? FileManager.default.removeItem(at: url)
            }
        }
        context.delete(look)
        try? context.save()
    }

    // Delete a category; reassign contained looks to Default. Returns the default category.
    @discardableResult
    func deleteCategory(_ category: LookCategory, in context: ModelContext) -> LookCategory {
        let def = ensureDefaultCategory(userID: category.userID, in: context)
        // Prevent deleting the default category itself
        if category.id == def.id { return def }

        // Move any looks to default
        let looks = (try? context.fetch(FetchDescriptor<Look>())) ?? []
        for look in looks where look.category == category.id {
            assign(look, to: def, in: context)
        }
        context.delete(category)
        try? context.save()
        return def
    }
}
