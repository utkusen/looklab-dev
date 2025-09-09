import SwiftUI
import SwiftData

struct WardrobeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var clothingItems: [ClothingItem]
    @State private var showingAddItemSheet = false
    
    // Sample user for demonstration - in real app this would come from user session
    private let sampleUser = User(id: "sample", fashionInterest: .male)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(ClothingCategory.allCases, id: \.self) { category in
                        CategorySection(
                            category: category,
                            items: itemsFor(category: category)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .background(Color.theme.background.ignoresSafeArea())
            .navigationTitle("Wardrobe")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddItemSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(Color.theme.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAddItemSheet) {
                AddItemSheet(user: sampleUser)
            }
        }
    }
    
    private func itemsFor(category: ClothingCategory) -> [ClothingItem] {
        return clothingItems.filter { $0.category == category }
    }
}

struct CategorySection: View {
    let category: ClothingCategory
    let items: [ClothingItem]
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteConfirm = false
    @State private var itemPendingDelete: ClothingItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category Header
            HStack {
                Image(systemName: category.iconName)
                    .font(.title2)
                    .foregroundColor(Color.theme.accent)
                    .frame(width: 24, height: 24)
                
                Text(category.displayName)
                    .font(.theme.title3)
                    .foregroundColor(Color.theme.textPrimary)
                
                Spacer()
                
                Text("\(items.count)")
                    .font(.theme.caption1)
                    .foregroundColor(Color.theme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.theme.surface)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 4)
            
            // Items Grid
            if items.isEmpty {
                EmptyStateView(category: category)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(items, id: \.id) { item in
                        EnhancedClothingItemCard(item: item)
                            .contextMenu {
                                Button(role: .destructive) {
                                    itemPendingDelete = item
                                    showDeleteConfirm = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .alert("Delete item?", isPresented: $showDeleteConfirm, presenting: itemPendingDelete) { item in
            Button("Delete", role: .destructive) {
                modelContext.delete(item)
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {}
        } message: { item in
            Text("This will remove \(item.name) from your wardrobe.")
        }
    }
}

struct EmptyStateView: View {
    let category: ClothingCategory
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: category.iconName)
                .font(.system(size: 40))
                .foregroundColor(Color.theme.textTertiary)
                .opacity(0.6)
            
            Text("No \(category.displayName.lowercased()) yet")
                .font(.theme.callout)
                .foregroundColor(Color.theme.textSecondary)
            
            Text("Tap the + button to add your first item")
                .font(.theme.caption1)
                .foregroundColor(Color.theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.theme.surface)
        .cornerRadius(16)
    }
}


#Preview {
    WardrobeView()
        .modelContainer(for: [ClothingItem.self, User.self])
}
