import SwiftUI
import SwiftData

struct GallerySelectionView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedCategory: ClothingCategory = .tops
    @State private var selectedItem: ClothingGalleryItem?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                categorySelector
                
                Divider()
                    .background(Color.theme.border)
                
                galleryGrid
                
                addButton
            }
            .background(Color.theme.background.ignoresSafeArea())
            .navigationTitle("Choose from Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.theme.textSecondary)
                }
            }
        }
    }
    
    private var categorySelector: some View {
        CategorySelector(
            selectedCategory: $selectedCategory,
            categories: ClothingCategory.allCases
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var galleryGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                ForEach(galleryItems, id: \.id) { item in
                    Button(action: {
                        selectedItem = item
                    }) {
                        LargeClothingImageView(
                            item: item,
                            isSelected: selectedItem?.id == item.id
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color.theme.background)
    }
    
    @ViewBuilder
    private var addButton: some View {
        if let selectedItem = selectedItem {
            VStack(spacing: 0) {
                Divider()
                    .background(Color.theme.border)
                
                Button(action: {
                    addItemToWardrobe(selectedItem)
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        
                        Text("Add to Wardrobe")
                            .font(.theme.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.theme.accent)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.theme.surface)
            }
        }
    }
    
    private var galleryItems: [ClothingGalleryItem] {
        ClothingGallery.getGalleryItems(for: user.fashionInterest, category: selectedCategory)
    }
    
    private func addItemToWardrobe(_ galleryItem: ClothingGalleryItem) {
        let clothingItem = ClothingItem(
            userID: user.id,
            name: galleryItem.name,
            category: galleryItem.category,
            imageURL: galleryItem.imagePath,
            isFromGallery: true
        )
        
        modelContext.insert(clothingItem)
        try? modelContext.save()
        
        dismiss()
    }
}

struct CategorySelector: View {
    @Binding var selectedCategory: ClothingCategory
    let categories: [ClothingCategory]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct CategoryChip: View {
    let category: ClothingCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .font(.system(size: 16))
                
                Text(category.displayName)
                    .font(.theme.callout)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : Color.theme.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected ? Color.theme.accent : Color.theme.surface
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.clear : Color.theme.border.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


#Preview {
    GallerySelectionView(user: User(id: "sample", fashionInterest: .male))
        .modelContainer(for: [ClothingItem.self, User.self])
}