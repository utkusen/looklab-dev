import SwiftUI
import SwiftData

// MARK: - BuildLookView (Selection stub + Build action)
// Design-first: a minimal selection summary and a Build button.
// The real selection UI will replace the placeholders later.
struct BuildLookView: View {
    @EnvironmentObject var router: TabRouter
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [ClothingItem]

    @State private var selectedTops: Set<String> = []
    @State private var selectedAccessories: Set<String> = []
    @State private var selectedOther: Set<String> = []
    @State private var selectedSingles: [ClothingCategory: String] = [:]
    @State private var background: BackgroundType = .elevatorMirror
    @State private var builderInput: LookBuilderInput?
    @State private var extraNotes: String = ""

    private struct LookBuilderInput: Identifiable {
        let id = UUID()
        let items: [ClothingItem]
        let background: BackgroundType
        let envInfo: String
        let notes: String
    }

    // Sample categories for this stub; real UI will allow picking from wardrobe/gallery
    private let singleSelectCategories: [ClothingCategory] = [.bottoms, .fullbody, .outerwear, .shoes, .head]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                // Header
                VStack(spacing: 6) {
                    Text("Build a Look")
                        .font(.theme.largeTitle)
                        .foregroundColor(.theme.textPrimary)
                    Text("Pick items and a background, then let AI style it")
                        .font(.theme.subheadline)
                        .foregroundColor(.theme.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 8)

                // Categories (bigger containers)
                BuildCard {
                    HStack { BuildSectionHeader(icon: "square.grid.2x2", title: "Pick Items"); Spacer() }
                    CategoryGrid(
                        onTap: { category in activeCategorySheet = category },
                        selections: selectionsByCategory
                    )
                }


                // Background picker (design placeholder)
                BuildCard {
                    HStack { BuildSectionHeader(icon: "photo", title: "Background"); Spacer() }
                    BackgroundPicker(background: $background)
                }

                // Extra Notes (Optional)
                BuildCard {
                    HStack { BuildSectionHeader(icon: "pencil.and.outline", title: "Extra Notes (Optional)"); Spacer() }
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $extraNotes)
                            .font(.theme.subheadline)
                            .foregroundColor(.theme.textPrimary)
                            .frame(minHeight: 86, alignment: .topLeading)
                            .padding(8)
                            .background(Color.theme.surfaceSecondary)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.theme.border, lineWidth: 1)
                            )
                        // Visible placeholder above the editor when empty
                        if extraNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Example: Shirt tucked in, sleeves rolled.")
                                .font(.theme.subheadline)
                                .foregroundColor(.theme.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .allowsHitTesting(false)
                        }
                    }
                }

                Button("Build") {
                    print("User selected background: raw=\(background.rawValue) name=\(background.displayName)")
                    let items = selectedItemsFromState
                    builderInput = LookBuilderInput(
                        items: items,
                        background: background,
                        envInfo: background.envInfoText,
                        notes: extraNotes
                    )
                }
                .buttonStyle(PrimaryButtonStyle(disabled: selectedItemsFromState.isEmpty))
                .disabled(selectedItemsFromState.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            }
            .background(Color.theme.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(item: $builderInput) { input in
            LookBuilderView(
                selectedItems: input.items,
                background: input.background,
                envInfo: input.envInfo,
                extraNotes: input.notes,
                onCancel: { builderInput = nil },
                onSaved: {
                    builderInput = nil
                    router.selection = .myLooks
                }
            )
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: Binding<Bool>(
            get: { activeCategorySheet != nil },
            set: { if !$0 { activeCategorySheet = nil } }
        )) {
            if let category = activeCategorySheet {
                if category == .tops || category == .accessories || category == .other {
                    BuildCategorySelectionSheet(
                        category: category,
                        items: items.filter { $0.category == category },
                        multiSelect: true,
                        selectedMulti: bindingForMulti(category: category),
                        selectedSingle: .constant(nil)
                    ) { activeCategorySheet = nil }
                } else {
                    BuildCategorySelectionSheet(
                        category: category,
                        items: items.filter { $0.category == category },
                        multiSelect: false,
                        selectedMulti: .constant([]),
                        selectedSingle: bindingForSingle(category: category)
                    ) { activeCategorySheet = nil }
                }
            }
        }
    }

    // Computed selections by category for thumbnails in tiles
    private var selectionsByCategory: [ClothingCategory: [ClothingItem]] {
        var dict: [ClothingCategory: [ClothingItem]] = [:]
        let singleIDs = Set(selectedSingles.values)
        let ids = selectedTops.union(selectedAccessories).union(selectedOther).union(singleIDs)
        let selected = items.filter { ids.contains($0.id) }
        for cat in [ClothingCategory.tops, .bottoms, .fullbody, .outerwear, .shoes, .accessories, .head, .other] {
            dict[cat] = selected.filter { $0.category == cat }
        }
        return dict
    }

    private var selectedItemsFromState: [ClothingItem] {
        selectionsByCategory.values.flatMap { $0 }
    }

    // Sheet routing
    @State private var activeCategorySheet: ClothingCategory?

    private func bindingForMulti(category: ClothingCategory) -> Binding<Set<String>> {
        switch category {
        case .tops: return $selectedTops
        case .accessories: return $selectedAccessories
        case .other: return $selectedOther
        default: return .constant([])
        }
    }

    private func bindingForSingle(category: ClothingCategory) -> Binding<String?> {
        Binding<String?>(
            get: { selectedSingles[category] },
            set: { newVal in selectedSingles[category] = newVal }
        )
    }

    private func mockSelectedItems() -> [ClothingItem] {
        // Create a small set of in-memory items for the visual design preview
        let uid = "preview"
        var arr: [ClothingItem] = []
        // Tops (multi)
        arr.append(ClothingItem(userID: uid, name: "White Tee", category: .tops, imageURL: "ClothingImages/men/top/men_top_white_t-shirt.webp"))
        arr.append(ClothingItem(userID: uid, name: "Denim Jacket", category: .outerwear, imageURL: "ClothingImages/men/outwear/men_outwear_blue_denim_jacket.webp"))
        // Singles
        arr.append(ClothingItem(userID: uid, name: "Black Jeans", category: .bottoms, imageURL: "ClothingImages/men/bottom/men_bottom_black_jeans.webp"))
        arr.append(ClothingItem(userID: uid, name: "White Canvas Shoes", category: .shoes, imageURL: "ClothingImages/men/shoe/men_shoe_white_canvas_shoes.webp"))
        // Accessories (multi)
        arr.append(ClothingItem(userID: uid, name: "Sunglasses", category: .accessories, imageURL: "ClothingImages/men/accessories/men_accessories_black_sunglasses.webp"))
        return arr
    }
}

// MARK: - Background Picker (design-only)
private struct BackgroundPicker: View {
    @Binding var background: BackgroundType
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(BackgroundType.allCases.filter { $0 != .originalBackground }, id: \.self) { bg in
                Button(action: { background = bg }) {
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.theme.surface)
                                .frame(height: 44)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.theme.border, lineWidth: 1))
                            Image(systemName: icon(for: bg))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.theme.accent)
                        }
                        Text(bg.displayName)
                            .font(.theme.caption2)
                            .foregroundColor(.theme.textSecondary)
                            .lineLimit(1)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(background == bg ? Color.theme.primary.opacity(0.10) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(background == bg ? Color.theme.primary : Color.clear, lineWidth: 1)
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func icon(for bg: BackgroundType) -> String {
        switch bg {
        case .elevatorMirror: return "square.split.bottomrightquarter"
        case .street: return "building.2"
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer"
        case .plainBackground: return "button.horizontal"
        case .beach: return "sun.max"
        case .originalBackground: return "photo"
        }
    }
}

// MARK: - Category Grid
private struct CategoryGrid: View {
    let onTap: (ClothingCategory) -> Void
    let selections: [ClothingCategory: [ClothingItem]]

    private let categories: [ClothingCategory] = [.tops, .bottoms, .fullbody, .outerwear, .shoes, .accessories, .head, .other]
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(categories, id: \.self) { cat in
                Button(action: { onTap(cat) }) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.theme.surfaceSecondary)
                                    .frame(width: 44, height: 44)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.theme.border, lineWidth: 1))
                                Image(systemName: cat.iconName)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.theme.accent)
                            }
                            Text(cat.displayName)
                                .font(.theme.headline)
                                .foregroundColor(.theme.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .layoutPriority(1)
                            Spacer(minLength: 0)
                        }
                        if let items = selections[cat], !items.isEmpty {
                            ThumbRow(items: items)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, minHeight: 128)
                    .background(Color.theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.theme.border, lineWidth: 1))
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ThumbRow: View {
    let items: [ClothingItem]
    private let maxThumbs = 4
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(items.prefix(maxThumbs)), id: \.id) { item in
                TinyThumb(imagePath: item.imageURL ?? "", placeholder: item.category.iconName)
            }
            if items.count > maxThumbs {
                MoreCountChip(count: items.count - maxThumbs)
            }
        }
    }
}

private struct TinyThumb: View {
    let imagePath: String
    let placeholder: String
    var body: some View {
        BundleImageView(
            imagePath: imagePath,
            size: CGSize(width: 36, height: 40),
            cornerRadius: 8,
            placeholder: placeholder
        )
    }
}

private struct MoreCountChip: View {
    let count: Int
    var body: some View {
        Text("+\(count)")
            .font(.theme.caption2)
            .foregroundColor(.theme.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.theme.surfaceSecondary)
            .cornerRadius(8)
    }
}

// MARK: - Category Selection Sheet
private struct BuildCategorySelectionSheet: View {
    let category: ClothingCategory
    let items: [ClothingItem]
    let multiSelect: Bool
    @Binding var selectedMulti: Set<String>
    @Binding var selectedSingle: String?
    var onDone: () -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: category.iconName)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.theme.accent)
                        Text("No items in \(category.displayName)")
                            .font(.theme.subheadline)
                            .foregroundColor(.theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.theme.background)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(items, id: \.id) { item in
                                CategorySelectCard(
                                    item: item,
                                    selected: isSelected(item),
                                    toggle: { toggle(item) }
                                )
                            }
                        }
                        .padding(16)
                    }
                    .background(Color.theme.background)
                }
            }
            .navigationTitle(category.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDone() }
                        .foregroundColor(.theme.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDone() }
                        .foregroundColor(.theme.primary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func isSelected(_ item: ClothingItem) -> Bool {
        if multiSelect { return selectedMulti.contains(item.id) }
        return selectedSingle == item.id
    }

    private func toggle(_ item: ClothingItem) {
        if multiSelect {
            if selectedMulti.contains(item.id) { selectedMulti.remove(item.id) } else { selectedMulti.insert(item.id) }
        } else {
            selectedSingle = selectedSingle == item.id ? nil : item.id
        }
    }
}

private struct CategorySelectCard: View {
    let item: ClothingItem
    let selected: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            VStack(alignment: .leading, spacing: 8) {
                BundleImageView(
                    imagePath: item.imageURL ?? "",
                    size: CGSize(width: 160, height: 180),
                    cornerRadius: 14,
                    placeholder: item.category.iconName
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.theme.primary.opacity(selected ? 1.0 : 0.0), lineWidth: 2)
                )
                .overlay(alignment: .topTrailing) {
                    if selected {
                        ZStack {
                            Circle().fill(Color.theme.primary)
                            Image(systemName: "checkmark").foregroundColor(.white).font(.system(size: 12, weight: .bold))
                        }
                        .frame(width: 22, height: 22)
                        .padding(8)
                    }
                }
                Text(item.name)
                    .font(.theme.caption1)
                    .foregroundColor(.theme.textPrimary)
                    .lineLimit(1)
            }
            .padding(6)
            .background(Color.theme.surface)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}


// Shared UI helpers moved to BuildLookUI.swift
