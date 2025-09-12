import SwiftUI
import SwiftData
import FirebaseAuth

struct SaveLookCategorySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categoriesQuery: [LookCategory]
    @Query private var users: [User]

    let image: UIImage?
    let selectedItems: [ClothingItem]
    let background: BackgroundType
    var onSaved: () -> Void
    var onCancel: () -> Void

    @State private var selectedCategoryID: String? = nil
    @State private var showingNewCategory = false
    @State private var newCategoryName: String = ""

    private var userID: String {
        Auth.auth().currentUser?.uid ?? users.first?.id ?? "local"
    }

    private var categories: [LookCategory] {
        let filtered = categoriesQuery.filter { $0.userID == userID }
        return filtered.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                List {
                    Section(header: Text("Choose Category").foregroundColor(.theme.textSecondary)) {
                        ForEach(categories, id: \.id) { cat in
                            HStack {
                                Text(cat.name).foregroundColor(.theme.textPrimary)
                                Spacer()
                                if selectedCategoryID == cat.id { Image(systemName: "checkmark").foregroundColor(.theme.primary) }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { selectedCategoryID = cat.id }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.theme.background)

                Button(action: { showingNewCategory = true }) {
                    Label("New Category", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.horizontal, 16)

                Button(action: save) {
                    Label("Save Look", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .background(Color.theme.background.ignoresSafeArea())
            .navigationTitle("Save Look")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(.theme.textPrimary)
                }
            }
        }
        .onAppear(perform: ensureDefaults)
        .sheet(isPresented: $showingNewCategory) {
            NewCategoryInlineSheet(isPresented: $showingNewCategory) { name in
                let created = LookLibraryService.shared.createCategory(userID: userID, name: name, in: modelContext)
                selectedCategoryID = created.id
            }
            .preferredColorScheme(.dark)
        }
    }

    private func ensureDefaults() {
        let def = LookLibraryService.shared.ensureDefaultCategory(userID: userID, in: modelContext)
        if selectedCategoryID == nil { selectedCategoryID = def.id }
    }

    private func save() {
        guard let img = image else { return }
        guard let path = saveImageToDocuments(image: img) else { return }

        let look = Look(userID: userID,
                        name: "My Look",
                        clothingItemIDs: selectedItems.map { $0.id },
                        backgroundType: background)
        look.generatedImageURLs = [path]
        look.selectedImageURL = path
        modelContext.insert(look)
        if let catID = selectedCategoryID,
           let cat = categories.first(where: { $0.id == catID }) {
            LookLibraryService.shared.assign(look, to: cat, in: modelContext)
        } else {
            let def = LookLibraryService.shared.ensureDefaultCategory(userID: userID, in: modelContext)
            LookLibraryService.shared.assign(look, to: def, in: modelContext)
        }
        try? modelContext.save()
        onSaved()
    }

    private func saveImageToDocuments(image: UIImage) -> String? {
        guard let data = image.pngData() ?? image.jpegData(compressionQuality: 0.92) else { return nil }
        let filename = "generated_look_\(UUID().uuidString).png"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(filename)
        guard let url else { return nil }
        do {
            try data.write(to: url)
            return url.path
        } catch {
            return nil
        }
    }
}

private struct NewCategoryInlineSheet: View {
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
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onCreate(trimmed)
                        isPresented = false
                    }
                    .foregroundColor(.theme.primary)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
