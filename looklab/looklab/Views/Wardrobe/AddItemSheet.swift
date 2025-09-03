import SwiftUI

struct AddItemSheet: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    @State private var showingGallery = false
    @State private var showingUpload = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color.theme.accent)
                        .padding(.top, 40)
                    
                    Text("Add Clothing Item")
                        .font(.theme.title2)
                        .foregroundColor(Color.theme.textPrimary)
                    
                    Text("Choose how you'd like to add a new item to your wardrobe")
                        .font(.theme.callout)
                        .foregroundColor(Color.theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 60)
                
                // Options
                VStack(spacing: 20) {
                    // Upload Photo Option
                    AddItemOptionCard(
                        icon: "camera.fill",
                        title: "Take or Upload Photo",
                        subtitle: "Upload a photo of your own clothing item",
                        accentColor: Color.theme.accent
                    ) {
                        showingUpload = true
                    }
                    .disabled(true) // Disabled for now as requested
                    .opacity(0.6)
                    
                    // Gallery Option
                    AddItemOptionCard(
                        icon: "rectangle.grid.3x2.fill",
                        title: "Choose from Gallery",
                        subtitle: "Select from our curated collection",
                        accentColor: Color.theme.primary
                    ) {
                        showingGallery = true
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color.theme.background.ignoresSafeArea())
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
        .sheet(isPresented: $showingGallery) {
            GallerySelectionView(user: user)
        }
        .sheet(isPresented: $showingUpload) {
            // Upload view will be implemented later
            Text("Upload functionality coming soon")
                .font(.theme.headline)
                .foregroundColor(Color.theme.textPrimary)
        }
    }
}

struct AddItemOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.theme.headline)
                        .foregroundColor(Color.theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(subtitle)
                        .font(.theme.callout)
                        .foregroundColor(Color.theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.theme.textTertiary)
            }
            .padding(20)
            .background(Color.theme.surface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.theme.border.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AddItemSheet(user: User(id: "sample", fashionInterest: .male))
}