import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import FirebaseAuth
import UIKit

private let lookDragType = UTType.plainText

struct MyLooksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var looks: [Look]
    @Query private var categoriesQuery: [LookCategory]
    @Query private var users: [User]

    @State private var selectedCategoryID: String? = nil
    @State private var showingNewCategory = false
    @State private var newCategoryName: String = ""
    @State private var previewLook: Look? = nil
    @State private var pendingDelete: Look? = nil
    @State private var pendingDeleteCategory: LookCategory? = nil

    private var userID: String {
        Auth.auth().currentUser?.uid ?? users.first?.id ?? "local"
    }

    private var categories: [LookCategory] {
        let filtered = categoriesQuery.filter { $0.userID == userID }
        if filtered.isEmpty { return [] }
        return filtered.sorted { $0.createdAt < $1.createdAt }
    }

    private var selectedCategory: LookCategory? {
        guard let id = selectedCategoryID else { return nil }
        return categories.first(where: { $0.id == id })
    }

    private var looksInSelected: [Look] {
        guard let cat = selectedCategory else { return [] }
        return looks.filter { $0.category == cat.id }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private let gridCols = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                header
                categoryStrip
                if looksInSelected.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: gridCols, spacing: 12) {
                            ForEach(looksInSelected, id: \.id) { look in
                                Button(action: { previewLook = look }) {
                                    LookThumbCard(look: look)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        pendingDelete = look
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .onDrag {
                                    NSItemProvider(object: look.id as NSString)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
            }
            .background(Color.theme.background.ignoresSafeArea())
            .onAppear(perform: ensureDefaults)
            .navigationBarHidden(true)
            .sheet(isPresented: Binding(
                get: { previewLook != nil },
                set: { if !$0 { previewLook = nil } }
            )) {
                if let look = previewLook {
                    LookPreviewSheet(look: look)
                        .preferredColorScheme(.dark)
                }
            }
            .alert("Delete Look?", isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let l = pendingDelete { LookLibraryService.shared.delete(look: l, in: modelContext) }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: {
                Text("This will remove the look permanently.")
            }
            .alert("Delete Category?", isPresented: Binding(
                get: { pendingDeleteCategory != nil },
                set: { if !$0 { pendingDeleteCategory = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let cat = pendingDeleteCategory {
                        let def = LookLibraryService.shared.deleteCategory(cat, in: modelContext)
                        if selectedCategoryID == cat.id { selectedCategoryID = def.id }
                    }
                    pendingDeleteCategory = nil
                }
                Button("Cancel", role: .cancel) { pendingDeleteCategory = nil }
            } message: {
                Text("Looks inside will be moved to Default.")
            }
        }
    }

    private var header: some View {
        HStack {
            Text("My Looks")
                .font(.theme.largeTitle)
                .foregroundColor(.theme.textPrimary)
            Spacer()
            Button(action: { showingNewCategory = true }) {
                Label("New Category", systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .foregroundColor(.theme.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.theme.border, lineWidth: 1))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .sheet(isPresented: $showingNewCategory) {
            NewCategorySheet(isPresented: $showingNewCategory, onCreate: { name in
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                let created = LookLibraryService.shared.createCategory(userID: userID, name: trimmed, in: modelContext)
                selectedCategoryID = created.id
            })
            .preferredColorScheme(.dark)
        }
    }

    private var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.id) { cat in
                    MyLooksCategoryChip(
                        name: cat.name,
                        selected: selectedCategoryID == cat.id,
                        onTap: { selectedCategoryID = cat.id }
                    )
                    .contextMenu {
                        if !isDefault(cat) {
                            Button(role: .destructive) {
                                pendingDeleteCategory = cat
                            } label: {
                                Label("Delete Category", systemImage: "trash")
                            }
                        } else {
                            Label("Default category", systemImage: "lock")
                        }
                    }
                    .dropDestination(for: String.self) { items, _ in
                        // Move dragged look to this category
                        guard let lookID = items.first else { return false }
                        LookLibraryService.shared.moveLook(lookID, toCategoryID: cat.id, in: modelContext)
                        return true
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.theme.accent)
            Text("No looks here yet")
                .font(.theme.subheadline)
                .foregroundColor(.theme.textSecondary)
            Text("Save a look, or drag one here from another category.")
                .font(.theme.caption1)
                .foregroundColor(.theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.background)
    }

    private func ensureDefaults() {
        let defaultCategory = LookLibraryService.shared.ensureDefaultCategory(userID: userID, in: modelContext)
        if selectedCategoryID == nil { selectedCategoryID = defaultCategory.id }
    }

    private func isDefault(_ cat: LookCategory) -> Bool {
        let def = LookLibraryService.shared.ensureDefaultCategory(userID: userID, in: modelContext)
        return def.id == cat.id || cat.name.lowercased() == "default"
    }
}

private struct MyLooksCategoryChip: View {
    let name: String
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(name)
                .font(.theme.caption1)
                .foregroundColor(selected ? .theme.primary : .theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selected ? Color.theme.primary.opacity(0.10) : Color.theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Color.theme.primary : Color.theme.border, lineWidth: 1))
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

private struct LookThumbCard: View {
    let look: Look

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.theme.border, lineWidth: 1))
                if let data = look.selectedImageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(6)
                } else if let stored = look.selectedImageURL ?? look.generatedImageURLs.first,
                          let ui = ImageStorage.loadImage(from: stored) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(6)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.theme.accent)
                    }
                }
            }
            .frame(height: 200)
            .onAppear {
                let hasData = look.selectedImageData != nil
                let urlStr = look.selectedImageURL ?? "-"
                let filename = look.generatedImageURLs.first ?? "-"
                let resolved = (look.selectedImageURL != nil) ? (ImageStorage.resolveURL(from: look.selectedImageURL!)?.path ?? "-") : (ImageStorage.resolveURL(from: filename)?.path ?? "-")
                print("[MyLooks] look=\(look.id) hasData=\(hasData) url=\(urlStr) filename=\(filename) resolved=\(resolved)")
            }
        }
        .background(Color.clear)
    }

    // Loading uses ImageStorage utility now.
}

// MARK: - Look Preview Sheet
private struct LookPreviewSheet: View {
    let look: Look
    @Environment(\.dismiss) private var dismiss

    private var image: UIImage? {
        if let data = look.selectedImageData, let ui = UIImage(data: data) { return ui }
        if let stored = look.selectedImageURL ?? look.generatedImageURLs.first,
           let ui = ImageStorage.loadImage(from: stored) { return ui }
        return nil
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.theme.background)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "photo")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.theme.accent)
                        Text("No preview available")
                            .font(.theme.subheadline)
                            .foregroundColor(.theme.textSecondary)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.theme.textPrimary)
                }
            }
        }
    }
}

private struct NewCategorySheet: View {
    @Binding var isPresented: Bool
    var onCreate: (String) -> Void
    @State private var name: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("Category name", text: $name)
                    .textInputAutocapitalization(.words)
                    .padding(12)
                    .background(Color.theme.surfaceSecondary)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.theme.border, lineWidth: 1))
                    .padding(.horizontal, 16)
                Spacer()
            }
            .background(Color.theme.background.ignoresSafeArea())
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(.theme.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(name)
                        isPresented = false
                    }
                    .foregroundColor(.theme.primary)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
