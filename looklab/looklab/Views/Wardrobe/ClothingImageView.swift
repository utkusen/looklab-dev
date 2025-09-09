import SwiftUI

struct ClothingImageView: View {
    let imagePath: String?
    let category: ClothingCategory
    let size: CGSize
    var cornerRadius: CGFloat = 16
    
    var body: some View {
        if let imagePath = imagePath {
            BundleImageView(
                imagePath: imagePath,
                size: size,
                cornerRadius: cornerRadius,
                placeholder: category.iconName
            )
        } else {
            BundleImageView(
                imagePath: "", // Empty path will show placeholder
                size: size,
                cornerRadius: cornerRadius,
                placeholder: category.iconName
            )
        }
    }
}


// Enhanced ClothingItemCard with responsive sizing to grid cell
struct EnhancedClothingItemCard: View {
    let item: ClothingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Responsive image container that matches the grid cell width
            ZStack { Color.clear }
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    GeometryReader { geo in
                        let w = geo.size.width
                        ClothingImageView(
                            imagePath: item.imageURL,
                            category: item.category,
                            size: CGSize(width: w, height: w),
                            cornerRadius: 12
                        )
                    }
                }

            // Item info with better typography
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.theme.caption1)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.theme.textPrimary)
                    .lineLimit(1)
                if let brand = item.brand {
                    Text(brand)
                        .font(.theme.caption2)
                        .foregroundColor(Color.theme.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(8)
        .background(Color.theme.surface)
        .cornerRadius(16)
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 4,
            x: 0,
            y: 2
        )
        .frame(maxWidth: .infinity)
    }
}

// Large size variant for gallery
struct LargeClothingImageView: View {
    let item: ClothingGalleryItem
    let isSelected: Bool
    var showCategoryBadge: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            BundleImageView(
                imagePath: item.imagePath,
                size: CGSize(width: 180, height: 200),
                cornerRadius: 16,
                placeholder: item.category.iconName
            )
            .overlay(
                // Selection border highlight
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.theme.primary.opacity(isSelected ? 0.95 : 0), lineWidth: 2)
            )
            .overlay(
                // Selection overlay
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.theme.primary.opacity(isSelected ? 0.10 : 0))
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(Color.theme.primary)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 22, height: 22)
                    .padding(8)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .overlay(alignment: .bottomLeading) {
                if showCategoryBadge {
                    Text(item.category.displayName)
                        .font(.theme.caption2)
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.theme.surface.opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.theme.border.opacity(0.5), lineWidth: 1)
                        )
                        .cornerRadius(10)
                        .padding(8)
                        .transition(.opacity)
                }
            }
            
            Text(item.name)
                .font(.theme.callout)
                .fontWeight(.medium)
                .foregroundColor(Color.theme.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
                .multilineTextAlignment(.leading)
        }
        .scaleEffect(isSelected ? 0.98 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// Preview helpers
#Preview("Single Item") {
    ClothingImageView(
        imagePath: nil,
        category: .tops,
        size: CGSize(width: 120, height: 140)
    )
    .padding()
    .background(Color.theme.background)
}

#Preview("Card Grid") {
    LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ], spacing: 12) {
        ForEach(ClothingCategory.allCases.prefix(6), id: \.self) { category in
            EnhancedClothingItemCard(
                item: ClothingItem(
                    userID: "sample",
                    name: "Sample \\(category.displayName)",
                    category: category,
                    isFromGallery: category == .tops
                )
            )
        }
    }
    .padding()
    .background(Color.theme.background)
}
