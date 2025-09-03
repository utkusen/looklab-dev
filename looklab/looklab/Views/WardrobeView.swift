import SwiftUI

struct MyWardrobeView: View {
    @State private var selectedCategory: ClothingCategory = .tops
    @State private var showingAddItem = false
    @State private var savedClothingItems: [ClothingItem] = []
    
    // Add sample data to demonstrate the UI
    private let sampleItems: [ClothingItem] = [
        ClothingItem(userID: "sample", name: "Black T-Shirt", category: .tops),
        ClothingItem(userID: "sample", name: "White Sneakers", category: .shoes),
        ClothingItem(userID: "sample", name: "Blue Jeans", category: .bottoms),
        ClothingItem(userID: "sample", name: "Leather Jacket", category: .outerwear),
        ClothingItem(userID: "sample", name: "Summer Dress", category: .dresses),
        ClothingItem(userID: "sample", name: "Sunglasses", category: .accessories)
    ]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Selector
                categorySelector
                
                // Content Area
                clothingGridView
                
                Spacer()
            }
            .background(Color.black)
            .navigationTitle("Wardrobe")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddItem = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddClothingItemView(category: selectedCategory)
            }
        }
    }
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ClothingCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        Text(category.displayName)
                            .font(.headline)
                            .foregroundColor(selectedCategory == category ? .black : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? Color.white : Color.gray)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(Color.gray.opacity(0.2))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.theme.surface)
                    .frame(width: 120, height: 120)
                
                Image(systemName: selectedCategory.emptyStateIcon)
                    .font(.system(size: 40))
                    .foregroundColor(.theme.textSecondary)
            }
            
            // Text
            VStack(spacing: 8) {
                Text("No \(selectedCategory.displayName.lowercased()) yet")
                    .font(.theme.title2)
                    .foregroundColor(.theme.textPrimary)
                
                Text("Add items to start building your wardrobe")
                    .font(.theme.body)
                    .foregroundColor(.theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Add Button
            Button(action: { showingAddItem = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Item")
                }
                .font(.theme.headline)
                .foregroundColor(.theme.background)
                .frame(width: 200, height: 50)
                .background(Color.theme.primary)
                .cornerRadius(25)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private var clothingGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredItems) { item in
                    VStack {
                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        Text(item.name)
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }
    
    private var filteredItems: [ClothingItem] {
        // Use sample data combined with saved items
        let allItems = savedClothingItems + sampleItems
        return allItems.filter { $0.category == selectedCategory }
    }
}

struct CategoryButton: View {
    let category: ClothingCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: category.betterIconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .theme.primary : .theme.textSecondary)
                
                Text(category.displayName)
                    .font(.theme.caption1)
                    .foregroundColor(isSelected ? .theme.primary : .theme.textSecondary)
            }
            .frame(minWidth: 60)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.theme.primary.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ClothingItemCard: View {
    let item: ClothingItem
    
    var body: some View {
        VStack(spacing: 8) {
            // Image Container with border for dark items
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.theme.border, lineWidth: 1)
                    )
                
                // Clothing image placeholder (will be replaced with real images later)
                Image(systemName: item.category.betterIconName)
                    .font(.system(size: 40))
                    .foregroundColor(.theme.primary.opacity(0.8))
                    .frame(maxWidth: .infinity, maxHeight: 120)
            }
            .frame(height: 140)
            
            // Item name
            Text(item.name)
                .font(.theme.subheadline)
                .foregroundColor(.theme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.surfaceSecondary)
        )
    }
}


// Extension to add missing properties to ClothingCategory
extension ClothingCategory {
    var emptyStateIcon: String {
        switch self {
        case .tops: return "tshirt.fill"
        case .bottoms: return "rectangle.stack.fill"
        case .outerwear: return "coat.fill"
        case .shoes: return "shoe.fill"
        case .accessories: return "eyeglasses"
        case .dresses: return "dress.fill"
        case .undergarments: return "folder.fill"
        }
    }
    
    // Update iconName to use better SF Symbols
    var betterIconName: String {
        switch self {
        case .tops: return "tshirt"
        case .bottoms: return "rectangle.stack"
        case .outerwear: return "coat"
        case .shoes: return "shoe.2"
        case .accessories: return "eyeglasses"
        case .dresses: return "dress"
        case .undergarments: return "folder"
        }
    }
}

#Preview {
    MyWardrobeView()
        .preferredColorScheme(.dark)
}