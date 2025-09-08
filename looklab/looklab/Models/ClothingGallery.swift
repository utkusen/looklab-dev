import Foundation

struct ClothingGallery {
    static func getGalleryItems(for interest: FashionInterest, category: ClothingCategory) -> [ClothingGalleryItem] {
        let items = getSampleItems(for: interest, category: category)
        return sort(items: items, for: category)
    }
    
    private static func mapCategoryToImagePath(_ category: ClothingCategory) -> String {
        switch category {
        case .tops:
            return "top"
        case .bottoms:
            return "bottom"
        case .fullbody:
            return "fullbody"
        case .outerwear:
            return "outwear"
        case .shoes:
            return "shoe"
        case .accessories:
            return "accessories"
        case .head:
            return "head"
        }
    }
    
    private static func getSampleItems(for interest: FashionInterest, category: ClothingCategory) -> [ClothingGalleryItem] {
        let sampleItems = getSampleItemsForCategory(interest: interest, category: category)
        
        return sampleItems.map { item in
            ClothingGalleryItem(
                id: UUID().uuidString,
                imagePath: item.imageName,
                name: item.displayName,
                category: category
            )
        }
    }

    // MARK: - Sorting by sub-type (kind)

    private static func sort(items: [ClothingGalleryItem], for category: ClothingCategory) -> [ClothingGalleryItem] {
        let priority = kindPriority(for: category)
        return items.sorted { a, b in
            let ka = inferKind(from: "\(a.name) \(a.imagePath)", for: category)
            let kb = inferKind(from: "\(b.name) \(b.imagePath)", for: category)
            let ia = priority.firstIndex(of: ka) ?? priority.count
            let ib = priority.firstIndex(of: kb) ?? priority.count
            if ia != ib { return ia < ib }
            // Group within the same kind by name
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }

    private static func kindPriority(for category: ClothingCategory) -> [String] {
        switch category {
        case .tops:
            return [
                "tshirt", "polo", "shirt", "sweater", "hoodie", "blouse", "tank", "crop", "other"
            ]
        case .bottoms:
            return [
                "jeans", "chinos", "pants", "leggings", "shorts", "skirt", "sarong", "other"
            ]
        case .outerwear:
            return [
                "blazer", "jacket", "coat", "trench", "parka", "puffer", "cardigan", "vest", "shacket", "cape", "other"
            ]
        case .fullbody:
            return [
                "dress", "jumpsuit", "suit", "tuxedo", "tracksuit", "other"
            ]
        case .shoes:
            return [
                "sneakers", "boots", "loafers", "oxfords", "heels", "sandals", "flats", "other"
            ]
        case .accessories:
            return [
                "bag", "belt", "watch", "tie", "scarf", "sunglasses", "gloves", "other"
            ]
        case .head:
            return [
                "hat", "other"
            ]
        }
    }

    private static func inferKind(from name: String, for category: ClothingCategory) -> String {
        let lower = name.lowercased()
        switch category {
        case .tops:
            if lower.contains("t-shirt") || lower.contains("tshirt") || lower.contains("t shirt") || lower.contains("tee") { return "tshirt" }
            if lower.contains("polo") { return "polo" }
            if lower.contains("shirt") { return "shirt" }
            if lower.contains("sweater") || lower.contains("jumper") { return "sweater" }
            if lower.contains("hoodie") { return "hoodie" }
            if lower.contains("blouse") { return "blouse" }
            if lower.contains("tank") || lower.contains("camisole") { return "tank" }
            if lower.contains("crop") { return "crop" }
            return "other"
        case .bottoms:
            if lower.contains("jeans") { return "jeans" }
            if lower.contains("chino") { return "chinos" }
            if lower.contains("legging") { return "leggings" }
            if lower.contains("short") { return "shorts" }
            if lower.contains("skirt") { return "skirt" }
            if lower.contains("sarong") { return "sarong" }
            if lower.contains("pants") || lower.contains("trouser") || lower.contains("slacks") { return "pants" }
            return "other"
        case .outerwear:
            if lower.contains("blazer") { return "blazer" }
            if lower.contains("puffer") { return "puffer" }
            if lower.contains("trench") { return "trench" }
            if lower.contains("parka") { return "parka" }
            if lower.contains("coat") { return "coat" }
            if lower.contains("jacket") { return "jacket" }
            if lower.contains("cardigan") { return "cardigan" }
            if lower.contains("vest") || lower.contains("gilet") { return "vest" }
            if lower.contains("shacket") { return "shacket" }
            if lower.contains("cape") { return "cape" }
            return "other"
        case .fullbody:
            if lower.contains("dress") { return "dress" }
            if lower.contains("jumpsuit") { return "jumpsuit" }
            if lower.contains("tracksuit") { return "tracksuit" }
            if lower.contains("tuxedo") { return "tuxedo" }
            if lower.contains("suit") { return "suit" }
            return "other"
        case .shoes:
            if lower.contains("sneaker") { return "sneakers" }
            if lower.contains("boot") { return "boots" }
            if lower.contains("loafer") { return "loafers" }
            if lower.contains("oxford") { return "oxfords" }
            if lower.contains("heel") { return "heels" }
            if lower.contains("sandal") { return "sandals" }
            if lower.contains("flat") { return "flats" }
            return "other"
        case .accessories:
            if lower.contains("bag") || lower.contains("purse") || lower.contains("tote") { return "bag" }
            if lower.contains("belt") { return "belt" }
            if lower.contains("watch") { return "watch" }
            if lower.contains("tie") { return "tie" }
            if lower.contains("scarf") { return "scarf" }
            if lower.contains("sunglass") || lower.contains("glasses") { return "sunglasses" }
            if lower.contains("glove") { return "gloves" }
            return "other"
        case .head:
            if lower.contains("hat") || lower.contains("beanie") || lower.contains("cap") { return "hat" }
            return "other"
        }
    }
    
    private static func getSampleItemsForCategory(interest: FashionInterest, category: ClothingCategory) -> [SampleItem] {
        let genderPath = interest == .male ? "men" : "women"
        let categoryPath = mapCategoryToImagePath(category)
        
        guard let resourcePath = Bundle.main.resourcePath else {
            print("Could not get bundle resource path")
            return []
        }
        
        let fullPath = "\(resourcePath)/ClothingImages/\(genderPath)/\(categoryPath)"
        
        do {
            let fileManager = FileManager.default
            let files = try fileManager.contentsOfDirectory(atPath: fullPath)
            
            let webpFiles = files.filter { $0.hasSuffix(".webp") && !$0.hasPrefix(".") }
            
            return webpFiles.map { filename in
                let imagePath = "ClothingImages/\(genderPath)/\(categoryPath)/\(filename)"
                return SampleItem(
                    imageName: imagePath,
                    displayName: formatItemName(filename)
                )
            }
        } catch {
            // Fallback: If the folder structure isn't preserved in the app bundle,
            // scan all bundled .webp files and filter by filename prefix.
            print("Error reading directory \(fullPath): \(error). Falling back to filename-based search.")
            let allWebPURLs = Bundle.main.urls(forResourcesWithExtension: "webp", subdirectory: nil) ?? []
            let expectedPrefix = "\(genderPath)_\(categoryPath)_"
            let matching = allWebPURLs.filter { $0.lastPathComponent.hasPrefix(expectedPrefix) }
            
            // Map found URLs to relative paths within the bundle so they can be loaded via resourcePath.
            let resourcePrefix = resourcePath.hasSuffix("/") ? resourcePath : resourcePath + "/"
            return matching.map { url in
                let absolutePath = url.path
                let relativePath = absolutePath.hasPrefix(resourcePrefix)
                    ? String(absolutePath.dropFirst(resourcePrefix.count))
                    : url.lastPathComponent
                return SampleItem(
                    imageName: relativePath,
                    displayName: formatItemName(url.lastPathComponent)
                )
            }
        }
    }
    
    private struct SampleItem {
        let imageName: String
        let displayName: String
    }
    
    private static func formatItemName(_ filename: String) -> String {
        // Remove file extension
        var name = filename.replacingOccurrences(of: ".webp", with: "")
        
        // Remove gender prefix (men_, women_)
        if name.hasPrefix("men_") {
            name = String(name.dropFirst(4))
        } else if name.hasPrefix("women_") {
            name = String(name.dropFirst(6))
        }
        
        // Remove category prefix (top_, bottom_, etc.)
        let categories = ["top_", "bottom_", "fullbody_", "outwear_", "shoe_", "accessories_", "head_"]
        for category in categories {
            if name.hasPrefix(category) {
                name = String(name.dropFirst(category.count))
                break
            }
        }
        
        // Replace underscores with spaces and capitalize
        return name
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}

struct ClothingGalleryItem: Identifiable, Hashable {
    let id: String
    let imagePath: String
    let name: String
    let category: ClothingCategory
    
    var bundleImagePath: String {
        return imagePath
    }
}
