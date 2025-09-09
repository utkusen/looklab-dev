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


// Enhanced ClothingItemCard with better image display
struct EnhancedClothingItemCard: View {
    let item: ClothingItem
    var cardSize: CGSize = CGSize(width: 120, height: 160)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Enhanced image container
            ClothingImageView(
                imagePath: item.imageURL,
                category: item.category,
                size: CGSize(width: cardSize.width, height: cardSize.height * 0.7),
                cornerRadius: 12
            )
            
            // Item info with better typography
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.theme.caption1)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.theme.textPrimary)
                    .lineLimit(1)
                
                HStack {
                    if let brand = item.brand {
                        Text(brand)
                            .font(.theme.caption2)
                            .foregroundColor(Color.theme.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    if item.isFromGallery {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundColor(Color.theme.accent)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(width: cardSize.width)
        .padding(8)
        .background(Color.theme.surface)
        .cornerRadius(16)
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

// Large size variant for gallery
struct LargeClothingImageView: View {
    let item: ClothingGalleryItem
    let isSelected: Bool
    
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
