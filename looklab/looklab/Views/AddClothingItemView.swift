import SwiftUI

struct AddClothingItemView: View {
    @Environment(\.dismiss) private var dismiss
    let category: ClothingCategory
    
    @State private var showingGallery = false
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.theme.surface)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: category.iconName)
                                .font(.system(size: 32))
                                .foregroundColor(.theme.primary)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Add \(category.displayName)")
                                .font(.theme.title1)
                                .foregroundColor(.theme.textPrimary)
                            
                            Text("Choose how to add your item")
                                .font(.theme.body)
                                .foregroundColor(.theme.textSecondary)
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        // Browse Gallery Button
                        AddMethodButton(
                            icon: "photo.on.rectangle",
                            title: "Browse Gallery",
                            subtitle: "Choose from our collection",
                            isPrimary: true
                        ) {
                            showingGallery = true
                        }
                        
                        // Upload Photo Button (disabled for now)
                        AddMethodButton(
                            icon: "camera.fill",
                            title: "Take Photo",
                            subtitle: "Upload from your camera",
                            isPrimary: false,
                            isDisabled: true
                        ) {
                            // Will be implemented later
                            showingImagePicker = true
                        }
                    }
                    
                    Spacer()
                    Spacer()
                }
                .padding(.horizontal, 32)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.theme.textSecondary)
                }
            }
            .sheet(isPresented: $showingGallery) {
                GalleryView(category: category)
            }
        }
    }
}

struct AddMethodButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let isPrimary: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String, isPrimary: Bool, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isPrimary = isPrimary
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(iconForegroundColor)
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.theme.headline)
                        .foregroundColor(titleColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(subtitle)
                        .font(.theme.subheadline)
                        .foregroundColor(subtitleColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(arrowColor)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
    
    private var backgroundColor: Color {
        if isDisabled {
            return Color.theme.surface.opacity(0.3)
        }
        return isPrimary ? Color.theme.primary.opacity(0.1) : Color.theme.surface
    }
    
    private var borderColor: Color {
        if isDisabled {
            return Color.theme.border.opacity(0.3)
        }
        return isPrimary ? Color.theme.primary.opacity(0.3) : Color.theme.border
    }
    
    private var iconBackgroundColor: Color {
        if isDisabled {
            return Color.theme.surface.opacity(0.3)
        }
        return isPrimary ? Color.theme.primary : Color.theme.surfaceSecondary
    }
    
    private var iconForegroundColor: Color {
        if isDisabled {
            return Color.theme.textTertiary
        }
        return isPrimary ? Color.white : Color.theme.primary
    }
    
    private var titleColor: Color {
        isDisabled ? Color.theme.textTertiary : Color.theme.textPrimary
    }
    
    private var subtitleColor: Color {
        isDisabled ? Color.theme.textTertiary.opacity(0.7) : Color.theme.textSecondary
    }
    
    private var arrowColor: Color {
        isDisabled ? Color.theme.textTertiary : Color.theme.textSecondary
    }
}

#Preview {
    AddClothingItemView(category: .tops)
        .preferredColorScheme(.dark)
}