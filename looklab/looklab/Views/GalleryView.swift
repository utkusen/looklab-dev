import SwiftUI

struct GalleryView: View {
    @Environment(\.dismiss) private var dismiss
    let category: ClothingCategory
    
    @State private var selectedGender: Gender = .women
    @State private var galleryItems: [GalleryItem] = []
    @State private var isLoading = true
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Gender Selector
                    genderSelector
                    
                    // Content
                    if isLoading {
                        loadingView
                    } else if galleryItems.isEmpty {
                        emptyStateView
                    } else {
                        galleryGridView
                    }
                }
            }
            .navigationTitle("Gallery")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.theme.textSecondary)
                }
            }
            .onAppear {
                loadGalleryItems()
            }
            .onChange(of: selectedGender) { _ in
                loadGalleryItems()
            }
        }
    }
    
    private var genderSelector: some View {
        HStack(spacing: 0) {
            ForEach(Gender.allCases, id: \.self) { gender in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedGender = gender
                    }
                }) {
                    Text(gender.displayName)
                        .font(.theme.headline)
                        .foregroundColor(selectedGender == gender ? .theme.background : .theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            selectedGender == gender ? Color.theme.primary : Color.clear
                        )
                }
            }
        }
        .background(Color.theme.surface)
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.theme.primary)
            
            Text("Loading gallery...")
                .font(.theme.body)
                .foregroundColor(.theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.theme.textSecondary)
            
            VStack(spacing: 8) {
                Text("No items found")
                    .font(.theme.title2)
                    .foregroundColor(.theme.textPrimary)
                
                Text("This category doesn't have any items yet")
                    .font(.theme.body)
                    .foregroundColor(.theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
    
    private var galleryGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(galleryItems) { item in
                    GalleryItemCard(item: item) {
                        // Handle item selection
                        handleItemSelection(item)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }
    
    private func loadGalleryItems() {
        isLoading = true
        galleryItems = []
        
        // Simulate loading delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            galleryItems = loadItemsFromBundle()
            isLoading = false
        }
    }
    
    private func loadItemsFromBundle() -> [GalleryItem] {
        // For now, return sample data since images cause build conflicts
        // TODO: Load from actual image directory when build issues are resolved
        return createSampleItems()
    }
    
    private func createSampleItems() -> [GalleryItem] {
        let sampleNames: [String] = {
            switch (selectedGender, category) {
            case (.women, .tops):
                return ["Black T-Shirt", "White Blouse", "Striped Top", "Knit Sweater", "Tank Top"]
            case (.women, .bottoms):
                return ["Black Jeans", "White Chinos", "Denim Shorts", "Dress Pants", "Leggings"]
            case (.women, .outerwear):
                return ["Black Blazer", "Denim Jacket", "Cardigan", "Trench Coat", "Leather Jacket"]
            case (.women, .shoes):
                return ["Black Boots", "White Sneakers", "High Heels", "Canvas Shoes", "Loafers"]
            case (.men, .tops):
                return ["Black T-Shirt", "White Shirt", "Polo Shirt", "Hoodie", "Tank Top"]
            case (.men, .bottoms):
                return ["Black Jeans", "Chinos", "Shorts", "Dress Pants", "Joggers"]
            case (.men, .outerwear):
                return ["Black Blazer", "Denim Jacket", "Bomber Jacket", "Hoodie", "Leather Jacket"]
            case (.men, .shoes):
                return ["Black Boots", "White Sneakers", "Dress Shoes", "Canvas Shoes", "Loafers"]
            default:
                return ["Sample Item 1", "Sample Item 2", "Sample Item 3"]
            }
        }()
        
        return sampleNames.enumerated().map { index, name in
            GalleryItem(
                id: "\(selectedGender.rawValue)_\(category.rawValue)_\(index)",
                name: name,
                imagePath: "placeholder", // Placeholder path
                category: category,
                gender: selectedGender
            )
        }
    }
    
    private func handleItemSelection(_ item: GalleryItem) {
        // TODO: Add item to user's wardrobe
        print("Selected item: \(item.name)")
        dismiss()
    }
}

struct GalleryItemCard: View {
    let item: GalleryItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Image Container with enhanced visibility for dark items
                ZStack {
                    // Background with subtle gradient for better contrast
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.theme.surface,
                                    Color.theme.surfaceSecondary
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Subtle inner border for better definition
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.theme.border.opacity(0.3),
                                    Color.theme.border.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                    
                    // Clothing image placeholder with icon
                    Image(systemName: item.category.iconName)
                        .font(.system(size: 30))
                        .foregroundColor(.theme.primary.opacity(0.8))
                        .frame(maxWidth: .infinity, maxHeight: 100)
                        .background(
                            // Very subtle radial highlight behind the image
                            // to help dark items pop
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.03),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Item name
                Text(item.name)
                    .font(.theme.caption1)
                    .foregroundColor(.theme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 32)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.surface.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.theme.border.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func loadImage(from path: String) -> UIImage? {
        guard let bundlePath = Bundle.main.resourcePath else {
            return nil
        }
        
        let fullImagePath = "\(bundlePath)/\(path)"
        return UIImage(contentsOfFile: fullImagePath)
    }
}

// Gender enum
enum Gender: String, CaseIterable {
    case men = "men"
    case women = "women"
    
    var displayName: String {
        switch self {
        case .men: return "Men"
        case .women: return "Women"
        }
    }
}

// Gallery item model
struct GalleryItem: Identifiable {
    let id: String
    let name: String
    let imagePath: String
    let category: ClothingCategory
    let gender: Gender
}

#Preview {
    GalleryView(category: .tops)
        .preferredColorScheme(.dark)
}