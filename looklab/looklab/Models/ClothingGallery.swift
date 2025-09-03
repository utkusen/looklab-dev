import Foundation

struct ClothingGallery {
    static func getGalleryItems(for interest: FashionInterest, category: ClothingCategory) -> [GalleryItem] {
        return getSampleItems(for: interest, category: category)
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
    
    private static func getSampleItems(for interest: FashionInterest, category: ClothingCategory) -> [GalleryItem] {
        let sampleItems = getSampleItemsForCategory(interest: interest, category: category)
        
        return sampleItems.map { item in
            GalleryItem(
                id: UUID().uuidString,
                imagePath: item.imageName,
                name: item.displayName,
                category: category
            )
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
            
            return webpFiles.prefix(8).map { filename in
                let imagePath = "ClothingImages/\(genderPath)/\(categoryPath)/\(filename)"
                return SampleItem(
                    imageName: imagePath,
                    displayName: formatItemName(filename)
                )
            }
        } catch {
            print("Error reading directory \(fullPath): \(error)")
            return []
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

struct GalleryItem: Identifiable, Hashable {
    let id: String
    let imagePath: String
    let name: String
    let category: ClothingCategory
    
    var bundleImagePath: String {
        return imagePath
    }
}

